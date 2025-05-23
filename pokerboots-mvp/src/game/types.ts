// src/game/types.ts
export type Suit = '♠' | '♥' | '♦' | '♣';
export type Rank = '2'|'3'|'4'|'5'|'6'|'7'|'8'|'9'|'T'|'J'|'Q'|'K'|'A';

/** ← this _must_ be exported */
export interface Card {
  suit: Suit;
  rank: Rank;
}

export interface Player {
  id: string;
  name: string;
  chips: number;
  hand: Card[];
  folded: boolean;
  currentBet: number;
}

export interface GameState {
  deck: Card[];
  players: Player[];
  community: Card[];
  pot: number;
  dealerIndex: number;
  currentIndex: number;
  street: 'preflop' | 'flop' | 'turn' | 'river' | 'showdown';
}
