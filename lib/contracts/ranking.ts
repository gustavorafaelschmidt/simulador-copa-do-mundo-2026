import type { RankingJobStatus, RankingType } from "@/lib/contracts/enums";
import type { TeamId } from "@/lib/contracts/team";
import type { UserId } from "@/lib/contracts/user";

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
