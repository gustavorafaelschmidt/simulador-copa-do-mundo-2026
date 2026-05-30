import { prisma } from "../../lib/db/prisma.ts";
import {
  RANKING_JOB_STATUS,
  RANKING_TYPE
} from "../../lib/contracts/enums.ts";
import type { RankingSnapshotDTO } from "../../lib/contracts/ranking.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import {
  calculateIndividualScores,
  calculateTeamScores,
  type ParticipantScore
} from "../scoring/scoringService.ts";
import { toRankingSnapshotDTO } from "./rankingMapper.ts";

function sortScores(scores: ParticipantScore[]): ParticipantScore[] {
  return [...scores].sort((scoreA, scoreB) => {
    if (scoreB.score !== scoreA.score) {
      return scoreB.score - scoreA.score;
    }

    if (scoreB.correctPredictions !== scoreA.correctPredictions) {
      return scoreB.correctPredictions - scoreA.correctPredictions;
    }

    return scoreA.participantKey.localeCompare(scoreB.participantKey);
  });
}

function addRanks(scores: ParticipantScore[]) {
  return sortScores(scores).map((score, index) => ({
    ...score,
    rank: index + 1
  }));
}

async function calculateScoresByRankingType(type: keyof typeof RANKING_TYPE) {
  if (type === RANKING_TYPE.INDIVIDUAL) {
    return calculateIndividualScores();
  }

  return calculateTeamScores();
}

export async function recalculateRanking({
  type,
  requestedByUserId,
  idempotencyKey
}: {
  type: keyof typeof RANKING_TYPE;
  requestedByUserId?: string | null;
  idempotencyKey: string;
}): Promise<RankingSnapshotDTO> {
  const existingJob = await prisma.rankingRecalculationJob.findUnique({
    where: {
      idempotencyKey
    },
    include: {
      snapshots: {
        include: {
          entries: {
            orderBy: {
              rank: "asc"
            }
          }
        }
      }
    }
  });

  if (existingJob?.status === RANKING_JOB_STATUS.COMPLETED && existingJob.snapshots[0]) {
    return toRankingSnapshotDTO(existingJob.snapshots[0]);
  }

  if (existingJob && existingJob.status === RANKING_JOB_STATUS.RUNNING) {
    throw new AppError({
      code: "CONFLICT",
      message: "Este recálculo de ranking já está em execução.",
      statusCode: 409
    });
  }

  const job = await prisma.rankingRecalculationJob.upsert({
    where: {
      idempotencyKey
    },
    update: {
      status: RANKING_JOB_STATUS.RUNNING,
      startedAt: new Date(),
      finishedAt: null,
      errorMessage: null
    },
    create: {
      type,
      status: RANKING_JOB_STATUS.RUNNING,
      idempotencyKey,
      requestedByUserId: requestedByUserId ?? null,
      startedAt: new Date()
    }
  });

  try {
    const rankedScores = addRanks(await calculateScoresByRankingType(type));

    const snapshot = await prisma.$transaction(async (tx) => {
      const createdSnapshot = await tx.rankingSnapshot.create({
        data: {
          type,
          sourceJobId: job.id,
          metadata: {
            participantCount: rankedScores.length
          },
          entries: {
            create: rankedScores.map((score) => ({
              rankingType: type,
              userId: score.userId,
              teamId: score.teamId,
              participantKey: score.participantKey,
              rank: score.rank,
              score: score.score,
              correctPredictions: score.correctPredictions,
              totalPredictions: score.totalPredictions,
              metadata: score.metadata
            }))
          }
        },
        include: {
          entries: {
            orderBy: {
              rank: "asc"
            }
          }
        }
      });

      await tx.rankingRecalculationJob.update({
        where: {
          id: job.id
        },
        data: {
          status: RANKING_JOB_STATUS.COMPLETED,
          finishedAt: new Date()
        }
      });

      return createdSnapshot;
    });

    return toRankingSnapshotDTO(snapshot);
  } catch (error) {
    await prisma.rankingRecalculationJob.update({
      where: {
        id: job.id
      },
      data: {
        status: RANKING_JOB_STATUS.FAILED,
        finishedAt: new Date(),
        errorMessage: error instanceof Error ? error.message : "Erro desconhecido."
      }
    });

    throw error;
  }
}

export async function getLatestRankingSnapshot(
  type: keyof typeof RANKING_TYPE,
  limit = 100
): Promise<RankingSnapshotDTO | null> {
  const snapshot = await prisma.rankingSnapshot.findFirst({
    where: {
      type
    },
    include: {
      entries: {
        orderBy: {
          rank: "asc"
        },
        take: limit
      }
    },
    orderBy: {
      calculatedAt: "desc"
    }
  });

  return snapshot ? toRankingSnapshotDTO(snapshot) : null;
}
