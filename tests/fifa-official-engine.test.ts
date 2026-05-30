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
