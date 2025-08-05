// src/components/PlayerSeat.tsx
import clsx from 'clsx';
import Card from './Card';
import type { Player } from '../game/types';

interface PlayerSeatProps {
  player: Player;       // player object from your Zustand store
  isDealer?: boolean;   // show “D” button
  isActive?: boolean;   // highlight when it's this player's turn
  bet?: number;         // chips currently in the pot for this player
  revealCards?: boolean;// flip cards face-up (e.g., showdown or for your own seat)
}

export default function PlayerSeat({
  player,
  isDealer = false,
  isActive = false,
  bet = 0,
  revealCards = false,
}: PlayerSeatProps) {
  return (
    <div
      className={clsx(
        'relative flex flex-col items-center gap-1 card p-2 rounded-xl',
        player.folded && 'opacity-60',
        isActive && 'ring-4 ring-[var(--brand-accent)]'
      )}
    >
      {/* dealer button */}
      {isDealer && (
        <span className="absolute -top-3 -right-3 w-6 h-6 rounded-full bg-[var(--brand-accent)] text-black text-xs font-bold flex items-center justify-center">
          D
        </span>
      )}

      {/* pocket cards */}
      <div className="flex gap-2">
        <Card card={player.hand[0] ?? null} hidden={!revealCards} size="lg" />
        <Card card={player.hand[1] ?? null} hidden={!revealCards} size="lg" />
      </div>

      {/* name + chip count */}
      <div className="text-center text-white">
        <div className="font-semibold">{player.name}</div>
        <div className="text-sm">{player.chips} chips</div>
      </div>

      {/* current bet */}
      {bet > 0 && (
        <div className="mt-0.5 px-2 py-0.5 bg-green-700 rounded text-xs text-white">
          Bet {bet}
        </div>
      )}
    </div>
  );
}
