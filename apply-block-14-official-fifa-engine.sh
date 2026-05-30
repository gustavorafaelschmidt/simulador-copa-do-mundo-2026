#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 14 — Motor FIFA oficial: classificação, melhores terceiros e 16-avos..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p lib/fifa
mkdir -p docs
mkdir -p tests

cat > lib/fifa/discipline.ts <<'EOF'
export type TeamDisciplinaryRecord = {
  yellowCards: number;
  indirectRedCards: number;
  directRedCards: number;
  yellowAndDirectRedCards: number;
};

/*
  FWC26 Regulations, Article 13:
  - yellow card: minus 1 point
  - indirect red card: minus 3 points
  - direct red card: minus 4 points
  - yellow card and direct red card: minus 5 points

  Quanto maior o score final, melhor o team conduct.
*/
export function calculateTeamConductScore(record: TeamDisciplinaryRecord): number {
  return (
    record.yellowCards * -1 +
    record.indirectRedCards * -3 +
    record.directRedCards * -4 +
    record.yellowAndDirectRedCards * -5
  );
}
EOF

cat > lib/fifa/standingsTypes.ts <<'EOF'
import type { GroupLetter } from "../contracts/enums.ts";

export type FifaTeamStandingInput = {
  teamId: string;
  group: GroupLetter;
  fifaRankingPosition: number;
  previousFifaRankingPositions?: number[];
  teamConductScore: number;
};

export type FifaGroupMatchResult = {
  group: GroupLetter;
  homeTeamId: string;
  awayTeamId: string;
  homeGoals: number;
  awayGoals: number;
};

export type FifaTeamStanding = FifaTeamStandingInput & {
  played: number;
  wins: number;
  draws: number;
  losses: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
  points: number;
  rank: number;
};

export type QualifiedTeamsResult = {
  groupWinners: FifaTeamStanding[];
  groupRunnersUp: FifaTeamStanding[];
  thirdPlacedTeams: FifaTeamStanding[];
  bestThirdPlacedTeams: FifaTeamStanding[];
  qualifiedTeams: FifaTeamStanding[];
};
EOF

cat > lib/fifa/groupStandings.ts <<'EOF'
import { AppError } from "../errors/AppError.ts";
import type {
  FifaGroupMatchResult,
  FifaTeamStanding,
  FifaTeamStandingInput,
  QualifiedTeamsResult
} from "./standingsTypes.ts";

function createInitialStanding(team: FifaTeamStandingInput): FifaTeamStanding {
  return {
    ...team,
    played: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    goalsFor: 0,
    goalsAgainst: 0,
    goalDifference: 0,
    points: 0,
    rank: 0
  };
}

function applyMatchToStanding(
  standing: FifaTeamStanding,
  goalsFor: number,
  goalsAgainst: number
): FifaTeamStanding {
  const isWin = goalsFor > goalsAgainst;
  const isDraw = goalsFor === goalsAgainst;

  const wins = standing.wins + (isWin ? 1 : 0);
  const draws = standing.draws + (isDraw ? 1 : 0);
  const losses = standing.losses + (!isWin && !isDraw ? 1 : 0);
  const totalGoalsFor = standing.goalsFor + goalsFor;
  const totalGoalsAgainst = standing.goalsAgainst + goalsAgainst;

  return {
    ...standing,
    played: standing.played + 1,
    wins,
    draws,
    losses,
    goalsFor: totalGoalsFor,
    goalsAgainst: totalGoalsAgainst,
    goalDifference: totalGoalsFor - totalGoalsAgainst,
    points: standing.points + (isWin ? 3 : isDraw ? 1 : 0)
  };
}

