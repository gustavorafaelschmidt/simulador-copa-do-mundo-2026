import type { RankingEntryDTO, RankingSnapshotDTO } from "../../lib/contracts/ranking.ts";

type RankingEntryRecord = {
  id: string;
  snapshotId: string;
  rankingType: RankingEntryDTO["rankingType"];
  userId: string | null;
  teamId: string | null;
  participantKey: string;
  rank: number;
  score: number;
  correctPredictions: number;
  totalPredictions: number;
  metadata: unknown | null;
};

type RankingSnapshotRecord = {
  id: string;
  type: RankingSnapshotDTO["type"];
  calculatedAt: Date;
  sourceJobId: string | null;
  metadata: unknown | null;
  entries?: RankingEntryRecord[];
};

export function toRankingEntryDTO(entry: RankingEntryRecord): RankingEntryDTO {
  return {
    id: entry.id,
    snapshotId: entry.snapshotId,
    rankingType: entry.rankingType,
    userId: entry.userId,
    teamId: entry.teamId,
    participantKey: entry.participantKey,
    rank: entry.rank,
    score: entry.score,
    correctPredictions: entry.correctPredictions,
    totalPredictions: entry.totalPredictions,
    metadata: entry.metadata
  };
}

export function toRankingSnapshotDTO(snapshot: RankingSnapshotRecord): RankingSnapshotDTO {
  return {
    id: snapshot.id,
    type: snapshot.type,
    calculatedAt: snapshot.calculatedAt.toISOString(),
    sourceJobId: snapshot.sourceJobId,
    metadata: snapshot.metadata,
    entries: snapshot.entries?.map(toRankingEntryDTO) ?? []
  };
}
