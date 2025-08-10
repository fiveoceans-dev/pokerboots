
## Contract Summary

This package contains Cairo contracts that power the onchain poker
application. Below is a high-level overview of each module.

- **Accounts.cairo** – placeholder for future account utilities.
- **Bank.cairo** – records player deposits, issues refunds and executes
  payouts in an ERC20 token.
- **CreatorEscrow.cairo** – stores the creator's share of ticket sales
  until it is withdrawn.
- **DeckShuffler.cairo** – generates a shuffled deck via a
  commit‑reveal scheme using VRF randomness.
- **HandEvaluator.cairo** – ranks seven-card poker hands with lookup
  tables.
- **Lobby.cairo** – tracks tournaments and their associated auction,
  ticket, and escrow contracts.
- **NFTAuction.cairo** – sells tickets, splits fees, mints NFTs and
  forwards the pool to the bank.
- **NFTTicket.cairo** – lightweight NFT representing tournament entry,
  supporting batch transfers and user assignments.
- **ProtocolTreasury.cairo** – holds protocol fees and allows the owner
  to withdraw balances.
- **TableState.cairo** – coordinates seating, game phases and interacts
  with the shuffler, evaluator and bank.

## How to use DeckShuffler

Files: DeckShuffler.cairo, deck_rng.py, test_deck_shuffler.py

### 1. on-chain part
rustup override set stable && rustup update
cargo install --locked scarb starknet-foundry
scarb build   # compiles DeckShuffler.cairo

### 2. local testnet & unit tests
pip install pytest starknet-devnet==0.13.5 starknet-foundry
pytest test_deck_shuffler.py          # contract integration
python deck_rng.py -v                 # RNG χ² + reproducibility

### 3. deploy
starkli declare --contract target/release/DeckShuffler.sierra.json
starkli deploy --class_hash <hash> --network sepolia


