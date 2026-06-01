import Link from "next/link";
import { VisualWorldCupSimulator } from "../components/world-cup/VisualWorldCupSimulator.tsx";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";

export default function HomePage() {
  return (
    <main className="min-h-dvh bg-[#eef1f4]">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-4 py-4">
          <div>
            <p className="text-[10px] font-black uppercase tracking-[0.28em] text-emerald-700">
              Bolão 2026
            </p>
            <strong className="text-lg font-black text-slate-950">Simulador da Copa</strong>
          </div>

          <nav className="hidden items-center gap-2 md:flex">
            <a className="rounded-full px-4 py-2 text-sm font-bold text-slate-600" href="#grupos">
              Grupos
            </a>
            <Link
              className="rounded-full px-4 py-2 text-sm font-bold text-slate-600"
              href="/ranking/individual"
            >
              Ranking
            </Link>
            <Link
              className="rounded-full bg-slate-950 px-5 py-2 text-sm font-black text-white"
              href="/entrar"
            >
              Entrar
            </Link>
          </nav>
        </div>
      </header>

      <section className="mx-auto max-w-7xl px-4 py-6 md:py-10">
        <VisualWorldCupSimulator groups={visualDemoGroups} />
      </section>
    </main>
  );
}
