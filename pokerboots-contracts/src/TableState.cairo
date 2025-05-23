// src/TableState.cairo
%lang starknet
%builtins pedersen range_check

from starknet        import syscalls::get_caller_address
use starknet::class_hash::class_hash
use starknet::contract_address_const::CONTRACT_ADDRESS

// ───────────────────────────────────────────────────────────────
//  Interfaces to helper contracts
// ───────────────────────────────────────────────────────────────
@contract_interface
namespace IShuffler {
    func request_random_deck(server_seed_hash: felt) -> (req_id: felt);
    func get_deck(req_id: felt) -> (deck: Array<felt>);
}

@contract_interface
namespace IEvaluator {
    func rank7(cards: Array<felt>) -> (rank: felt);
}

@contract_interface
namespace IBank {
    func payout(table_id: felt, to: Array<felt>, amounts: Array<felt>);
}

// ───────────────────────────────────────────────────────────────
//  Constants
// ───────────────────────────────────────────────────────────────
const MAX_SEATS          = 9;
const SMALL_BLIND_WEI    = 1e14_felt252;
const BIG_BLIND_WEI      = 2e14_felt252;
const BANK_ADDR          = 0x0123456789abcdef;     // set at deploy
const SHUFFLER_ADDR      = 0x02...;
const EVAL_ADDR          = 0x03...;

// Phases
enum Phase {
    Waiting,  // waiting for seats
    Preflop,
    Flop,
    Turn,
    River,
    Showdown,
    Settled
}

// ───────────────────────────────────────────────────────────────
//  Storage layout
// ───────────────────────────────────────────────────────────────
#[storage]
struct Storage {
    creator       : felt,                     // tournament creator
    phase         : Phase,                    // table phase
    deck_req_id   : felt,                     // pointer to deck in Shuffler
    seat_player   : LegacyMap::<felt, felt>,  // seatIdx => player addr
    seat_stack    : LegacyMap::<felt, felt>,  // seatIdx => wei balance
    seat_cards    : LegacyMap::<felt, felt>,  // seatIdx => length-15 Array index (7 cards)
    community     : felt*;                    // [0..10)  five community cards
    pot           : felt,                     // main pot wei
    highest_rank  : felt,                     // best hand rank this hand
    winner        : felt                      // seatIdx of winner
}

// ───────────────────────────────────────────────────────────────
//  Events
// ───────────────────────────────────────────────────────────────
#[event]
struct PhaseAdvanced { phase: Phase }
#[event]
struct SeatTaken     { seat: felt, player: felt }
#[event]
struct Winner        { seat: felt, rank: felt, amount: felt }

// ───────────────────────────────────────────────────────────────
//  Helpers
// ───────────────────────────────────────────────────────────────
fn only_creator() {
    let caller = get_caller_address();
    assert(caller == Storage::creator::read(), 'only creator');
}

// ───────────────────────────────────────────────────────────────
//  External entry points
// ───────────────────────────────────────────────────────────────

/// Creator seeds the table & requests deck
#[external]
func init_table{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(creator: felt, server_seed_hash: felt)
{
    assert Storage::phase::read() == Phase::Waiting;
    Storage::creator::write(creator);
    let (req_id) = IShuffler::request_random_deck(SHUFFLER_ADDR, server_seed_hash);
    Storage::deck_req_id::write(req_id);
}

/// Players buy-in (must own ticket NFT in Lobby, verify off-chain)
#[external]
func take_seat{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(seat: felt)
{
    assert seat < MAX_SEATS;
    assert Storage::phase::read() == Phase::Waiting;
    let caller = get_caller_address();
    assert Storage::seat_player::read(seat) == 0;
    Storage::seat_player::write(seat, caller);
    Storage::seat_stack::write(seat, 0);  // stack top-ups through Bank
    emit SeatTaken{ seat, player: caller };
}

/// Creator starts the hand after seats & decks ready
#[external]
func start_hand{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}()
{
    only_creator();
    assert Storage::phase::read() == Phase::Waiting;
    let req_id = Storage::deck_req_id::read();
    let (deck) = IShuffler::get_deck(SHUFFLER_ADDR, req_id);
    // Deal hole cards: for seat i → cards[2*i .. 2*i+1]
    let mut idx = 0;
    let mut card_ptr = deck.at(0);
    for seat in 0..MAX_SEATS {
        if Storage::seat_player::read(seat) != 0 {
            // store 7-card array index (2 hole + 5 community placeholders)
            Storage::seat_cards::write(seat, card_ptr);
            card_ptr += 14;      // skip 7 cards *2 felts
            idx += 4;            // consumed from deck
        }
    };
    // write community next 5*2 felts at deck[idx]
    Storage::community::write(deck.data_ptr() + idx * 1);  // pointer math
    Storage::phase::write(Phase::Preflop);
    emit PhaseAdvanced{ phase: Phase::Preflop };
}

/// Advance phase (anyone can call once betting done)
#[external]
func next_phase{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}()
{
    match Storage::phase::read() {
        Phase::Preflop => Storage::phase::write(Phase::Flop),
        Phase::Flop    => Storage::phase::write(Phase::Turn),
        Phase::Turn    => Storage::phase::write(Phase::River),
        Phase::River   => Storage::phase::write(Phase::Showdown),
        _              => {panic!("bad phase")}
    };
    emit PhaseAdvanced{ phase: Storage::phase::read() };
}

/// Showdown & payout (anyone can call)
#[external]
func settle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}()
{
    assert Storage::phase::read() == Phase::Showdown;
    let mut best_rank = 10_000; let mut winner_seat = 0;
    let community_ptr = Storage::community::read();
    for seat in 0..MAX_SEATS {
        let p = Storage::seat_player::read(seat);
        if p == 0 { continue; }
        let card_idx = Storage::seat_cards::read(seat);
        // build 7-card array (2 hole + 5 community)
        let mut buf = Array::<felt252>::new();
        let mut i = 0;
        while i < 14 { buf.append(card_idx[i]); i += 1; }
        i = 0; while i < 10 { buf.append(community_ptr[i]); i += 1; }
        let (rank) = IEvaluator::rank7(EVAL_ADDR, buf);
        if rank < best_rank {
            best_rank = rank; winner_seat = seat;
        }
    };
    Storage::highest_rank::write(best_rank);
    Storage::winner::write(winner_seat);

    // compute payouts (simple winner-takes-all here)
    let mut to = Array::<felt252>::new(); to.append(Storage::seat_player::read(winner_seat));
    let mut amt = Array::<felt252>::new(); amt.append(Storage::pot::read());
    IBank::payout(BANK_ADDR, CONTRACT_ADDRESS, to, amt);

    Storage::phase::write(Phase::Settled);
    emit Winner{ seat: winner_seat, rank: best_rank, amount: Storage::pot::read() };
}