function comparePreviousRankings(
  teamA: FifaTeamStanding,
  teamB: FifaTeamStanding
): number {
  const maxLength = Math.max(
    teamA.previousFifaRankingPositions?.length ?? 0,
    teamB.previousFifaRankingPositions?.length ?? 0
  );

  for (let index = 0; index < maxLength; index += 1) {
    const rankingA = teamA.previousFifaRankingPositions?.[index] ?? Number.POSITIVE_INFINITY;
    const rankingB = teamB.previousFifaRankingPositions?.[index] ?? Number.POSITIVE_INFINITY;

    if (rankingA !== rankingB) {
      return rankingA - rankingB;
    }
  }

  return teamA.teamId.localeCompare(teamB.teamId);
}

function buildHeadToHeadStanding(
  team: FifaTeamStanding,
  tiedTeamIds: Set<string>,
  matches: FifaGroupMatchResult[]
): FifaTeamStanding {
  const base = createInitialStanding(team);

  return matches
    .filter(
      (match) => tiedTeamIds.has(match.homeTeamId) && tiedTeamIds.has(match.awayTeamId)
    )
    .reduce((standing, match) => {
      if (match.homeTeamId === team.teamId) {
        return applyMatchToStanding(standing, match.homeGoals, match.awayGoals);
      }

      if (match.awayTeamId === team.teamId) {
        return applyMatchToStanding(standing, match.awayGoals, match.homeGoals);
      }

      return standing;
    }, base);
}

function compareHeadToHead(
  teamA: FifaTeamStanding,
  teamB: FifaTeamStanding,
  allTeams: FifaTeamStanding[],
  matches: FifaGroupMatchResult[]
): number {
  const tiedTeamIds = new Set(
    allTeams
      .filter(
        (team) =>
          team.points === teamA.points &&
          team.goalDifference === teamA.goalDifference &&
          team.goalsFor === teamA.goalsFor
      )
      .map((team) => team.teamId)
  );

  if (tiedTeamIds.size < 2) {
    return 0;
  }

  const headToHeadA = buildHeadToHeadStanding(teamA, tiedTeamIds, matches);
  const headToHeadB = buildHeadToHeadStanding(teamB, tiedTeamIds, matches);

  return (
    headToHeadB.points - headToHeadA.points ||
    headToHeadB.goalDifference - headToHeadA.goalDifference ||
    headToHeadB.goalsFor - headToHeadA.goalsFor
  );
}

export function buildGroupStandings(
  teams: FifaTeamStandingInput[],
  matches: FifaGroupMatchResult[]
): FifaTeamStanding[] {
  if (teams.length !== 4) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Cada grupo FIFA precisa ter exatamente quatro seleções.",
      statusCode: 422
    });
  }

  const group = teams[0]?.group;

  if (!group || teams.some((team) => team.group !== group)) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as seleções devem pertencer ao mesmo grupo.",
      statusCode: 422
    });
  }

  const teamIds = new Set(teams.map((team) => team.teamId));

  for (const match of matches) {
    if (match.group !== group) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Todas as partidas devem pertencer ao mesmo grupo.",
        statusCode: 422
      });
    }

    if (!teamIds.has(match.homeTeamId) || !teamIds.has(match.awayTeamId)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Partida possui seleção fora do grupo.",
        statusCode: 422
      });
    }
  }

  const standingsByTeamId = new Map(
    teams.map((team) => [team.teamId, createInitialStanding(team)])
  );

  for (const match of matches) {
    const homeStanding = standingsByTeamId.get(match.homeTeamId);
    const awayStanding = standingsByTeamId.get(match.awayTeamId);

    if (!homeStanding || !awayStanding) {
      continue;
    }

    standingsByTeamId.set(
      match.homeTeamId,
      applyMatchToStanding(homeStanding, match.homeGoals, match.awayGoals)
    );
    standingsByTeamId.set(
      match.awayTeamId,
      applyMatchToStanding(awayStanding, match.awayGoals, match.homeGoals)
    );
  }

  return [...standingsByTeamId.values()];
}

