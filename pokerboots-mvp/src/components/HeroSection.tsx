// components/HeroSection.tsx

import appMockup from '../assets/app-mockup.png';

/**
 * HeroSection – concise, on‑point banner explaining the NFT‑tournament flow.
 */
export default function HeroSection() {
  return (
    <section
      id="home"
      className="relative flex flex-col justify-center items-center h-screen px-6 md:px-12 overflow-hidden text-center"
    >
      {/* decorative angle */}
      <div className="absolute inset-0 bg-gradient-to-tr from-[var(--brand-accent)]/20 via-purple-600/10 to-indigo-700/10 [clip-path:polygon(0_0,100%_0,100%_75%,0_100%)] pointer-events-none" />

      {/* content wrapper */}
      <div className="relative z-10 max-w-4xl w-full mx-auto">
        {/* headline */}
        <h1 className="font-extrabold text-4xl md:text-5xl leading-tight uppercase tracking-wider">
          <span className="block text-[var(--brand-accent)]">POKER ON STARKNET</span>
          <span className="block text-white">SPIN UP YOUR TOURNAMENT</span>
          <span className="block text-white">WITH NFT SALE</span>
        </h1>

        {/* subline */}
        <p className="mt-4 text-slate-300 text-lg md:text-xl">
          Mint tickets → Prize pool auto‑escrows → Smart‑contract payouts.
        </p>

        {/* how it works concise */}
        <ul className="mt-6 space-y-2 text-sm md:text-base list-disc pl-6 text-slate-300 text-left">
          <li>Anyone launches a tournament by selling ticket‑NFTs.</li>
          <li>100% of sales locked in-bank by Starknet smart‑contracts.</li>
          <li>After the final hand: 10% platform • 10% creator • 40% winner • 40% top&nbsp;15%.</li>
        </ul>

        {/* CTA */}
        <div className="mt-10 flex gap-4 justify-center">
          <a href="/#mint" className="btn">
            BUY NFT
          </a>
          <a
            href="/play"
            className="btn" style={{ background: 'transparent', color: 'var(--brand-accent)', border: '2px solid var(--brand-accent)' }}
          >
            PLAY NOW
          </a>
        </div>
      </div>

      {/* mockup */}
      <div className="absolute bottom-0 md:bottom-[-5rem] right-1/2 md:right-16 translate-x-1/2 md:translate-x-0 w-[240px] md:w-[340px] rotate-[4deg] shadow-2xl pointer-events-none">
        <img src={appMockup} alt="Poker app mockup" className="w-full h-auto object-contain" />
      </div>
    </section>
  );
}
