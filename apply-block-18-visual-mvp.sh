#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 18 — UI visual MVP inspirada no simulador esportivo..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p components/world-cup lib/fifa tests docs .backup/block-18-visual-mvp
for file in app/page.tsx app/dashboard/previsoes/grupos/page.tsx app/dashboard/previsoes/mata-mata/page.tsx; do
  [ -f "$file" ] && cp "$file" ".backup/block-18-visual-mvp/$(echo "$file" | tr '/' '__').backup"
done

cat > lib/fifa/visualDemoData.ts <<'EOF'
export type VisualDemoTeam = {
  id: string;
  name: string;
  shortName: string;
  flag: string;
  seed: number;
};

export type VisualDemoGroup = {
  letter: string;
  name: string;
  teams: VisualDemoTeam[];
};

const flags = ["🇧🇷", "🇦🇷", "🇫🇷", "🇪🇸", "🇩🇪", "🇮🇹", "🇵🇹", "🇳🇱", "🇺🇸", "🇲🇽", "🇯🇵", "🇰🇷"];

const teamNames = [
  ["Brasil", "Canadá", "Marrocos", "Escócia"],
  ["Argentina", "Egito", "Austrália", "Noruega"],
  ["França", "Uruguai", "Gana", "Panamá"],
  ["Espanha", "Colômbia", "Tunísia", "Nova Zelândia"],
  ["Alemanha", "Chile", "Japão", "Catar"],
  ["Itália", "México", "Senegal", "Costa Rica"],
  ["Portugal", "Estados Unidos", "África do Sul", "Arábia Saudita"],
  ["Holanda", "Croácia", "Coreia do Sul", "Jamaica"],
  ["Inglaterra", "Paraguai", "Irã", "Honduras"],
  ["Bélgica", "Suíça", "Equador", "Iraque"],
  ["Dinamarca", "Sérvia", "Peru", "China"],
  ["Suécia", "Polônia", "Nigéria", "Bolívia"]
];

export const visualDemoGroups: VisualDemoGroup[] = teamNames.map((teams, groupIndex) => {
  const letter = String.fromCharCode(65 + groupIndex);

  return {
    letter,
    name: `Grupo ${letter}`,
    teams: teams.map((name, teamIndex) => ({
      id: `${letter}${teamIndex + 1}`,
      name,
      shortName: name.slice(0, 3).toUpperCase(),
      flag: flags[(groupIndex + teamIndex) % flags.length] ?? "🏳️",
      seed: teamIndex + 1
    }))
  };
});
EOF

cat > lib/fifa/visualDemoHelpers.ts <<'EOF'
import type { VisualDemoGroup, VisualDemoTeam } from "./visualDemoData.ts";

export type VisualPickPosition = "first" | "second" | "third";

export type VisualGroupPick = {
  first?: string;
  second?: string;
  third?: string;
};

export type VisualGroupPicks = Record<string, VisualGroupPick>;

export type VisualQualifiedTeam = {
  groupLetter: string;
  position: 1 | 2 | 3;
  team: VisualDemoTeam;
};

export function chooseVisualTeam(
  currentPick: VisualGroupPick,
  position: VisualPickPosition,
  teamId: string
): VisualGroupPick {
  const nextPick: VisualGroupPick = {};

  for (const key of ["first", "second", "third"] as const) {
    const value = currentPick[key];

    if (value && value !== teamId) {
      nextPick[key] = value;
    }
  }

  if (currentPick[position] === teamId) {
    delete nextPick[position];
    return nextPick;
  }

  nextPick[position] = teamId;

  return nextPick;
}

export function buildVisualQualifiedTeams(
  groups: VisualDemoGroup[],
  picks: VisualGroupPicks
): VisualQualifiedTeam[] {
  const qualified: VisualQualifiedTeam[] = [];

  for (const group of groups) {
    const pick = picks[group.letter] ?? {};
    const entries = [
      ["first", 1],
      ["second", 2],
      ["third", 3]
    ] as const;

    for (const [key, position] of entries) {
      const teamId = pick[key];
      const team = group.teams.find((candidate) => candidate.id === teamId);

      if (team) {
        qualified.push({
          groupLetter: group.letter,
          position,
          team
        });
      }
    }
  }

  return qualified;
}

