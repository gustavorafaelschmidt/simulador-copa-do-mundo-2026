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
