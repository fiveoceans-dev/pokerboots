// src/NFTAuction.cairo
%lang starknet
%builtins pedersen range_check

from starknet::syscalls import get_caller_address, emit_event
from starknet::contract_address_const import CONTRACT_ADDRESS
from starknet::uint256 import Uint256, uint256_div, uint256_mul, uint256_sub, uint256_add

// ────────── Interfaces ──────────
@contract_interface
namespace IERC20 {
    func transfer_from{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(
            sender: felt,
            recipient: felt,
            amount: Uint256
        ) -> (success: felt);
    func transfer{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(
            recipient: felt,
            amount: Uint256
        ) -> (success: felt);
}

@contract_interface
namespace INFTTicket {
    func safe_mint{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(
            to: felt,
            token_id: Uint256,
            tournament_id: felt
        );
}

// ────────── Storage ──────────
#[storage]
struct Storage {
    price           : Uint256,  // sale price per ticket
    token           : felt,     // ERC20 token used for payment
    ticket_nft      : felt,     // TicketNFT contract address
    fee_vault       : felt,     // protocol fee recipient
    creator_escrow  : felt,     // creator fee recipient
    bank            : felt,     // prize pool escrow
    tournament_id   : felt,     // associated tournament
    next_id         : Uint256   // auto-increment ticket ID
}

// ────────── Events ──────────
#[event]
struct TicketSold {
    ticket_id: Uint256,
    buyer: felt,
    price: Uint256
}

// ────────── Constructor ──────────
@external
func constructor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        price: Uint256,
        token: felt,
        ticket_nft: felt,
        fee_vault: felt,
        creator_escrow: felt,
        bank: felt,
        tournament_id: felt
    )
{
    Storage::price::write(price);
    Storage::token::write(token);
    Storage::ticket_nft::write(ticket_nft);
    Storage::fee_vault::write(fee_vault);
    Storage::creator_escrow::write(creator_escrow);
    Storage::bank::write(bank);
    Storage::tournament_id::write(tournament_id);
    Storage::next_id::write(Uint256(1, 0));
    return ();
}

// ────────── Purchase Entrypoint ──────────
@external
func buy_ticket{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (ticket_id: Uint256)
{
    let buyer = get_caller_address();
    let price = Storage::price::read();
    let erc20 = Storage::token::read();

    // Transfer price from buyer to this contract
    let (ok1) = IERC20::transfer_from{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr,
        contract_address=erc20
    }(buyer, CONTRACT_ADDRESS, price);
    assert ok1 == 1;

    // Calculate splits: 10% fee, 10% creator, 80% pool
    let (fee) = uint256_div(price, Uint256(10,0));         // 10%
    let (two_fee) = uint256_mul(fee, Uint256(2,0));       // 20%
    let (pool) = uint256_sub(price, two_fee);             // 80%

    let fee_vault      = Storage::fee_vault::read();
    let creator_escrow = Storage::creator_escrow::read();
    let bank           = Storage::bank::read();

    // Distribute funds
    let (_ok2) = IERC20::transfer{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr,
        contract_address=erc20
    }(fee_vault, fee);
    let (_ok3) = IERC20::transfer{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr,
        contract_address=erc20
    }(creator_escrow, fee);
    let (_ok4) = IERC20::transfer{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr,
        contract_address=erc20
    }(bank, pool);

    // Mint the ticket NFT
    let mut next = Storage::next_id::read();
    Storage::next_id::write(uint256_add(next, Uint256(1,0)));
    let ticket_nft = Storage::ticket_nft::read();
    let tour_id    = Storage::tournament_id::read();
    INFTTicket::safe_mint{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr,
        contract_address=ticket_nft
    }(buyer, next, tour_id);

    // Emit sale event
    emit_event TicketSold{ ticket_id=next, buyer=buyer, price=price };

    return (next,);
}