export function rankGroupStandings(
  standings: FifaTeamStanding[],
  matches: FifaGroupMatchResult[]
): FifaTeamStanding[] {
  const ranked = [...standings].sort(
    (teamA, teamB) =>
      teamB.points - teamA.points ||
      teamB.goalDifference - teamA.goalDifference ||
      teamB.goalsFor - teamA.goalsFor ||
      compareHeadToHead(teamA, teamB, standings, matches) ||
      teamB.teamConductScore - teamA.teamConductScore ||
      teamA.fifaRankingPosition - teamB.fifaRankingPosition ||
      comparePreviousRankings(teamA, teamB)
  );

  return ranked.map((team, index) => ({
    ...team,
    rank: index + 1
  }));
}

export function rankThirdPlacedTeams(thirdPlacedTeams: FifaTeamStanding[]): FifaTeamStanding[] {
  return [...thirdPlacedTeams].sort(
    (teamA, teamB) =>
      teamB.points - teamA.points ||
      teamB.goalDifference - teamA.goalDifference ||
      teamB.goalsFor - teamA.goalsFor ||
      teamB.teamConductScore - teamA.teamConductScore ||
      teamA.fifaRankingPosition - teamB.fifaRankingPosition ||
      comparePreviousRankings(teamA, teamB)
  );
}

export function selectQualifiedTeamsFromRankedGroups(
  rankedGroups: FifaTeamStanding[][]
): QualifiedTeamsResult {
  if (rankedGroups.length !== 12) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "A fase de grupos da Copa 2026 precisa conter 12 grupos.",
      statusCode: 422
    });
  }

  const groupWinners = rankedGroups.map((group) => group[0]).filter(Boolean);
  const groupRunnersUp = rankedGroups.map((group) => group[1]).filter(Boolean);
  const thirdPlacedTeams = rankedGroups.map((group) => group[2]).filter(Boolean);
  const bestThirdPlacedTeams = rankThirdPlacedTeams(thirdPlacedTeams).slice(0, 8);
  const qualifiedTeams = [...groupWinners, ...groupRunnersUp, ...bestThirdPlacedTeams];

  return {
    groupWinners,
    groupRunnersUp,
    thirdPlacedTeams,
    bestThirdPlacedTeams,
    qualifiedTeams
  };
}
EOF

cat > lib/fifa/roundOf32.ts <<'EOF'
import { AppError } from "../errors/AppError.ts";
import type { GroupLetter } from "../contracts/enums.ts";

export type RoundOf32FixedSlot = {
  matchCode: string;
  order: number;
  teamA: string;
  teamB: string;
  allowedThirdGroups?: GroupLetter[];
};

/*
  FWC26 Regulations, Article 12.6.
  Os confrontos que dependem dos terceiros devem ser resolvidos com Annexe C.
*/
export const ROUND_OF_32_FIXED_SLOTS: RoundOf32FixedSlot[] = [
  { matchCode: "M73", order: 1, teamA: "2A", teamB: "2B" },
  { matchCode: "M74", order: 2, teamA: "1E", teamB: "BEST_3RD_ABCDF", allowedThirdGroups: ["A", "B", "C", "D", "F"] },
  { matchCode: "M75", order: 3, teamA: "1F", teamB: "2C" },
  { matchCode: "M76", order: 4, teamA: "1C", teamB: "2F" },
  { matchCode: "M77", order: 5, teamA: "1I", teamB: "BEST_3RD_CDFGH", allowedThirdGroups: ["C", "D", "F", "G", "H"] },
  { matchCode: "M78", order: 6, teamA: "2E", teamB: "2I" },
  { matchCode: "M79", order: 7, teamA: "1A", teamB: "BEST_3RD_CEFHI", allowedThirdGroups: ["C", "E", "F", "H", "I"] },
  { matchCode: "M80", order: 8, teamA: "1L", teamB: "BEST_3RD_EHIJK", allowedThirdGroups: ["E", "H", "I", "J", "K"] },
  { matchCode: "M81", order: 9, teamA: "1D", teamB: "BEST_3RD_BEFIJ", allowedThirdGroups: ["B", "E", "F", "I", "J"] },
  { matchCode: "M82", order: 10, teamA: "1G", teamB: "BEST_3RD_AEHIJ", allowedThirdGroups: ["A", "E", "H", "I", "J"] },
  { matchCode: "M83", order: 11, teamA: "2K", teamB: "2L" },
  { matchCode: "M84", order: 12, teamA: "1H", teamB: "2J" },
  { matchCode: "M85", order: 13, teamA: "1B", teamB: "BEST_3RD_EFGIJ", allowedThirdGroups: ["E", "F", "G", "I", "J"] },
  { matchCode: "M86", order: 14, teamA: "1J", teamB: "2H" },
  { matchCode: "M87", order: 15, teamA: "1K", teamB: "BEST_3RD_DEIJL", allowedThirdGroups: ["D", "E", "I", "J", "L"] },
  { matchCode: "M88", order: 16, teamA: "2D", teamB: "2G" }
];

