
// src/DeckShuffler.cairo   (Cairo 2.5.0)
// targets Starknet ≥ 0.13.5
// Compile with:  scarb build
%lang starknet
%builtins pedersen range_check
use starknet::contract_address_const::CONTRACT_ADDRESS;
use starknet::syscalls::{emit_event, get_block_hash};

// -------------------------  storage  ----------------
#[storage]
struct Storage {
    /// mapping(request_id) → hash(server_seed)  (commit)
    commit: LegacyMap::<felt252, felt252>,
    /// mapping(request_id) → 104-felt packed deck  (reveal)
    deck: LegacyMap::<felt252, Array::<felt252>>,
}

// -------------------------  events  -----------------
#[event]
struct DeckRequested { request_id: felt252, server_seed_hash: felt252 }

#[event]
struct DeckFulfilled { request_id: felt252 }

// --------------  helper: Fisher-Yates on felt[] -----
fn shuffle_fisher_yates(rands: Array::<felt252>) -> Array::<felt252> {
    let mut deck = Array::<felt252>::new();
    // initialise ordered deck 0-51 packed as two felts each (rank, suit)
    for i in 0..52 {
        deck.append(i % 13);      // rank
        deck.append(i / 13);      // suit
    };
    // single-pass shuffle
    let mut j: felt252 = 51;
    for i in 0..51 {
        // rejection-free modulo using rands[i]
        let k = rands[i] % (52 - i);
        // swap pairs (2 felts per card)
        let a0 = deck[2 * i];          let a1 = deck[2 * i + 1];
        let b0 = deck[2 * (i + k)];    let b1 = deck[2 * (i + k) + 1];
        deck[2 * i]       = b0;        deck[2 * i + 1]     = b1;
        deck[2 * (i + k)] = a0;        deck[2 * (i + k)+1] = a1;
    };
    return deck;
}

// ----------------  external entry points ------------
#[external]
fn request_random_deck{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(server_seed_hash: felt252) -> felt252 {
    let request_id = get_block_hash(0)  // cheap pseudo-unique nonce
                     + CONTRACT_ADDRESS;
    Storage::commit::write(request_id, server_seed_hash);
    emit_event(DeckRequested{request_id, server_seed_hash});
    return request_id;
}

/// Called *only* by the VRF oracle after it proves `vrf_random`
/// randomness. `server_seed_preimage` must hash to the commit.
#[external]
fn fulfill_random_deck{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        request_id: felt252,
        server_seed_preimage: felt252,
        vrf_random: Array::<felt252>  // ≥ 52 numbers, already uniform
    ) {
    let stored = Storage::commit::read(request_id);
    assert stored = hash2(server_seed_preimage, 0);  // simple MD5 sim

    let deck = shuffle_fisher_yates(vrf_random);
    Storage::deck::write(request_id, deck);
    emit_event(DeckFulfilled{request_id});
}

/// Pure view that returns the packed deck so clients can verify.
#[view]
fn get_deck{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(request_id: felt252) -> Array::<felt252> {
    return Storage::deck::read(request_id);
}
