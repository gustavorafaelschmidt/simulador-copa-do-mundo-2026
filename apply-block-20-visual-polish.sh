#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 20 — polimento visual, shell esportivo e experiência de produto..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p components/world-cup lib/fifa tests docs .backup/block-20-visual-polish

for file in \
  app/page.tsx \
  app/dashboard/previsoes/grupos/page.tsx \
  app/dashboard/previsoes/mata-mata/page.tsx \
  components/world-cup/VisualSimulatorShell.tsx \
  components/world-cup/VisualInfoRail.tsx \
  lib/fifa/visualProgress.ts \
  tests/visual-progress.test.ts
do
  if [ -f "$file" ]; then
    cp "$file" ".backup/block-20-visual-polish/$(echo "$file" | tr '/' '__').backup"
  fi
done

cat > lib/fifa/visualProgress.ts <<'EOF'
import type { VisualBracketPicks, VisualBracketRoundKey } from "./visualBracketHelpers.ts";
import type { VisualDemoGroup } from "./visualDemoData.ts";
import {
  buildVisualQualifiedTeams,
  countCompletedGroups,
  getDemoBestThirdPlacedTeams,
  type VisualGroupPicks
} from "./visualDemoHelpers.ts";

export type VisualProgressSummary = {
  completedGroups: number;
  totalGroups: number;
  qualifiedCount: number;
  totalQualifiedTarget: number;
  bestThirdsCount: number;
  totalBestThirdsTarget: number;
  bracketPickCount: number;
  totalBracketMatches: number;
  completionPercentage: number;
};

const totalBracketMatchesByRound: Record<VisualBracketRoundKey, number> = {
  round32: 16,
  round16: 8,
  quarterFinals: 4,
  semiFinals: 2,
  final: 1
};

export function getVisualTotalBracketMatches(): number {
  return Object.values(totalBracketMatchesByRound).reduce((total, count) => total + count, 0);
}

export function buildVisualProgressSummary({
  groups,
  groupPicks,
  bracketPicks
}: {
  groups: VisualDemoGroup[];
  groupPicks: VisualGroupPicks;
  bracketPicks: VisualBracketPicks;
}): VisualProgressSummary {
  const completedGroups = countCompletedGroups(groups, groupPicks);
  const qualified = buildVisualQualifiedTeams(groups, groupPicks);
  const bestThirds = getDemoBestThirdPlacedTeams(groups, groupPicks);
  const firstAndSecondQualified = qualified.filter(
    (qualifiedTeam) => qualifiedTeam.position === 1 || qualifiedTeam.position === 2
  );
  const bracketPickCount = Object.keys(bracketPicks).length;
  const totalBracketMatches = getVisualTotalBracketMatches();

  const groupWeight = completedGroups / groups.length;
  const bracketWeight = totalBracketMatches > 0 ? bracketPickCount / totalBracketMatches : 0;

  return {
    completedGroups,
    totalGroups: groups.length,
    qualifiedCount: firstAndSecondQualified.length + bestThirds.length,
    totalQualifiedTarget: 32,
    bestThirdsCount: bestThirds.length,
    totalBestThirdsTarget: 8,
    bracketPickCount,
    totalBracketMatches,
    completionPercentage: Math.round(((groupWeight * 0.55) + (bracketWeight * 0.45)) * 100)
  };
}

export function clampVisualProgressPercentage(value: number): number {
  if (value < 0) {
    return 0;
  }

  if (value > 100) {
    return 100;
  }

  return Math.round(value);
}
EOF

cat > components/world-cup/VisualInfoRail.tsx <<'EOF'
type VisualInfoRailProps = {
  title?: string;
};

const cards = [
  {
    eyebrow: "1",
    title: "Escolha os grupos",
    description: "Defina 1º, 2º e 3º colocados de cada grupo em poucos toques."
  },
  {
    eyebrow: "2",
    title: "Veja os terceiros",
    description: "A interface mostra oito terceiros classificados em modo demo."
  },
  {
    eyebrow: "3",
    title: "Monte o mata-mata",
    description: "Os vencedores avançam automaticamente até a grande final."
  }
];

