#[starknet::contract]
mod HandEvaluator {
    use core::array::ArrayTrait;

    const LOOKUP: @Array<felt252> = @("0x026A ..." /* truncated */);

    #[view]
    fn rank7(self: @ContractState, cards: Array::<felt252>) -> felt252 {
        assert(cards.len() == 14);
        let CARD_PRIME = @array<u32>(2,3,5,7,11,13,17,19,23,29,31,37,41);
        let mut prod: felt252 = 1;
        let mut i = 0;
        while i < 14 {
            let rank = cards.at(i);
            prod *= CARD_PRIME[rank];
            i = i + 2;
        };
        let idx = _binary_search(prod);
        LOOKUP.at(idx)
    }

    fn _binary_search(key: felt252) -> felt252 {
        let mut low = 0;
        let mut high = LOOKUP.len() - 1;
        loop {
            if low > high { panic!("hand key not found"); }
            let mid = (low + high) / 2;
            let val = LOOKUP.at(mid);
            if val == key { return mid; }
            if val < key { low = mid + 1; }
            else { high = mid - 1; }
        };
    }
}
