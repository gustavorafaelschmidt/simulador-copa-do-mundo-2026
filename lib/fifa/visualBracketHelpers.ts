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
