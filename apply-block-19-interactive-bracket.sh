#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 19 — mata-mata interativo, persistência local e UX visual avançada..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p components/world-cup lib/fifa tests docs .backup/block-19-interactive-bracket

for file in \
  components/world-cup/VisualWorldCupSimulator.tsx \
  lib/fifa/visualBracketHelpers.ts \
  tests/visual-bracket-helpers.test.ts \
  docs/visual-interactive-bracket.md
do
  if [ -f "$file" ]; then
    cp "$file" ".backup/block-19-interactive-bracket/$(echo "$file" | tr '/' '__').backup"
  fi
done

cat > lib/fifa/visualBracketHelpers.ts <<'EOF'
import type { VisualDemoGroup, VisualDemoTeam } from "./visualDemoData.ts";
import {
  buildVisualQualifiedTeams,
  getDemoBestThirdPlacedTeams,
  type VisualGroupPicks
} from "./visualDemoHelpers.ts";

export type VisualBracketRoundKey = "round32" | "round16" | "quarterFinals" | "semiFinals" | "final";

export type VisualBracketMatch = {
  id: string;
  roundKey: VisualBracketRoundKey;
  matchNumber: number;
  homeToken: string;
  awayToken: string;
  homeTeam: VisualDemoTeam | null;
  awayTeam: VisualDemoTeam | null;
};

export type VisualBracketPicks = Record<string, string>;