export function countCompletedGroups(groups: VisualDemoGroup[], picks: VisualGroupPicks): number {
  return groups.filter((group) => {
    const pick = picks[group.letter];

    return Boolean(pick?.first && pick.second && pick.third);
  }).length;
}

export function getDemoBestThirdPlacedTeams(
  groups: VisualDemoGroup[],
  picks: VisualGroupPicks
): VisualQualifiedTeam[] {
  return buildVisualQualifiedTeams(groups, picks)
    .filter((qualified) => qualified.position === 3)
    .slice(0, 8);
}
EOF

cat > components/world-cup/VisualWorldCupSimulator.tsx <<'EOF'
"use client";

import { useMemo, useState } from "react";
import type { VisualDemoGroup, VisualDemoTeam } from "../../lib/fifa/visualDemoData.ts";
import {
  buildVisualQualifiedTeams,
  chooseVisualTeam,
  countCompletedGroups,
  getDemoBestThirdPlacedTeams,
  type VisualGroupPicks,
  type VisualPickPosition
} from "../../lib/fifa/visualDemoHelpers.ts";

type VisualWorldCupSimulatorProps = {
  groups: VisualDemoGroup[];
};

const positionConfig = [
  ["first", "1º"],
  ["second", "2º"],
  ["third", "3º"]
] as const;

const roundOf32Tokens = [
  ["2A", "2B"],
  ["1E", "3º"],
  ["1F", "2C"],
  ["1C", "2F"],
  ["1I", "3º"],
  ["2E", "2I"],
  ["1A", "3º"],
  ["1L", "3º"],
  ["1D", "3º"],
  ["1G", "3º"],
  ["2K", "2L"],
  ["1H", "2J"],
  ["1B", "3º"],
  ["1J", "2H"],
  ["1K", "3º"],
  ["2D", "2G"]
] as const;

function shuffleTeams(teams: VisualDemoTeam[]): VisualDemoTeam[] {
  return [...teams].sort(() => Math.random() - 0.5);
}

function TeamIdentity({ team }: { team: VisualDemoTeam }) {
  return (
    <span className="flex min-w-0 items-center gap-2">
      <span
        aria-hidden="true"
        className="grid size-8 shrink-0 place-items-center rounded-full border border-white/70 bg-white text-lg shadow-sm"
      >
        {team.flag}
      </span>
      <span className="min-w-0">
        <span className="block truncate font-semibold text-slate-900">{team.name}</span>
        <span className="block text-[11px] font-bold uppercase tracking-[0.22em] text-slate-400">
          {team.shortName}
        </span>
      </span>
    </span>
  );
}

function GroupCard({
  group,
  pick,
  onChoose,
  onRandomize
}: {
  group: VisualDemoGroup;
  pick: Record<string, string | undefined>;
  onChoose: (position: VisualPickPosition, teamId: string) => void;
  onRandomize: () => void;
}) {
  return (
    <article className="overflow-hidden rounded-[28px] border border-slate-200 bg-white shadow-[0_18px_60px_rgba(15,23,42,0.09)]">
      <header className="flex items-center justify-between bg-[#f4f6f8] px-4 py-3">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-emerald-700">
            Fase de grupos
          </p>
          <h3 className="text-xl font-black text-slate-950">{group.name}</h3>
        </div>
        <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-slate-500 shadow-sm">
          4 seleções
        </span>
      </header>

      <div className="grid grid-cols-[1fr_44px_44px_44px] items-center border-b border-slate-100 px-4 py-3 text-[11px] font-black uppercase tracking-[0.16em] text-slate-400">
        <span>Seleção</span>
        <span className="text-center">1º</span>
        <span className="text-center">2º</span>
        <span className="text-center">3º</span>
      </div>

      <div className="divide-y divide-slate-100">
        {group.teams.map((team) => {
          const selectedPosition = positionConfig.find(([key]) => pick[key] === team.id)?.[0];

          return (
            <div
              className={`grid grid-cols-[1fr_44px_44px_44px] items-center gap-1 px-4 py-3 transition ${
                selectedPosition ? "bg-emerald-50/70" : "bg-white"
              }`}
              key={team.id}
            >
              <TeamIdentity team={team} />

              {positionConfig.map(([key, label]) => {
                const selected = pick[key] === team.id;

                return (
                  <button
                    aria-label={`${team.name} como ${label} colocado do ${group.name}`}
                    className={`mx-auto grid size-9 place-items-center rounded-full border text-sm font-black transition ${
                      selected
                        ? "border-emerald-600 bg-emerald-600 text-white shadow-[0_8px_22px_rgba(5,150,105,0.3)]"
                        : "border-slate-200 bg-slate-50 text-slate-400 hover:border-emerald-400 hover:text-emerald-700"
                    }`}
                    key={key}
                    onClick={() => onChoose(key, team.id)}
                    type="button"
                  >
                    {selected ? "✓" : label}
                  </button>
                );
              })}
            </div>
          );
        })}
      </div>

      <footer className="border-t border-slate-100 bg-slate-50/80 px-4 py-3">
        <button
          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-black text-slate-700 transition hover:border-emerald-500 hover:text-emerald-700"
          onClick={onRandomize}
          type="button"
        >
          Sorteio aleatório
        </button>
      </footer>
    </article>
  );
}