export type ThirdPlaceMatrixAssignment = {
  slotCode: string;
  thirdGroup: GroupLetter;
};

export type ThirdPlaceMatrixRule = {
  combinationKey: string;
  assignments: ThirdPlaceMatrixAssignment[];
};

export function buildThirdPlaceCombinationKey(groups: GroupLetter[]): string {
  return [...groups].sort().join("");
}

export function validateThirdPlaceMatrixRule(rule: ThirdPlaceMatrixRule): void {
  const combinationGroups = buildThirdPlaceCombinationKey(
    rule.combinationKey.split("") as GroupLetter[]
  );

  if (combinationGroups !== rule.combinationKey) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Chave de combinação de terceiros precisa estar ordenada.",
      statusCode: 422
    });
  }

  if (rule.assignments.length !== 8) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Regra da matriz de terceiros precisa possuir oito atribuições.",
      statusCode: 422
    });
  }

  const assignedGroups = new Set(rule.assignments.map((assignment) => assignment.thirdGroup));

  if (assignedGroups.size !== 8) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Regra da matriz de terceiros não pode repetir grupos.",
      statusCode: 422
    });
  }

  const allowedSlotCodes = new Set(
    ROUND_OF_32_FIXED_SLOTS
      .filter((slot) => slot.allowedThirdGroups)
      .map((slot) => slot.teamB)
  );

  for (const assignment of rule.assignments) {
    if (!allowedSlotCodes.has(assignment.slotCode)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Regra da matriz aponta para slot inexistente de terceiro colocado.",
        statusCode: 422,
        details: assignment
      });
    }

    const fixedSlot = ROUND_OF_32_FIXED_SLOTS.find((slot) => slot.teamB === assignment.slotCode);

    if (!fixedSlot?.allowedThirdGroups?.includes(assignment.thirdGroup)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Grupo terceiro atribuído a slot onde ele não é permitido pelo Artigo 12.6.",
        statusCode: 422,
        details: assignment
      });
    }
  }
}

export function resolveThirdPlaceAssignments(
  bestThirdGroups: GroupLetter[],
  rules: ThirdPlaceMatrixRule[]
): ThirdPlaceMatrixAssignment[] {
  const combinationKey = buildThirdPlaceCombinationKey(bestThirdGroups);
  const rule = rules.find((candidate) => candidate.combinationKey === combinationKey);

  if (!rule) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message:
        "Combinação oficial da matriz de terceiros não encontrada. Carregue Annexe C completo antes de resolver os 16-avos.",
      statusCode: 500,
      details: {
        combinationKey
      }
    });
  }

  validateThirdPlaceMatrixRule(rule);

  return rule.assignments;
}
EOF

node <<'NODE'
const fs = require("node:fs");

const indexPath = "lib/fifa/index.ts";
let source = fs.existsSync(indexPath) ? fs.readFileSync(indexPath, "utf8") : "";

