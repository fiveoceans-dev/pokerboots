
# How to use DeckShuffler
Files: DeckShuffler.cairo, deck_rng.py, test_deck_shuffler.py

# 1. on-chain part
rustup override set stable && rustup update
cargo install --locked scarb starknet-foundry
scarb build   # compiles DeckShuffler.cairo

# 2. local testnet & unit tests
pip install pytest starknet-devnet==0.13.5 starknet-foundry
pytest test_deck_shuffler.py          # contract integration
python deck_rng.py -v                 # RNG χ² + reproducibility

# 3. deploy
starkli declare --contract target/release/DeckShuffler.sierra.json
starkli deploy --class_hash <hash> --network sepolia


