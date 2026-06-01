import Link from "next/link";
import type { ReactNode } from "react";
import { VisualInfoRail } from "./VisualInfoRail.tsx";

type VisualSimulatorShellProps = {
  children: ReactNode;
  activeSection?: "home" | "groups" | "knockout";
};

const navigation = [
  {
    label: "Simulador",
    href: "/",
    key: "home"
  },
  {
    label: "Grupos",
    href: "/dashboard/previsoes/grupos",
    key: "groups"
  },
  {
    label: "Mata-mata",
    href: "/dashboard/previsoes/mata-mata",
    key: "knockout"
  },
  {
    label: "Ranking",
    href: "/ranking/individual",
    key: "ranking"
  }
] as const;

export function VisualSimulatorShell({
  children,
  activeSection = "home"
}: VisualSimulatorShellProps) {
  return (
    <main className="min-h-dvh bg-[#eef1f4]">
      <header className="sticky top-0 z-40 border-b border-slate-200 bg-white/95 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-4 py-4">
          <Link className="min-w-0" href="/">
            <p className="text-[10px] font-black uppercase tracking-[0.28em] text-emerald-700">
              Bolão 2026
            </p>
            <strong className="block truncate text-lg font-black text-slate-950">
              Simulador da Copa
            </strong>
          </Link>

          <nav className="hidden items-center gap-2 md:flex">
            {navigation.map((item) => (
              <Link
                className={`rounded-full px-4 py-2 text-sm font-bold transition ${
                  item.key === activeSection
                    ? "bg-slate-950 text-white"
                    : "text-slate-600 hover:bg-slate-100"
                }`}
                href={item.href}
                key={item.key}
              >
                {item.label}
              </Link>
            ))}

            <Link
              className="rounded-full bg-emerald-600 px-5 py-2 text-sm font-black text-white shadow-[0_8px_24px_rgba(5,150,105,0.25)]"
              href="/entrar"
            >
              Entrar
            </Link>
          </nav>
        </div>

        <nav className="flex gap-2 overflow-x-auto border-t border-slate-100 px-4 py-2 md:hidden">
          {navigation.map((item) => (
            <Link
              className={`shrink-0 rounded-full px-4 py-2 text-xs font-black transition ${
                item.key === activeSection
                  ? "bg-slate-950 text-white"
                  : "bg-slate-100 text-slate-600"
              }`}
              href={item.href}
              key={item.key}
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </header>

      <section className="mx-auto max-w-7xl px-4 py-6 md:py-10">{children}</section>

      <VisualInfoRail />

      <div className="fixed inset-x-0 bottom-0 z-40 border-t border-slate-200 bg-white/95 p-3 shadow-[0_-14px_45px_rgba(15,23,42,0.12)] backdrop-blur md:hidden">
        <Link
          className="flex items-center justify-center rounded-2xl bg-emerald-600 px-4 py-3 text-sm font-black text-white"
          href="/dashboard/previsoes/grupos"
        >
          Continuar simulação
        </Link>
      </div>
    </main>
  );
}
