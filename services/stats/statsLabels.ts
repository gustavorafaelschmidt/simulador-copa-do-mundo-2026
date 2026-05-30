import type { RankingType } from "../../lib/contracts/enums.ts";

export function buildRankingStatsLabel(type: RankingType): string {
  return type === "INDIVIDUAL" ? "Ranking individual" : "Ranking por equipes";
}
