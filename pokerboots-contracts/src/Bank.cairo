// src/Bank.cairo
%lang starknet
%builtins pedersen range_check

from starknet::syscalls import get_caller_address, emit_event
from starknet::uint256 import Uint256, uint256_add, uint256_sub
from starknet::contract_address_const import CONTRACT_ADDRESS

// ────────── Interfaces ──────────
@contract_interface
namespace IERC20 {
    func transfer{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(
            recipient: felt,
            amount: Uint256
        ) -> (success: felt);
}

// ────────── Storage ──────────
#[storage]
struct Storage {
    token             : felt,      // ERC20 token address
    depositor_role    : LegacyMap::<felt, felt>,                 // who can record deposits
    payer_role        : LegacyMap::<felt, felt>,                 // who can call payout
    total_deposited   : LegacyMap::<felt, Uint256>,              // tourId → total Uint256
    player_deposit    : LegacyMap::<(felt, felt), Uint256>,      // (tourId,player) → Uint256
}

// ────────── Events ──────────
#[event] struct DepositRecorded { tour_id: felt, player: felt, amount: Uint256 }
#[event] struct Refunded        { tour_id: felt, player: felt, amount: Uint256 }
#[event] struct PayoutMade      { tour_id: felt, player: felt, amount: Uint256 }

// ────────── Constructor ──────────
@external
func constructor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        token: felt,
        initial_depositor: felt,
        initial_payer: felt
    )
{
    Storage::token::write(token);
    Storage::depositor_role::write(initial_depositor, 1);
    Storage::payer_role::write(initial_payer, 1);
    return ();
}

// ────────── Modifiers ──────────
func only_depositor() {
    let caller = get_caller_address();
    let ok     = Storage::depositor_role::read(caller);
    assert ok == 1_u8;
}
func only_payer() {
    let caller = get_caller_address();
    let ok     = Storage::payer_role::read(caller);
    assert ok == 1_u8;
}

// ────────── Record a deposit (called by NFTAuction after transferring tokens) ──────────
@external
func record_deposit{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        tour_id: felt,
        player: felt,
        amount: Uint256
    )
{
    only_depositor();
    // update total
    let prev_total = Storage::total_deposited::read(tour_id);
    let new_total  = uint256_add(prev_total, amount);
    Storage::total_deposited::write(tour_id, new_total);

    // update per-player
    let key = (tour_id, player);
    let prev_pd = Storage::player_deposit::read(key);
    let new_pd  = uint256_add(prev_pd, amount);
    Storage::player_deposit::write(key, new_pd);

    emit_event DepositRecorded { tour_id, player, amount };
    return ();
}

// ────────── Refund all players (e.g. on cancel) ──────────
@external
func refund_all{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        tour_id: felt,
        players: Array::<felt>
    )
{
    only_depositor();

    let token = Storage::token::read();
    // iterate players
    for player in players.iter() {
        let key       = (tour_id, player);
        let deposited = Storage::player_deposit::read(key);
        // zero it out before transfer
        Storage::player_deposit::write(key, Uint256(0,0));

        // subtract from total
        let prev_total = Storage::total_deposited::read(tour_id);
        let new_total  = uint256_sub(prev_total, deposited);
        Storage::total_deposited::write(tour_id, new_total);

        // transfer back
        let (_ok) = IERC20::transfer{
            syscall_ptr=syscall_ptr,
            pedersen_ptr=pedersen_ptr,
            range_check_ptr=range_check_ptr,
            contract_address=token
        }(player, deposited);

        emit_event Refunded { tour_id, player, amount: deposited };
    }
    return ();
}

// ────────── Payout winners (called by StateMachine) ──────────
@external
func payout{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        tour_id: felt,
        players: Array::<felt>,
        amounts: Array::<Uint256>
    )
{
    only_payer();

    let token = Storage::token::read();
    // iterate and pay
    let mut i = 0;
    while i < players.len() {
        let player = players.at(i);
        let amt    = amounts.at(i);
        // update total_deposited
        let prev_total = Storage::total_deposited::read(tour_id);
        let new_total  = uint256_sub(prev_total, amt);
        Storage::total_deposited::write(tour_id, new_total);

        // transfer out
        let (_ok) = IERC20::transfer{
            syscall_ptr=syscall_ptr,
            pedersen_ptr=pedersen_ptr,
            range_check_ptr=range_check_ptr,
            contract_address=token
        }(player, amt);

        emit_event PayoutMade { tour_id, player, amount: amt };
        i += 1;
    }
    return ();
}

// ────────── Views ──────────
@view
func get_total_deposited{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(tour_id: felt) -> Uint256
{
    return (Storage::total_deposited::read(tour_id),);
}

@view
func get_player_deposit{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(tour_id: felt, player: felt) -> Uint256
{
    return (Storage::player_deposit::read((tour_id, player)),);
}
