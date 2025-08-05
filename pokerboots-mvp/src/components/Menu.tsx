// components/Menu.tsx

import { useState } from 'react';

/**
 * FloatingMenu – fixed top navigation with smooth‑scroll hash links to page sections.
 * TailwindCSS utilities assumed.
 */
export default function FloatingMenu() {
  const [open, setOpen] = useState(false);
  const links = [
    { label: 'Home', href: '/#home' },
    { label: 'Mint NFT', href: '/#mint' },
    { label: 'Tournaments', href: '/#boards' },
    { label: 'Follow Us', href: '/#stay' }
  ];

  return (
    <nav className="fixed top-4 left-1/2 -translate-x-1/2 z-50 flex items-center gap-6 card px-8 py-3 rounded-full">
      <span className="font-extrabold text-lg text-[var(--brand-accent)]">PokerBoots</span>

      {/* mobile burger */}
      <button
        onClick={() => setOpen(!open)}
        className="md:hidden w-8 h-8 flex flex-col justify-between"
      >
        <span className="block w-full h-[2px] bg-[var(--brand-accent)]" />
        <span className="block w-full h-[2px] bg-[var(--brand-accent)]" />
        <span className="block w-full h-[2px] bg-[var(--brand-accent)]" />
      </button>

      {/* links */}
      <ul
        className={`md:flex md:gap-6 ${open ? 'flex flex-col gap-4 mt-4' : 'hidden'} md:mt-0`}
      >
        {links.map(l => (
          <li key={l.href}>
            <a
              href={l.href}
              className="text-white font-semibold hover:text-[var(--brand-accent)] transition-colors"
              onClick={() => setOpen(false)}
            >
              {l.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}