for (const line of [
  'export * from "./discipline.ts";',
  'export * from "./standingsTypes.ts";',
  'export * from "./groupStandings.ts";',
  'export * from "./roundOf32.ts";'
]) {
  if (!source.includes(line)) {
    source += `\n${line}`;
  }
}

fs.writeFileSync(indexPath, `${source.trim()}\n`);
NODE

cat > docs/fifa-official-engine.md <<'EOF'
# Bloco 14 — Motor FIFA oficial

## Fonte

Este bloco implementa regras baseadas no regulamento oficial `FWC26_regulations_EN.pdf`.

## Implementado

- Cálculo de team conduct score:
  - amarelo: -1;
  - vermelho indireto: -3;
  - vermelho direto: -4;
  - amarelo + vermelho direto: -5.
- Classificação de grupos com:
  - pontos;
  - saldo;
  - gols pró;
  - confronto direto para times ainda empatados;
  - team conduct;
  - ranking FIFA atual;
  - rankings FIFA anteriores.
- Seleção dos classificados:
  - 1º e 2º de cada um dos 12 grupos;
  - 8 melhores terceiros.
- Ordenação dos terceiros por:
  - pontos;
  - saldo;
  - gols pró;
  - team conduct;
  - ranking FIFA atual;
  - rankings FIFA anteriores.
- Estrutura dos 16-avos conforme Artigo 12.6.
- Guard para matriz oficial Annexe C.

## Não implementado ainda

O Annexe C possui 495 combinações. Este bloco não inventa a matriz completa.

A função `resolveThirdPlaceAssignments` exige que regras oficiais sejam carregadas em dados versionados. Sem isso, ela bloqueia a resolução do chaveamento dependente dos terceiros.
EOF

cat > tests/fifa-official-engine.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { AppError } from "../lib/errors/AppError.ts";
import { calculateTeamConductScore } from "../lib/fifa/discipline.ts";
import {
  buildGroupStandings,
  rankGroupStandings,
  rankThirdPlacedTeams,
  selectQualifiedTeamsFromRankedGroups
} from "../lib/fifa/groupStandings.ts";
import {
  buildThirdPlaceCombinationKey,
  resolveThirdPlaceAssignments,
  ROUND_OF_32_FIXED_SLOTS,
  validateThirdPlaceMatrixRule
} from "../lib/fifa/roundOf32.ts";
import type { FifaTeamStandingInput } from "../lib/fifa/standingsTypes.ts";

function buildTeams(group: "A"): FifaTeamStandingInput[] {
  return [
    {
      teamId: "A1",
      group,
      fifaRankingPosition: 1,
      teamConductScore: 0
    },
    {
      teamId: "A2",
      group,
      fifaRankingPosition: 2,
      teamConductScore: -1
    },
    {
      teamId: "A3",
      group,
      fifaRankingPosition: 3,
      teamConductScore: -2
    },
    {
      teamId: "A4",
      group,
      fifaRankingPosition: 4,
      teamConductScore: -3
    }
  ];
}

