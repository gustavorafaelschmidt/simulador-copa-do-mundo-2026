import type { RankingJobStatus, RankingType } from "./enums.ts";
import type { TeamId } from "./team.ts";
import type { UserId } from "./user.ts";

export type RankingSnapshotId = string;

export type RankingEntryDTO = {
  id: string;
  snapshotId: RankingSnapshotId;
  rankingType: RankingType;
  userId: UserId | null;
  teamId: TeamId | null;
  participantKey: string;
  rank: number;
  score: number;
  correctPredictions: number;
  totalPredictions: number;
  metadata: unknown | null;
};

export type RankingSnapshotDTO = {
  id: RankingSnapshotId;
  type: RankingType;
  calculatedAt: string;
  sourceJobId: string | null;
  metadata: unknown | null;
  entries: RankingEntryDTO[];
};

export type RankingRecalculationJobDTO = {
  id: string;
  type: RankingType;
  status: RankingJobStatus;
  idempotencyKey: string;
  requestedByUserId: UserId | null;
  startedAt: string | null;
  finishedAt: string | null;
  errorMessage: string | null;
  metadata: unknown | null;
};

export type RequestRankingRecalculationInputDTO = {
  type: RankingType;
  idempotencyKey: string;
};
