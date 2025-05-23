# tools/build_table.py  (run once)
from phevaluator import evaluate_7cards  # pip install poker-hand-evaluator
from itertools import combinations
PRIMES = [2,3,5,7,11,13,17,19,23,29,31,37,41]  # ranks 2..A
SUITS  = range(4)
CARD_PRIME = [p for p in PRIMES for _ in SUITS]  # 52 primes

table = {}
for seven in combinations(range(52), 7):
    product = 1
    for c in seven:
        product *= CARD_PRIME[c]
    table[product] = evaluate_7cards(*seven)  # 0..7461
