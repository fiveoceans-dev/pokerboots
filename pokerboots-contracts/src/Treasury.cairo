// src/Treasury.cairo
%lang starknet
%builtins pedersen range_check

// ────────── Imports ──────────
use openzeppelin::access::ownable::Ownable;
use openzeppelin::token::erc20::IERC20;
use starknet::syscalls::get_caller_address;
use starknet::contract_address_const::CONTRACT_ADDRESS;
use starknet::uint256::Uint256;

// ────────── Storage ──────────
#[storage]
struct Storage {
    #[substorage] own   : Ownable::Storage,
    token              : felt              // ERC20 token address collecting fees
}

// ────────── Events ──────────
#[event]
struct FeeWithdrawn {
    to: felt,
    amount: Uint256
}

// ────────── Constructor ──────────
@external
func constructor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(token: felt)
{
    // Initialize Ownable (sets msg.sender as owner)
    Ownable::initializer();
    // Store the fee token address
    Storage::token::write(token);
    return ();
}

// ────────── Withdraw All Fees ──────────
@external
func withdraw_all{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(to: felt)
{
    // only the contract owner (treasury multisig / DAO) may withdraw
    let caller = get_caller_address();
    Ownable::only_owner(caller);

    // Fetch token contract and this contract's balance
    let token = Storage::token::read();
    let (balance) = IERC20::balance_of{
        syscall_ptr=syscall_ptr,
        pedersen_ptr=pedersen_ptr,
        range_check_ptr=range_check_ptr,
        contract_address=token
    }(CONTRACT_ADDRESS);

    // Transfer full balance to the recipient
    let (_ok) = IERC20::transfer{
        syscall_ptr=syscall_ptr,
        pedersen_ptr=pedersen_ptr,
        range_check_ptr=range_check_ptr,
        contract_address=token
    }(to, balance);
    // Emit event for off-chain indexing
    emit_event FeeWithdrawn { to, amount: balance };
    return ();
}

// ────────── View: Current Balance ──────────
@view
func get_balance{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (balance: Uint256)
{
    let token = Storage::token::read();
    let (bal) = IERC20::balance_of{
        syscall_ptr=syscall_ptr,
        pedersen_ptr=pedersen_ptr,
        range_check_ptr=range_check_ptr,
        contract_address=token
    }(CONTRACT_ADDRESS);
    return (bal,);
}
