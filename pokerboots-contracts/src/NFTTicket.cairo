// src/NFTTicket.cairo
%lang starknet
%builtins pedersen range_check

// ────────── OpenZeppelin imports ──────────
use openzeppelin::access::ownable::Ownable;
use openzeppelin::access::roles::{RoleManager, has_role, grant_role};
use openzeppelin::token::erc721::{ERC721, IERC721};

// ────────── Roles ──────────
const MINTER_ROLE : felt252 = 'MINTER_ROLE';

// ────────── ERC-4907 storage (*very* light) ──────────
#[storage]
struct Storage {
    #[substorage] erc721 : ERC721::Storage,         // OZ ERC-721
    #[substorage] own    : Ownable::Storage,

    // ERC-4907 user mapping  tokenId → (user, expires)
    user_of   : LegacyMap::<u256, felt252>,
    expires   : LegacyMap::<u256, felt252>,

    // optional: back-pointer to tournament
    tour_of   : LegacyMap::<u256, felt252>
}

// ────────── Constructor ──────────
@external
func constructor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(name: felt252, symbol: felt252, minter: felt252)
{
    Ownable::initializer();
    ERC721::initializer(name, symbol);
    // grant MINTER_ROLE to the auction / factory
    RoleManager::write(minter, MINTER_ROLE, 1);
    return ();
}

// ────────── Mint – only MINTER_ROLE ──────────
@external
func safe_mint{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(to: felt252, token_id: u256, tournament_id: felt252)
{
    assert has_role(MINTER_ROLE, get_caller_address()) == 1, 'not minter';
    ERC721::safe_mint(to, token_id);
    Storage::tour_of::write(token_id, tournament_id);
    return ();
}

// ────────── Batch transfer helper (gas save) ──────────
@external
func batch_transfer{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(to: felt252, token_ids: Array::<u256>)
{
    let caller = get_caller_address();
    for tkn in token_ids.iter() {
        ERC721::transfer_from(caller, to, tkn);
    };
    return ();
}

// ────────── ERC-4907 – setUser ──────────
@external
func set_user{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(token_id: u256, user: felt252, expires: felt252)
{
    let owner = ERC721::owner_of(token_id);
    assert owner == get_caller_address(), 'not owner';
    Storage::user_of::write(token_id, user);
    Storage::expires::write(token_id, expires);
}

@view
func user_of{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(token_id: u256) -> felt252
{
    let exp = Storage::expires::read(token_id);
    if exp < block_timestamp() { return (0,); }
    return (Storage::user_of::read(token_id),);
}

// ────────── Metadata (optional tokenURI) ──────────
@view
func token_uri{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(token_id: u256) -> felt252
{
    // off-chain base URI pattern -> "ipfs://…/{token_id}.json"
    return (Storage::tour_of::read(token_id),); // placeholder
}