function BracketPreview({
  groups,
  picks
}: {
  groups: VisualDemoGroup[];
  picks: VisualGroupPicks;
}) {
  const qualified = buildVisualQualifiedTeams(groups, picks);
  const bestThirds = getDemoBestThirdPlacedTeams(groups, picks);
  const byToken = new Map<string, VisualDemoTeam>();

  for (const qualifiedTeam of qualified) {
    const prefix =
      qualifiedTeam.position === 1 ? "1" : qualifiedTeam.position === 2 ? "2" : "3";
    byToken.set(`${prefix}${qualifiedTeam.groupLetter}`, qualifiedTeam.team);
  }

  const thirdQueue = [...bestThirds];

  function resolveToken(token: string): VisualDemoTeam | null {
    if (token === "3º") {
      return thirdQueue.shift()?.team ?? null;
    }

    return byToken.get(token) ?? null;
  }

  return (
    <section className="rounded-[32px] border border-slate-200 bg-white p-4 shadow-[0_18px_60px_rgba(15,23,42,0.08)] md:p-6">
      <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-emerald-700">
            Mata-mata
          </p>
          <h2 className="mt-1 text-2xl font-black text-slate-950">Chave automática</h2>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">
            Prévia visual dos 16-avos. A matriz oficial completa dos terceiros deve
            continuar vindo dos dados oficiais versionados.
          </p>
        </div>

        <div className="rounded-2xl bg-slate-950 px-4 py-3 text-center text-white">
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-emerald-300">
            Campeã
          </p>
          <p className="text-lg font-black">🏆 A definir</p>
        </div>
      </div>

      <div className="mb-4 grid grid-cols-5 gap-2 text-center text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">
        <span>Décima-sextas</span>
        <span>Oitavas</span>
        <span>Quartas</span>
        <span>Semi</span>
        <span>Final</span>
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        {roundOf32Tokens.map(([homeToken, awayToken], index) => {
          const home = resolveToken(homeToken);
          const away = resolveToken(awayToken);

          return (
            <article
              className="rounded-2xl border border-slate-200 bg-slate-50 p-3"
              key={`${homeToken}-${awayToken}-${index}`}
            >
              <p className="mb-2 text-[10px] font-black uppercase tracking-[0.18em] text-slate-400">
                Jogo {index + 73}
              </p>

              {[home, away].map((team, teamIndex) => (
                <div
                  className="mb-2 flex items-center justify-between rounded-xl bg-white px-3 py-2 shadow-sm last:mb-0"
                  key={`${index}-${teamIndex}`}
                >
                  {team ? (
                    <TeamIdentity team={team} />
                  ) : (
                    <span className="text-sm font-bold text-slate-400">A definir</span>
                  )}
                  <button
                    className="rounded-full border border-slate-200 px-3 py-1 text-xs font-black text-slate-400"
                    type="button"
                  >
                    escolher
                  </button>
                </div>
              ))}
            </article>
          );
        })}
      </div>
    </section>
  );
}

