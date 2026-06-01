import { prisma } from "../../lib/db/prisma.ts";
import type { RankingType } from "../../lib/contracts/enums.ts";
import {
  buildGlobalStatsPayload,
  type GlobalStatsPayload
} from "./globalStatsCalculator.ts";

export type GlobalStatSnapshotDTO = {
  id: string;
  calculatedAt: string;
  payload: GlobalStatsPayload;
};

function toGlobalStatSnapshotDTO(snapshot: {
  id: string;
  calculatedAt: Date;
  payload: unknown;
}): GlobalStatSnapshotDTO {
  return {
    id: snapshot.id,
    calculatedAt: snapshot.calculatedAt.toISOString(),
    payload: snapshot.payload as GlobalStatsPayload
  };
}

export async function calculateGlobalStatsPayload(): Promise<GlobalStatsPayload> {
  const [
    usersCount,
    teamsCount,
    individualGroupPredictionsCount,
    individualKnockoutPredictionsCount,
    teamGroupConsensusCount,
    teamKnockoutConsensusCount,
    realResultsCount,
    rankingSnapshotsCount
  ] = await Promise.all([
    prisma.user.count(),
    prisma.team.count(),
    prisma.individualGroupPrediction.count(),
    prisma.individualKnockoutPrediction.count(),
    prisma.teamGroupConsensus.count(),
    prisma.teamKnockoutConsensus.count(),
    prisma.realTournamentResult.count(),
    prisma.rankingSnapshot.count()
  ]);

  return buildGlobalStatsPayload({
    usersCount,
    teamsCount,
    individualPredictionsCount:
      individualGroupPredictionsCount + individualKnockoutPredictionsCount,
    teamConsensusCount: teamGroupConsensusCount + teamKnockoutConsensusCount,
    realResultsCount,
    rankingSnapshotsCount
  });
}

export async function createGlobalStatSnapshot(): Promise<GlobalStatSnapshotDTO> {
  const payload = await calculateGlobalStatsPayload();

  const snapshot = await prisma.globalStatSnapshot.create({
    data: {
      payload
    }
  });

  return toGlobalStatSnapshotDTO(snapshot);
}

export async function getLatestGlobalStatSnapshot(): Promise<GlobalStatSnapshotDTO | null> {
  const snapshot = await prisma.globalStatSnapshot.findFirst({
    orderBy: {
      calculatedAt: "desc"
    }
  });

  return snapshot ? toGlobalStatSnapshotDTO(snapshot) : null;
}

export function buildRankingStatsLabel(type: RankingType): string {
  return type === "INDIVIDUAL" ? "Ranking individual" : "Ranking por equipes";
}