describe("fifa official engine", () => {
  it("deve calcular team conduct score", () => {
    expect(
      calculateTeamConductScore({
        yellowCards: 2,
        indirectRedCards: 1,
        directRedCards: 1,
        yellowAndDirectRedCards: 1
      })
    ).toBe(-14);
  });

  it("deve montar e ordenar classificação de grupo por pontos", () => {
    const teams = buildTeams("A");
    const matches = [
      {
        group: "A" as const,
        homeTeamId: "A1",
        awayTeamId: "A2",
        homeGoals: 2,
        awayGoals: 0
      },
      {
        group: "A" as const,
        homeTeamId: "A3",
        awayTeamId: "A4",
        homeGoals: 1,
        awayGoals: 1
      },
      {
        group: "A" as const,
        homeTeamId: "A1",
        awayTeamId: "A3",
        homeGoals: 3,
        awayGoals: 1
      },
      {
        group: "A" as const,
        homeTeamId: "A2",
        awayTeamId: "A4",
        homeGoals: 1,
        awayGoals: 0
      }
    ];

    const standings = buildGroupStandings(teams, matches);
    const ranked = rankGroupStandings(standings, matches);

    expect(ranked[0]?.teamId).toBe("A1");
    expect(ranked[0]?.points).toBe(6);
  });

  it("deve ordenar melhores terceiros por critérios oficiais principais", () => {
    const rankedThirds = rankThirdPlacedTeams([
      {
        ...buildTeams("A")[0]!,
        rank: 3,
        played: 3,
        wins: 1,
        draws: 0,
        losses: 2,
        goalsFor: 2,
        goalsAgainst: 4,
        goalDifference: -2,
        points: 3
      },
      {
        ...buildTeams("A")[1]!,
        teamId: "B3",
        group: "B",
        rank: 3,
        played: 3,
        wins: 1,
        draws: 1,
        losses: 1,
        goalsFor: 3,
        goalsAgainst: 3,
        goalDifference: 0,
        points: 4
      }
    ]);

    expect(rankedThirds[0]?.teamId).toBe("B3");
  });

  it("deve selecionar 32 classificados de 12 grupos", () => {
    const rankedGroups = Array.from({ length: 12 }, (_, index) => {
      const group = String.fromCharCode(65 + index) as "A";
      return [0, 1, 2, 3].map((position) => ({
        teamId: `${group}${position + 1}`,
        group,
        fifaRankingPosition: position + 1,
        teamConductScore: 0,
        played: 3,
        wins: position === 0 ? 3 : 0,
        draws: 0,
        losses: position,
        goalsFor: 5 - position,
        goalsAgainst: position,
        goalDifference: 5 - position * 2,
        points: 9 - position,
        rank: position + 1
      }));
    });

    expect(selectQualifiedTeamsFromRankedGroups(rankedGroups).qualifiedTeams).toHaveLength(32);
  });

  it("deve expor os 16 slots dos 16-avos", () => {
    expect(ROUND_OF_32_FIXED_SLOTS).toHaveLength(16);
    expect(ROUND_OF_32_FIXED_SLOTS[0]).toMatchObject({
      matchCode: "M73",
      teamA: "2A",
      teamB: "2B"
    });
  });

  it("deve montar chave ordenada da combinação de terceiros", () => {
    expect(buildThirdPlaceCombinationKey(["L", "A", "C", "B", "D", "E", "F", "G"])).toBe(
      "ABCDEFGL"
    );
  });

  it("deve validar regra de matriz coerente com slots permitidos", () => {
    expect(() =>
      validateThirdPlaceMatrixRule({
        combinationKey: "ABCDEFGH",
        assignments: [
          { slotCode: "BEST_3RD_ABCDF", thirdGroup: "A" },
          { slotCode: "BEST_3RD_CDFGH", thirdGroup: "C" },
          { slotCode: "BEST_3RD_CEFHI", thirdGroup: "F" },
          { slotCode: "BEST_3RD_EHIJK", thirdGroup: "E" },
          { slotCode: "BEST_3RD_BEFIJ", thirdGroup: "B" },
          { slotCode: "BEST_3RD_AEHIJ", thirdGroup: "H" },
          { slotCode: "BEST_3RD_EFGIJ", thirdGroup: "G" },
          { slotCode: "BEST_3RD_DEIJL", thirdGroup: "D" }
        ]
      })
    ).not.toThrow();
  });

  it("deve bloquear matriz ausente", () => {
    expect(() => resolveThirdPlaceAssignments(["A", "B", "C", "D", "E", "F", "G", "H"], [])).toThrow(
      AppError
    );
  });
});
EOF

echo "==> Bloco 14 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add official fifa rules engine\""
echo "  git push"