export const visualRoundOf32Tokens = [
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

function getTeamByToken(
  token: string,
  byToken: Map<string, VisualDemoTeam>,
  thirdQueue: VisualDemoTeam[]
): VisualDemoTeam | null {
  if (token === "3º") {
    return thirdQueue.shift() ?? null;
  }

  return byToken.get(token) ?? null;
}

function getWinner(match: VisualBracketMatch, picks: VisualBracketPicks): VisualDemoTeam | null {
  const winnerId = picks[match.id];

  if (!winnerId) {
    return null;
  }

  if (match.homeTeam?.id === winnerId) {
    return match.homeTeam;
  }

  if (match.awayTeam?.id === winnerId) {
    return match.awayTeam;
  }

  return null;
}

export function buildVisualRoundOf32(
  groups: VisualDemoGroup[],
  picks: VisualGroupPicks
): VisualBracketMatch[] {
  const qualified = buildVisualQualifiedTeams(groups, picks);
  const bestThirds = getDemoBestThirdPlacedTeams(groups, picks).map((qualifiedTeam) => qualifiedTeam.team);
  const byToken = new Map<string, VisualDemoTeam>();

  for (const qualifiedTeam of qualified) {
    const prefix =
      qualifiedTeam.position === 1 ? "1" : qualifiedTeam.position === 2 ? "2" : "3";
    byToken.set(`${prefix}${qualifiedTeam.groupLetter}`, qualifiedTeam.team);
  }

  const thirdQueue = [...bestThirds];

  return visualRoundOf32Tokens.map(([homeToken, awayToken], index) => ({
    id: `round32-${index}`,
    roundKey: "round32",
    matchNumber: index + 73,
    homeToken,
    awayToken,
    homeTeam: getTeamByToken(homeToken, byToken, thirdQueue),
    awayTeam: getTeamByToken(awayToken, byToken, thirdQueue)
  }));
}

export function buildVisualNextRound({
  previousRound,
  picks,
  roundKey,
  firstMatchNumber
}: {
  previousRound: VisualBracketMatch[];
  picks: VisualBracketPicks;
  roundKey: VisualBracketRoundKey;
  firstMatchNumber: number;
}): VisualBracketMatch[] {
  const matches: VisualBracketMatch[] = [];

  for (let index = 0; index < previousRound.length; index += 2) {
    const homeSource = previousRound[index];
    const awaySource = previousRound[index + 1];

    matches.push({
      id: `${roundKey}-${index / 2}`,
      roundKey,
      matchNumber: firstMatchNumber + index / 2,
      homeToken: homeSource ? `Vencedor ${homeSource.matchNumber}` : "A definir",
      awayToken: awaySource ? `Vencedor ${awaySource.matchNumber}` : "A definir",
      homeTeam: homeSource ? getWinner(homeSource, picks) : null,
      awayTeam: awaySource ? getWinner(awaySource, picks) : null
    });
  }

  return matches;
}

export function buildVisualBracketRounds(
  groups: VisualDemoGroup[],
  groupPicks: VisualGroupPicks,
  bracketPicks: VisualBracketPicks
): Record<VisualBracketRoundKey, VisualBracketMatch[]> {
  const round32 = buildVisualRoundOf32(groups, groupPicks);
  const round16 = buildVisualNextRound({
    previousRound: round32,
    picks: bracketPicks,
    roundKey: "round16",
    firstMatchNumber: 89
  });
  const quarterFinals = buildVisualNextRound({
    previousRound: round16,
    picks: bracketPicks,
    roundKey: "quarterFinals",
    firstMatchNumber: 97
  });
  const semiFinals = buildVisualNextRound({
    previousRound: quarterFinals,
    picks: bracketPicks,
    roundKey: "semiFinals",
    firstMatchNumber: 101
  });
  const final = buildVisualNextRound({
    previousRound: semiFinals,
    picks: bracketPicks,
    roundKey: "final",
    firstMatchNumber: 104
  });

  return {
    round32,
    round16,
    quarterFinals,
    semiFinals,
    final
  };
}

export function getVisualChampion(
  rounds: Record<VisualBracketRoundKey, VisualBracketMatch[]>,
  picks: VisualBracketPicks
): VisualDemoTeam | null {
  const finalMatch = rounds.final[0];

  return finalMatch ? getWinner(finalMatch, picks) : null;
}

export function sanitizeVisualBracketPicks(
  rounds: Record<VisualBracketRoundKey, VisualBracketMatch[]>,
  picks: VisualBracketPicks
): VisualBracketPicks {
  const validPicks: VisualBracketPicks = {};

  for (const round of Object.values(rounds)) {
    for (const match of round) {
      const pickedTeamId = picks[match.id];

      if (!pickedTeamId) {
        continue;
      }

      if (match.homeTeam?.id === pickedTeamId || match.awayTeam?.id === pickedTeamId) {
        validPicks[match.id] = pickedTeamId;
      }
    }
  }

  return validPicks;
}
EOF

cat > components/world-cup/VisualWorldCupSimulator.tsx <<'EOF'
"use client";

import { useEffect, useMemo, useState } from "react";
import type { VisualDemoGroup, VisualDemoTeam } from "../../lib/fifa/visualDemoData.ts";
import {
  buildVisualBracketRounds,
  getVisualChampion,
  sanitizeVisualBracketPicks,
  type VisualBracketMatch,
  type VisualBracketPicks,
  type VisualBracketRoundKey
} from "../../lib/fifa/visualBracketHelpers.ts";
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

type PersistedVisualState = {
  groupPicks: VisualGroupPicks;
  bracketPicks: VisualBracketPicks;
};

const storageKey = "simulador-copa-2026:visual-state:v1";

const positionConfig = [
  ["first", "1º"],
  ["second", "2º"],
  ["third", "3º"]
] as const;

const roundLabels: Record<VisualBracketRoundKey, string> = {
  round32: "16-avos",
  round16: "Oitavas",
  quarterFinals: "Quartas",
  semiFinals: "Semifinais",
  final: "Final"
};

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

function TeamPickButton({
  team,
  selected,
  disabled,
  onPick
}: {
  team: VisualDemoTeam | null;
  selected: boolean;
  disabled: boolean;
  onPick: () => void;
}) {
  return (
    <button
      className={`flex w-full items-center justify-between rounded-xl border px-3 py-2 text-left transition ${
        selected
          ? "border-emerald-600 bg-emerald-50 shadow-[0_8px_22px_rgba(5,150,105,0.14)]"
          : "border-slate-200 bg-white hover:border-emerald-300"
      } ${disabled ? "cursor-not-allowed opacity-55" : ""}`}
      disabled={disabled}
      onClick={onPick}
      type="button"
    >
      {team ? <TeamIdentity team={team} /> : <span className="text-sm font-bold text-slate-400">A definir</span>}
      <span
        className={`grid size-7 place-items-center rounded-full text-xs font-black ${
          selected ? "bg-emerald-600 text-white" : "bg-slate-100 text-slate-400"
        }`}
      >
        {selected ? "✓" : "›"}
      </span>
    </button>
  );
}

function BracketMatchCard({
  match,
  pickedTeamId,
  onPick
}: {
  match: VisualBracketMatch;
  pickedTeamId?: string;
  onPick: (matchId: string, teamId: string) => void;
}) {
  const canPickHome = Boolean(match.homeTeam);
  const canPickAway = Boolean(match.awayTeam);

  return (
    <article className="rounded-2xl border border-slate-200 bg-slate-50 p-3">
      <div className="mb-2 flex items-center justify-between">
        <p className="text-[10px] font-black uppercase tracking-[0.18em] text-slate-400">
          Jogo {match.matchNumber}
        </p>
        <span className="rounded-full bg-white px-2 py-1 text-[10px] font-black text-slate-400">
          {match.homeToken} × {match.awayToken}
        </span>
      </div>

      <div className="space-y-2">
        <TeamPickButton
          disabled={!canPickHome}
          onPick={() => match.homeTeam && onPick(match.id, match.homeTeam.id)}
          selected={pickedTeamId === match.homeTeam?.id}
          team={match.homeTeam}
        />
        <TeamPickButton
          disabled={!canPickAway}
          onPick={() => match.awayTeam && onPick(match.id, match.awayTeam.id)}
          selected={pickedTeamId === match.awayTeam?.id}
          team={match.awayTeam}
        />
      </div>
    </article>
  );
}

function InteractiveBracket({
  rounds,
  bracketPicks,
  champion,
  onPick
}: {
  rounds: Record<VisualBracketRoundKey, VisualBracketMatch[]>;
  bracketPicks: VisualBracketPicks;
  champion: VisualDemoTeam | null;
  onPick: (matchId: string, teamId: string) => void;
}) {
  const roundOrder: VisualBracketRoundKey[] = [
    "round32",
    "round16",
    "quarterFinals",
    "semiFinals",
    "final"
  ];

  return (
    <section className="rounded-[32px] border border-slate-200 bg-white p-4 shadow-[0_18px_60px_rgba(15,23,42,0.08)] md:p-6">
      <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-emerald-700">
            Mata-mata
          </p>
          <h2 className="mt-1 text-2xl font-black text-slate-950">Chave interativa</h2>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">
            Escolha os vencedores de cada confronto. As próximas fases são atualizadas
            automaticamente conforme suas escolhas.
          </p>
        </div>

        <div className="rounded-2xl bg-slate-950 px-4 py-3 text-center text-white">
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-emerald-300">
            Campeã
          </p>
          <p className="text-lg font-black">
            {champion ? `${champion.flag} ${champion.name}` : "🏆 A definir"}
          </p>
        </div>
      </div>

      <div className="-mx-4 overflow-x-auto px-4 pb-2">
        <div className="grid min-w-[1180px] grid-cols-5 gap-4">
          {roundOrder.map((roundKey) => (
            <div className="space-y-3" key={roundKey}>
              <div className="sticky top-0 rounded-2xl bg-slate-950 px-3 py-2 text-center text-xs font-black uppercase tracking-[0.18em] text-white">
                {roundLabels[roundKey]}
              </div>

              {rounds[roundKey].map((match) => (
                <BracketMatchCard
                  bracketPicks={bracketPicks}
                  key={match.id}
                  match={match}
                  onPick={onPick}
                  pickedTeamId={bracketPicks[match.id]}
                />
              ))}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function QualifiedStrip({
  groups,
  picks
}: {
  groups: VisualDemoGroup[];
  picks: VisualGroupPicks;
}) {
  const qualified = buildVisualQualifiedTeams(groups, picks);
  const bestThirds = getDemoBestThirdPlacedTeams(groups, picks);

  return (
    <section className="rounded-[28px] border border-slate-200 bg-white p-4 shadow-sm">
      <div className="mb-3 flex items-center justify-between gap-3">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-emerald-700">
            Classificados
          </p>
          <h2 className="text-lg font-black text-slate-950">32 vagas em construção</h2>
        </div>
        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-black text-slate-500">
          {qualified.length}/36 escolhas
        </span>
      </div>

      <div className="flex gap-2 overflow-x-auto pb-1">
        {qualified.map((qualifiedTeam) => {
          const isThird = qualifiedTeam.position === 3;
          const thirdQualified = bestThirds.some(
            (team) => team.groupLetter === qualifiedTeam.groupLetter
          );

          return (
            <span
              className={`flex shrink-0 items-center gap-2 rounded-full border px-3 py-2 text-sm font-bold ${
                isThird && !thirdQualified
                  ? "border-slate-200 bg-slate-50 text-slate-400"
                  : "border-emerald-100 bg-emerald-50 text-emerald-800"
              }`}
              key={`${qualifiedTeam.groupLetter}-${qualifiedTeam.position}-${qualifiedTeam.team.id}`}
            >
              <span aria-hidden="true">{qualifiedTeam.team.flag}</span>
              {qualifiedTeam.team.name}
              <small className="font-black">
                {qualifiedTeam.position}º {qualifiedTeam.groupLetter}
              </small>
            </span>
          );
        })}

        {qualified.length === 0 ? (
          <span className="text-sm font-medium text-slate-400">
            Escolha os classificados nos grupos para preencher esta área.
          </span>
        ) : null}
      </div>
    </section>
  );
}

export function VisualWorldCupSimulator({ groups }: VisualWorldCupSimulatorProps) {
  const [groupPicks, setGroupPicks] = useState<VisualGroupPicks>({});
  const [bracketPicks, setBracketPicks] = useState<VisualBracketPicks>({});
  const [hasMounted, setHasMounted] = useState(false);
  const [shareFeedback, setShareFeedback] = useState<string | null>(null);

  const completedGroups = countCompletedGroups(groups, groupPicks);
  const bestThirds = getDemoBestThirdPlacedTeams(groups, groupPicks);

  const rounds = useMemo(
    () => buildVisualBracketRounds(groups, groupPicks, bracketPicks),
    [bracketPicks, groups, groupPicks]
  );

  const champion = useMemo(() => getVisualChampion(rounds, bracketPicks), [bracketPicks, rounds]);

  const qualifiedCount = useMemo(() => {
    const qualified = buildVisualQualifiedTeams(groups, groupPicks);
    const firstAndSecond = qualified.filter((team) => team.position === 1 || team.position === 2);

    return firstAndSecond.length + bestThirds.length;
  }, [bestThirds.length, groups, groupPicks]);

  useEffect(() => {
    setHasMounted(true);

    try {
      const rawState = window.localStorage.getItem(storageKey);

      if (!rawState) {
        return;
      }

      const parsedState = JSON.parse(rawState) as Partial<PersistedVisualState>;

      setGroupPicks(parsedState.groupPicks ?? {});
      setBracketPicks(parsedState.bracketPicks ?? {});
    } catch {
      window.localStorage.removeItem(storageKey);
    }
  }, []);

  useEffect(() => {
    if (!hasMounted) {
      return;
    }

    const nextState: PersistedVisualState = {
      groupPicks,
      bracketPicks: sanitizeVisualBracketPicks(rounds, bracketPicks)
    };

    window.localStorage.setItem(storageKey, JSON.stringify(nextState));
  }, [bracketPicks, groupPicks, hasMounted, rounds]);

  function choose(groupLetter: string, position: VisualPickPosition, teamId: string) {
    setGroupPicks((current) => ({
      ...current,
      [groupLetter]: chooseVisualTeam(current[groupLetter] ?? {}, position, teamId)
    }));
    setBracketPicks({});
  }

  function randomizeGroup(group: VisualDemoGroup) {
    const [first, second, third] = shuffleTeams(group.teams);

    setGroupPicks((current) => ({
      ...current,
      [group.letter]: {
        first: first?.id,
        second: second?.id,
        third: third?.id
      }
    }));
    setBracketPicks({});
  }

  function randomizeAll() {
    setGroupPicks(
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
    setBracketPicks({});
  }

  function pickBracketWinner(matchId: string, teamId: string) {
    setBracketPicks((current) =>
      sanitizeVisualBracketPicks(rounds, {
        ...current,
        [matchId]: teamId
      })
    );
  }

  function reset() {
    setGroupPicks({});
    setBracketPicks({});
    setShareFeedback(null);
    window.localStorage.removeItem(storageKey);
  }

  async function share() {
    const text = champion
      ? `Minha campeã no Simulador da Copa 2026: ${champion.name}`
      : "Montei minha simulação da Copa 2026.";

    try {
      await navigator.clipboard.writeText(text);
      setShareFeedback("Resumo copiado.");
    } catch {
      setShareFeedback("Não foi possível copiar automaticamente.");
    }
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
            botões rápidos, classificados em tempo real e mata-mata interativo.
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
            onClick={share}
            type="button"
          >
            Compartilhar
          </button>
          {shareFeedback ? (
            <span className="shrink-0 rounded-full bg-slate-950 px-5 py-3 text-sm font-black text-white">
              {shareFeedback}
            </span>
          ) : null}
        </div>
      </div>

      <QualifiedStrip groups={groups} picks={groupPicks} />

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
              pick={groupPicks[group.letter] ?? {}}
            />
          ))}
        </div>
      </section>

      <InteractiveBracket
        bracketPicks={bracketPicks}
        champion={champion}
        onPick={pickBracketWinner}
        rounds={rounds}
      />
    </div>
  );
}
EOF

cat > tests/visual-bracket-helpers.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  buildVisualBracketRounds,
  buildVisualRoundOf32,
  getVisualChampion
} from "../lib/fifa/visualBracketHelpers.ts";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";
import type { VisualGroupPicks } from "../lib/fifa/visualDemoHelpers.ts";

function fullGroupPicks(): VisualGroupPicks {
  return Object.fromEntries(
    visualDemoGroups.map((group) => [
      group.letter,
      {
        first: `${group.letter}1`,
        second: `${group.letter}2`,
        third: `${group.letter}3`
      }
    ])
  );
}

describe("visual bracket helpers", () => {
  it("deve montar 16 confrontos iniciais", () => {
    expect(buildVisualRoundOf32(visualDemoGroups, fullGroupPicks())).toHaveLength(16);
  });

  it("deve propagar vencedores até a final", () => {
    const groupPicks = fullGroupPicks();
    let rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, {});
    const bracketPicks: Record<string, string> = {};

    for (const match of rounds.round32) {
      if (match.homeTeam) {
        bracketPicks[match.id] = match.homeTeam.id;
      }
    }

    rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

    expect(rounds.round16[0]?.homeTeam).not.toBeNull();
  });

  it("deve retornar campeão quando final estiver escolhida", () => {
    const groupPicks = fullGroupPicks();
    let rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, {});
    const bracketPicks: Record<string, string> = {};

    for (const roundKey of ["round32", "round16", "quarterFinals", "semiFinals", "final"] as const) {
      rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

      for (const match of rounds[roundKey]) {
        const winner = match.homeTeam ?? match.awayTeam;

        if (winner) {
          bracketPicks[match.id] = winner.id;
        }
      }
    }

    rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

    expect(getVisualChampion(rounds, bracketPicks)).not.toBeNull();
  });
});
EOF

cat > docs/visual-interactive-bracket.md <<'EOF'
# Bloco 19 — Mata-mata interativo

## Entrega

- Persistência local das escolhas no navegador.
- Classificados em uma faixa visual.
- Mata-mata interativo dos 16-avos até a final.
- Propagação automática dos vencedores.
- Campeão destacado no topo do bracket.
- Compartilhamento simples por clipboard.

## Observação

Este bloco ainda usa dados demo seguros. A integração com Prisma/dados oficiais virá no próximo bloco.
EOF

echo "==> Bloco 19 aplicado."
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
echo "  git commit -m \"feat: add interactive visual bracket\""
echo "  git push"
