// src/Lobby.cairo
%lang starknet
%builtins pedersen range_check

use openzeppelin::access::ownable::Ownable;
from starknet::syscalls import get_caller_address, emit_event;

/// Storage: owner + tournament records
#[storage]
struct Storage {
    #[substorage] own         : Ownable::Storage,
    creator_of               : LegacyMap::<felt, felt>,  // tourId → creator
    auction_of               : LegacyMap::<felt, felt>,  // tourId → NFTAuction address
    ticket_nft_of            : LegacyMap::<felt, felt>,  // tourId → TicketNFT address
    escrow_of                : LegacyMap::<felt, felt>,  // tourId → CreatorEscrow address
    status_of                : LegacyMap::<felt, felt>   // tourId → 0=Created,1=Finalized,2=Cancelled
}

/// Events
#[event] struct TournamentCreated   { tour_id: felt, creator: felt, auction: felt, ticket_nft: felt, escrow: felt }
#[event] struct TournamentFinalized { tour_id: felt }
#[event] struct TournamentCancelled { tour_id: felt }

/// Only the contract owner (DAO/multisig) can remove or override registrations
@external
func constructor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }()
{
    Ownable::initializer();  // msg.sender becomes the admin
    return ();
}

/// Creators call this to register a new tournament in the registry
@external
func create_tournament{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        tour_id: felt,
        auction_addr: felt,
        ticket_nft_addr: felt,
        escrow_addr: felt
    )
{
    let caller = get_caller_address();
    // ensure we haven’t already registered this tour
    assert Storage::creator_of::read(tour_id) == 0_felt;

    Storage::creator_of::write(tour_id, caller);
    Storage::auction_of::write(tour_id, auction_addr);
    Storage::ticket_nft_of::write(tour_id, ticket_nft_addr);
    Storage::escrow_of::write(tour_id, escrow_addr);
    Storage::status_of::write(tour_id, 0_felt);

    emit_event TournamentCreated {
      tour_id, creator: caller,
      auction: auction_addr,
      ticket_nft: ticket_nft_addr,
      escrow: escrow_addr
    };
    return ();
}

/// Creator finalizes the tournament (enables creator-escrow withdrawal, etc.)
@external
func finalize_tournament{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(tour_id: felt)
{
    let caller = get_caller_address();
    // only the registered creator may finalize
    assert Storage::creator_of::read(tour_id) == caller;
    Storage::status_of::write(tour_id, 1_felt);
    emit_event TournamentFinalized { tour_id };
    return ();
}

/// Creator cancels the tournament (e.g. to enable refunds)
@external
func cancel_tournament{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(tour_id: felt)
{
    let caller = get_caller_address();
    assert Storage::creator_of::read(tour_id) == caller;
    Storage::status_of::write(tour_id, 2_felt);
    emit_event TournamentCancelled { tour_id };
    return ();
}
