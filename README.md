# Onchain Poker with Starknet

Pokerboots is an experiment in running poker tournaments entirely on
Starknet. The `pokerboots-contracts` package contains the Cairo smart
contracts that manage tournaments, tickets and payouts.

## Contract Summary

- **Bank.cairo** – tracks player deposits, issues refunds and pays out
  winners using an ERC20 token.
- **CreatorEscrow.cairo** – holds the creator’s share of ticket sales
  until withdrawal.
- **DeckShuffler.cairo** – produces a shuffled deck through a
  commit‑reveal process and VRF randomness.
- **HandEvaluator.cairo** – evaluates seven-card hands to determine
  poker rankings.
- **Lobby.cairo** – registers tournaments and links their auction,
  ticket and escrow contracts.
- **NFTAuction.cairo** – sells tournament tickets, splits fees and
  mints the corresponding NFT.
- **NFTTicket.cairo** – lightweight NFT representing tournament entry
  with delegation features.
- **ProtocolTreasury.cairo** – vault for protocol fees that the owner
  can withdraw.
- **TableState.cairo** – coordinates seating, game phases and payouts
  at a poker table.

See [pokerboots-contracts/README.md](pokerboots-contracts/README.md) for
build instructions and additional details.

