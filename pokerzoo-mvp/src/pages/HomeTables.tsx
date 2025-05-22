// HomeTables.tsx

import Table from '../components/Table';
import ActionBar from '../components/ActionBar';
import { useGameStore } from '../hooks/useGameStore';

export default function HomeTables() {
  const {
    startHand,
    dealFlop,
    dealTurn,
    dealRiver,
    street,
  } = useGameStore();


  return (
    <main className="min-h-screen flex flex-col items-center bg-gradient-to-br from-green-900 to-green-700 text-white">
      <header className="relative w-full max-w-6xl flex items-center justify-between mt-6 mb-4 px-4">
        <h1 className="text-4xl font-bold">PokerBoots × Starknet</h1>

        <button
          className="absolute left-1/2 -translate-x-1/2 px-4 py-2 rounded bg-blue-900 hover:bg-red-500 font-semibold"
          onClick={() => alert('join logic TBD')}
        >
          Join Table
        </button>

        <ActionBar
          street={street}
          onStart={startHand}
          onFlop={dealFlop}
          onTurn={dealTurn}
          onRiver={dealRiver}
        />
      </header>

      <Table />


    </main>
  );
}