export function VisualWorldCupSimulator({ groups }: VisualWorldCupSimulatorProps) {
  const [picks, setPicks] = useState<VisualGroupPicks>({});
  const completedGroups = countCompletedGroups(groups, picks);
  const bestThirds = getDemoBestThirdPlacedTeams(groups, picks);

  const qualifiedCount = useMemo(() => {
    const qualified = buildVisualQualifiedTeams(groups, picks);
    const firstAndSecond = qualified.filter((team) => team.position === 1 || team.position === 2);

    return firstAndSecond.length + bestThirds.length;
  }, [bestThirds.length, groups, picks]);

  function choose(groupLetter: string, position: VisualPickPosition, teamId: string) {
    setPicks((current) => ({
      ...current,
      [groupLetter]: chooseVisualTeam(current[groupLetter] ?? {}, position, teamId)
    }));
  }

  function randomizeGroup(group: VisualDemoGroup) {
    const [first, second, third] = shuffleTeams(group.teams);

    setPicks((current) => ({
      ...current,
      [group.letter]: {
        first: first?.id,
        second: second?.id,
        third: third?.id
      }
    }));
  }

  function randomizeAll() {
    setPicks(
      Object.fromEntries(
        groups.map((group) => {
          const [first, second, third] = shuffleTeams(group.teams);

          return [
            group.letter,
            {
              first: first?.id,
              second: second?.id,
              third: third?.id
            }
          ];
        })
      )
    );
  }

  function reset() {
    setPicks({});
  }

  return (
    <div className="space-y-8">
      <section className="grid gap-4 rounded-[32px] border border-white/20 bg-slate-950 p-4 text-white shadow-[0_24px_80px_rgba(15,23,42,0.22)] md:grid-cols-[1fr_auto] md:p-6">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.24em] text-emerald-300">
            Simulador Copa 2026
          </p>
          <h1 className="mt-3 max-w-3xl text-3xl font-black leading-tight md:text-5xl">
            Escolha os classificados e monte o caminho até a taça.
          </h1>
          <p className="mt-4 max-w-2xl text-sm leading-6 text-slate-300 md:text-base">
            Experiência mobile first inspirada em simuladores esportivos: grupos compactos,
            botões rápidos, classificados em tempo real e prévia do mata-mata.
          </p>
        </div>

        <aside className="grid grid-cols-3 gap-2 md:w-80">
          <div className="rounded-3xl bg-white/10 p-4 text-center">
            <p className="text-2xl font-black">{completedGroups}/12</p>
            <p className="text-[10px] font-black uppercase tracking-[0.18em] text-slate-300">
              Grupos
            </p>
          </div>
          <div className="rounded-3xl bg-white/10 p-4 text-center">
            <p className="text-2xl font-black">{qualifiedCount}/32</p>
            <p className="text-[10px] font-black uppercase tracking-[0.18em] text-slate-300">
              Classificados
            </p>
          </div>
          <div className="rounded-3xl bg-white/10 p-4 text-center">
            <p className="text-2xl font-black">{bestThirds.length}/8</p>
            <p className="text-[10px] font-black uppercase tracking-[0.18em] text-slate-300">
              Terceiros
            </p>
          </div>
        </aside>
      </section>

      <div className="sticky top-0 z-20 -mx-4 border-y border-slate-200 bg-white/90 px-4 py-3 backdrop-blur md:mx-0 md:rounded-3xl md:border md:shadow-sm">
        <div className="flex gap-2 overflow-x-auto">
          <button
            className="shrink-0 rounded-full bg-emerald-600 px-5 py-3 text-sm font-black text-white"
            onClick={randomizeAll}
            type="button"
          >
            Preencher todas as chaves
          </button>
          <button
            className="shrink-0 rounded-full border border-slate-200 bg-white px-5 py-3 text-sm font-black text-slate-700"
            onClick={reset}
            type="button"
          >
            Reiniciar
          </button>
          <button
            className="shrink-0 rounded-full border border-slate-200 bg-white px-5 py-3 text-sm font-black text-slate-700"
            type="button"
          >
            Compartilhar
          </button>
        </div>
      </div>

      <section id="grupos" className="space-y-4">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.24em] text-emerald-700">
            Grupos
          </p>
          <h2 className="mt-1 text-3xl font-black text-slate-950">Fase de grupos</h2>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          {groups.map((group) => (
            <GroupCard
              group={group}
              key={group.letter}
              onChoose={(position, teamId) => choose(group.letter, position, teamId)}
              onRandomize={() => randomizeGroup(group)}
              pick={picks[group.letter] ?? {}}
            />
          ))}
        </div>
      </section>

      <BracketPreview groups={groups} picks={picks} />
    </div>
  );
}
EOF

