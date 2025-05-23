// src/CreatorEscrow.cairo
%lang starknet
%builtins pedersen range_check

use openzeppelin::access::ownable::Ownable;
use openzeppelin::token::erc20::IERC20;
from starknet::syscalls import emit_event;
from starknet::contract_address_const import CONTRACT_ADDRESS;
use starknet::uint256::Uint256;

/// Storage: owner (tournament creator) + token address
#[storage]
struct Storage {
    #[substorage] own    : Ownable::Storage,
    token               : felt           // ERC-20 contract holding the fee
}

/// Emitted whenever creator withdraws their accumulated funds
#[event]
struct CreatorWithdrawn {
    to: felt,
    amount: Uint256
}

/// Initialize with the fee‐token and the creator (owner)
@external
func constructor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(token: felt, creator: felt)
{
    // sets msg.sender as provisional owner…
    Ownable::initializer();
    // …then transfer ownership to the tournament creator
    Ownable::transfer_ownership(creator);
    Storage::token::write(token);
    return ();
}

/// Withdraw **all** tokens in this escrow to `to` (only callable by creator)
@external
func withdraw_all{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(to: felt)
{
    // only the creator (owner) may call
    let caller = get_caller_address();
    Ownable::only_owner(caller);

    let token = Storage::token::read();
    // read full balance of this contract
    let (balance) = IERC20::balance_of{
        syscall_ptr=syscall_ptr,
        pedersen_ptr=pedersen_ptr,
        range_check_ptr=range_check_ptr,
        contract_address=token
    }(CONTRACT_ADDRESS);

    // send it out
    let (_ok) = IERC20::transfer{
        syscall_ptr=syscall_ptr,
        pedersen_ptr=pedersen_ptr,
        range_check_ptr=range_check_ptr,
        contract_address=token
    }(to, balance);

    emit_event CreatorWithdrawn { to, amount: balance };
    return ();
}

/// View the current escrowed balance
@view
func get_balance{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (bal: Uint256)
{
    let token = Storage::token::read();
    let (balance) = IERC20::balance_of{
        syscall_ptr=syscall_ptr,
        pedersen_ptr=pedersen_ptr,
        range_check_ptr=range_check_ptr,
        contract_address=token
    }(CONTRACT_ADDRESS);
    return (balance,);
}