export function VisualInfoRail({ title = "Como funciona" }: VisualInfoRailProps) {
  return (
    <section className="mx-auto max-w-7xl px-4 pb-8">
      <div className="rounded-[32px] border border-slate-200 bg-white p-4 shadow-[0_18px_60px_rgba(15,23,42,0.08)] md:p-6">
        <div className="mb-4 flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-[11px] font-black uppercase tracking-[0.24em] text-emerald-700">
              Guia rápido
            </p>
            <h2 className="text-2xl font-black text-slate-950">{title}</h2>
          </div>

          <p className="max-w-xl text-sm leading-6 text-slate-500">
            Este visual é inspirado na experiência de simuladores esportivos, com layout,
            fluxo e interações próprias do projeto.
          </p>
        </div>

        <div className="grid gap-3 md:grid-cols-3">
          {cards.map((card) => (
            <article
              className="rounded-3xl border border-slate-200 bg-slate-50 p-4"
              key={card.eyebrow}
            >
              <span className="grid size-9 place-items-center rounded-full bg-emerald-600 text-sm font-black text-white">
                {card.eyebrow}
              </span>
              <h3 className="mt-4 text-lg font-black text-slate-950">{card.title}</h3>
              <p className="mt-2 text-sm leading-6 text-slate-500">{card.description}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
EOF

cat > components/world-cup/VisualSimulatorShell.tsx <<'EOF'
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
EOF

cat > app/page.tsx <<'EOF'
import { VisualSimulatorShell } from "../components/world-cup/VisualSimulatorShell.tsx";
import { VisualWorldCupSimulator } from "../components/world-cup/VisualWorldCupSimulator.tsx";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";

export default function HomePage() {
  return (
    <VisualSimulatorShell activeSection="home">
      <VisualWorldCupSimulator groups={visualDemoGroups} />
    </VisualSimulatorShell>
  );
}
EOF

mkdir -p app/dashboard/previsoes/grupos app/dashboard/previsoes/mata-mata

cat > app/dashboard/previsoes/grupos/page.tsx <<'EOF'
import { VisualSimulatorShell } from "../../../../components/world-cup/VisualSimulatorShell.tsx";
import { VisualWorldCupSimulator } from "../../../../components/world-cup/VisualWorldCupSimulator.tsx";
import { visualDemoGroups } from "../../../../lib/fifa/visualDemoData.ts";

export default function GroupPredictionsVisualPage() {
  return (
    <VisualSimulatorShell activeSection="groups">
      <VisualWorldCupSimulator groups={visualDemoGroups} />
    </VisualSimulatorShell>
  );
}
EOF

cat > app/dashboard/previsoes/mata-mata/page.tsx <<'EOF'
import { VisualSimulatorShell } from "../../../../components/world-cup/VisualSimulatorShell.tsx";
import { VisualWorldCupSimulator } from "../../../../components/world-cup/VisualWorldCupSimulator.tsx";
import { visualDemoGroups } from "../../../../lib/fifa/visualDemoData.ts";

export default function KnockoutPredictionsVisualPage() {
  return (
    <VisualSimulatorShell activeSection="knockout">
      <VisualWorldCupSimulator groups={visualDemoGroups} />
    </VisualSimulatorShell>
  );
}
EOF

cat > tests/visual-progress.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  buildVisualProgressSummary,
  clampVisualProgressPercentage,
  getVisualTotalBracketMatches
} from "../lib/fifa/visualProgress.ts";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";

describe("visual progress helpers", () => {
  it("deve calcular total de jogos do mata-mata visual", () => {
    expect(getVisualTotalBracketMatches()).toBe(31);
  });

  it("deve limitar percentual visual", () => {
    expect(clampVisualProgressPercentage(-10)).toBe(0);
    expect(clampVisualProgressPercentage(55.4)).toBe(55);
    expect(clampVisualProgressPercentage(110)).toBe(100);
  });

  it("deve montar resumo de progresso", () => {
    const summary = buildVisualProgressSummary({
      groups: visualDemoGroups,
      groupPicks: {
        A: {
          first: "A1",
          second: "A2",
          third: "A3"
        }
      },
      bracketPicks: {
        "round32-0": "A2"
      }
    });

    expect(summary.completedGroups).toBe(1);
    expect(summary.totalGroups).toBe(12);
    expect(summary.totalBracketMatches).toBe(31);
    expect(summary.completionPercentage).toBeGreaterThan(0);
  });
});
EOF

cat > docs/visual-polish.md <<'EOF'
# Bloco 20 — Polimento visual

## Entrega

- Shell visual esportivo reutilizável.
- Header sticky desktop/mobile.
- Navegação compacta mobile.
- CTA fixo inferior no mobile.
- Guia rápido explicando o fluxo.
- Helpers de progresso visual testados.

## Próximo passo

Conectar progressos e escolhas ao backend real, mantendo o modo demo apenas para desenvolvimento.
EOF

echo "==> Bloco 20 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run build"
echo "  npm run dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: polish visual simulator shell\""
echo "  git push"