cat > app/page.tsx <<'EOF'
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
EOF

mkdir -p app/dashboard/previsoes/grupos app/dashboard/previsoes/mata-mata

cat > app/dashboard/previsoes/grupos/page.tsx <<'EOF'
import { VisualWorldCupSimulator } from "../../../../components/world-cup/VisualWorldCupSimulator.tsx";
import { visualDemoGroups } from "../../../../lib/fifa/visualDemoData.ts";

export default function GroupPredictionsVisualPage() {
  return (
    <main className="min-h-dvh bg-[#eef1f4] px-4 py-6">
      <section className="mx-auto max-w-7xl">
        <VisualWorldCupSimulator groups={visualDemoGroups} />
      </section>
    </main>
  );
}
EOF

cat > app/dashboard/previsoes/mata-mata/page.tsx <<'EOF'
import { VisualWorldCupSimulator } from "../../../../components/world-cup/VisualWorldCupSimulator.tsx";
import { visualDemoGroups } from "../../../../lib/fifa/visualDemoData.ts";

export default function KnockoutPredictionsVisualPage() {
  return (
    <main className="min-h-dvh bg-[#eef1f4] px-4 py-6">
      <section className="mx-auto max-w-7xl">
        <VisualWorldCupSimulator groups={visualDemoGroups} />
      </section>
    </main>
  );
}
EOF

cat > tests/visual-demo-helpers.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";
import {
  buildVisualQualifiedTeams,
  chooseVisualTeam,
  countCompletedGroups,
  getDemoBestThirdPlacedTeams
} from "../lib/fifa/visualDemoHelpers.ts";

describe("visual demo helpers", () => {
  it("deve selecionar uma equipe por posição e remover duplicidade", () => {
    const firstPick = chooseVisualTeam({}, "first", "A1");
    const secondPick = chooseVisualTeam(firstPick, "second", "A1");

    expect(secondPick).toEqual({
      second: "A1"
    });
  });

  it("deve contar grupos completos", () => {
    expect(
      countCompletedGroups(visualDemoGroups, {
        A: {
          first: "A1",
          second: "A2",
          third: "A3"
        }
      })
    ).toBe(1);
  });

  it("deve montar classificados visuais", () => {
    const qualified = buildVisualQualifiedTeams(visualDemoGroups, {
      A: {
        first: "A1",
        second: "A2",
        third: "A3"
      }
    });

    expect(qualified).toHaveLength(3);
    expect(qualified[0]?.team.name).toBe("Brasil");
  });

  it("deve limitar terceiros demo a oito seleções", () => {
    const picks = Object.fromEntries(
      visualDemoGroups.map((group) => [
        group.letter,
        {
          first: `${group.letter}1`,
          second: `${group.letter}2`,
          third: `${group.letter}3`
        }
      ])
    );

    expect(getDemoBestThirdPlacedTeams(visualDemoGroups, picks)).toHaveLength(8);
  });
});
EOF

cat > docs/visual-mvp.md <<'EOF'
# Bloco 18 — UI Visual MVP

## Objetivo

Criar uma primeira experiência visual fortemente inspirada em simuladores esportivos de Copa:

- cards de grupos;
- colunas 1º, 2º e 3º;
- botão de sorteio por grupo;
- ações de preencher, reiniciar e compartilhar;
- prévia visual do mata-mata;
- layout mobile first.

## Limite legal

Não foram usados assets, marcas, logos, imagens, ícones proprietários ou código-fonte de terceiros.

A inspiração é de fluxo e composição visual, com identidade própria do projeto.
EOF

echo "==> Bloco 18 aplicado."
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
echo "  git commit -m \"feat: add visual world cup simulator MVP\""
echo "  git push"
