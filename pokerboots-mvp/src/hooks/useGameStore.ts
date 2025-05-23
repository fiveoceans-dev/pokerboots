// src/hooks/useGameStore.ts
import { create } from 'zustand';
import type { GameState } from '../game/types';
import { freshDeck, draw } from '../game/utils';

interface Actions {
  startHand(): void;
  dealFlop(): void;
  dealTurn(): void;
  dealRiver(): void;
}

/* -------- Zustand store -------- */
export const useGameStore = create<GameState & Actions>((set, get) => ({
  deck: freshDeck(),
  players: [],
  community: [],
  pot: 0,
  dealerIndex: 0,
  currentIndex: 0,
  street: 'preflop',

  /* ----- new hand ----- */
  startHand() {
    const deck = freshDeck();
    const players = get().players.map((p) => ({
      ...p,
      hand: [draw(deck), draw(deck)],
      folded: false,
      currentBet: 0,
    }));
    set({ deck, players, community: [], street: 'preflop' });
  },

  /* ----- flop ----- */
  dealFlop() {
    const deck = get().deck;
    draw(deck); // burn
    const flop = [draw(deck), draw(deck), draw(deck)];
    set({ community: flop, street: 'flop', deck });
  },

  /* ----- turn ----- */
  dealTurn() {
    const deck = get().deck;
    draw(deck); // burn
    const turnCard = draw(deck);
    set((state) => ({
      community: [...state.community, turnCard],
      street: 'turn',
      deck,
    }));
  },

  /* ----- river ----- */
  dealRiver() {
    const deck = get().deck;
    draw(deck); // burn
    const riverCard = draw(deck);
    set((state) => ({
      community: [...state.community, riverCard],
      street: 'river',
      deck,
    }));
  },
}));
