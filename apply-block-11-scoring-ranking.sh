#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 11 — pontuação, rankings e recálculo idempotente..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/scoring
mkdir -p services/ranking
mkdir -p actions
mkdir -p components/ranking
mkdir -p app/ranking/individual
mkdir -p app/ranking/equipes
mkdir -p docs
mkdir -p tests

cat > services/scoring/scoringRules.ts <<'EOF'
export const SCORING_RULES = {
  GROUP_EXACT_FIRST_PLACE: 10,
  GROUP_EXACT_SECOND_PLACE: 10,
  GROUP_EXACT_THIRD_PLACE: 8,
  GROUP_EXACT_FOURTH_PLACE: 5,
  GROUP_QUALIFIED_TEAM_ANY_POSITION: 3,
  KNOCKOUT_EXACT_WINNER: 15
} as const;

export type ScoreBreakdownItem = {
  code: keyof typeof SCORING_RULES;
  points: number;
  description: string;
};

export type ScoreBreakdown = {
  totalScore: number;
  correctPredictions: number;
  totalPredictions: number;
  items: ScoreBreakdownItem[];
};
EOF

cat > services/scoring/resultPayloads.ts <<'EOF'
import { z } from "zod";

export const groupStandingResultPayloadSchema = z.object({
  orderedTeamIds: z.array(z.string().min(1)).length(4)
});

export const knockoutMatchResultPayloadSchema = z.object({
  winnerTeamId: z.string().min(1)
});

export type GroupStandingResultPayload = z.infer<typeof groupStandingResultPayloadSchema>;
export type KnockoutMatchResultPayload = z.infer<typeof knockoutMatchResultPayloadSchema>;
EOF

cat > services/scoring/scoringCalculator.ts <<'EOF'
import { SCORING_RULES, type ScoreBreakdown } from "./scoringRules.ts";

export type GroupPredictionForScoring = {
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
  fourthPlaceTeamId: string;
};

export type KnockoutPredictionForScoring = {
  winnerTeamId: string;
};

export function scoreGroupPrediction(
  prediction: GroupPredictionForScoring,
  realOrderedTeamIds: string[]
): ScoreBreakdown {
  const [realFirst, realSecond, realThird, realFourth] = realOrderedTeamIds;
  const items: ScoreBreakdown["items"] = [];
  let correctPredictions = 0;

  if (prediction.firstPlaceTeamId === realFirst) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_FIRST_PLACE",
      points: SCORING_RULES.GROUP_EXACT_FIRST_PLACE,
      description: "Acertou o 1º colocado do grupo."
    });
  }

  if (prediction.secondPlaceTeamId === realSecond) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_SECOND_PLACE",
      points: SCORING_RULES.GROUP_EXACT_SECOND_PLACE,
      description: "Acertou o 2º colocado do grupo."
    });
  }

  if (prediction.thirdPlaceTeamId === realThird) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_THIRD_PLACE",
      points: SCORING_RULES.GROUP_EXACT_THIRD_PLACE,
      description: "Acertou o 3º colocado do grupo."
    });
  }

  if (prediction.fourthPlaceTeamId === realFourth) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_FOURTH_PLACE",
      points: SCORING_RULES.GROUP_EXACT_FOURTH_PLACE,
      description: "Acertou o 4º colocado do grupo."
    });
  }

  const realQualifiedTeamIds = new Set(realOrderedTeamIds.slice(0, 3));
  const predictedQualifiedTeamIds = [
    prediction.firstPlaceTeamId,
    prediction.secondPlaceTeamId,
    prediction.thirdPlaceTeamId
  ];

  for (const predictedTeamId of predictedQualifiedTeamIds) {
    if (
      realQualifiedTeamIds.has(predictedTeamId) &&
      predictedTeamId !== realFirst &&
      predictedTeamId !== realSecond &&
      predictedTeamId !== realThird
    ) {
      items.push({
        code: "GROUP_QUALIFIED_TEAM_ANY_POSITION",
        points: SCORING_RULES.GROUP_QUALIFIED_TEAM_ANY_POSITION,
        description: "Acertou seleção classificada em posição diferente."
      });
    }
  }

  const totalScore = items.reduce((sum, item) => sum + item.points, 0);

  return {
    totalScore,
    correctPredictions,
    totalPredictions: 4,
    items
  };
}

export function scoreKnockoutPrediction(
  prediction: KnockoutPredictionForScoring,
  realWinnerTeamId: string
): ScoreBreakdown {
  if (prediction.winnerTeamId !== realWinnerTeamId) {
    return {
      totalScore: 0,
      correctPredictions: 0,
      totalPredictions: 1,
      items: []
    };
  }

  return {
    totalScore: SCORING_RULES.KNOCKOUT_EXACT_WINNER,
    correctPredictions: 1,
    totalPredictions: 1,
    items: [
      {
        code: "KNOCKOUT_EXACT_WINNER",
        points: SCORING_RULES.KNOCKOUT_EXACT_WINNER,
        description: "Acertou o vencedor do confronto."
      }
    ]
  };
}

export function mergeScoreBreakdowns(breakdowns: ScoreBreakdown[]): ScoreBreakdown {
  return breakdowns.reduce<ScoreBreakdown>(
    (accumulator, breakdown) => ({
      totalScore: accumulator.totalScore + breakdown.totalScore,
      correctPredictions: accumulator.correctPredictions + breakdown.correctPredictions,
      totalPredictions: accumulator.totalPredictions + breakdown.totalPredictions,
      items: [...accumulator.items, ...breakdown.items]
    }),
    {
      totalScore: 0,
      correctPredictions: 0,
      totalPredictions: 0,
      items: []
    }
  );
}
EOF

cat > services/scoring/scoringService.ts <<'EOF'
import { prisma } from "../../lib/db/prisma.ts";
import { REAL_RESULT_TYPE } from "../../lib/contracts/enums.ts";
import {
  groupStandingResultPayloadSchema,
  knockoutMatchResultPayloadSchema
} from "./resultPayloads.ts";
import {
  mergeScoreBreakdowns,
  scoreGroupPrediction,
  scoreKnockoutPrediction
} from "./scoringCalculator.ts";
import type { ScoreBreakdown } from "./scoringRules.ts";

export type ParticipantScore = {
  participantKey: string;
  userId: string | null;
  teamId: string | null;
  score: number;
  correctPredictions: number;
  totalPredictions: number;
  metadata: ScoreBreakdown;
};

export async function calculateIndividualScores(): Promise<ParticipantScore[]> {
  const [groupPredictions, knockoutPredictions, realResults] = await Promise.all([
    prisma.individualGroupPrediction.findMany(),
    prisma.individualKnockoutPrediction.findMany(),
    prisma.realTournamentResult.findMany()
  ]);

  const realGroupResultsByGroup = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.GROUP_STANDING && result.group)
      .map((result) => [result.group, groupStandingResultPayloadSchema.safeParse(result.payload)])
  );

  const realKnockoutResultsBySlot = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && result.bracketSlotId)
      .map((result) => [
        result.bracketSlotId,
        knockoutMatchResultPayloadSchema.safeParse(result.payload)
      ])
  );

  const breakdownsByUserId = new Map<string, ScoreBreakdown[]>();

  for (const prediction of groupPredictions) {
    const realResult = realGroupResultsByGroup.get(prediction.group);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreGroupPrediction(prediction, realResult.data.orderedTeamIds);
    const existingBreakdowns = breakdownsByUserId.get(prediction.userId) ?? [];

    breakdownsByUserId.set(prediction.userId, [...existingBreakdowns, breakdown]);
  }

  for (const prediction of knockoutPredictions) {
    const realResult = realKnockoutResultsBySlot.get(prediction.bracketSlotId);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreKnockoutPrediction(prediction, realResult.data.winnerTeamId);
    const existingBreakdowns = breakdownsByUserId.get(prediction.userId) ?? [];

    breakdownsByUserId.set(prediction.userId, [...existingBreakdowns, breakdown]);
  }

  return [...breakdownsByUserId.entries()].map(([userId, breakdowns]) => {
    const metadata = mergeScoreBreakdowns(breakdowns);

    return {
      participantKey: `user:${userId}`,
      userId,
      teamId: null,
      score: metadata.totalScore,
      correctPredictions: metadata.correctPredictions,
      totalPredictions: metadata.totalPredictions,
      metadata
    };
  });
}

export async function calculateTeamScores(): Promise<ParticipantScore[]> {
  const [groupConsensuses, knockoutConsensuses, realResults] = await Promise.all([
    prisma.teamGroupConsensus.findMany(),
    prisma.teamKnockoutConsensus.findMany(),
    prisma.realTournamentResult.findMany()
  ]);

  const realGroupResultsByGroup = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.GROUP_STANDING && result.group)
      .map((result) => [result.group, groupStandingResultPayloadSchema.safeParse(result.payload)])
  );

  const realKnockoutResultsBySlot = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && result.bracketSlotId)
      .map((result) => [
        result.bracketSlotId,
        knockoutMatchResultPayloadSchema.safeParse(result.payload)
      ])
  );

  const breakdownsByTeamId = new Map<string, ScoreBreakdown[]>();

  for (const consensus of groupConsensuses) {
    const realResult = realGroupResultsByGroup.get(consensus.group);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreGroupPrediction(consensus, realResult.data.orderedTeamIds);
    const existingBreakdowns = breakdownsByTeamId.get(consensus.teamId) ?? [];

    breakdownsByTeamId.set(consensus.teamId, [...existingBreakdowns, breakdown]);
  }

  for (const consensus of knockoutConsensuses) {
    const realResult = realKnockoutResultsBySlot.get(consensus.bracketSlotId);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreKnockoutPrediction(consensus, realResult.data.winnerTeamId);
    const existingBreakdowns = breakdownsByTeamId.get(consensus.teamId) ?? [];

    breakdownsByTeamId.set(consensus.teamId, [...existingBreakdowns, breakdown]);
  }

  return [...breakdownsByTeamId.entries()].map(([teamId, breakdowns]) => {
    const metadata = mergeScoreBreakdowns(breakdowns);

    return {
      participantKey: `team:${teamId}`,
      userId: null,
      teamId,
      score: metadata.totalScore,
      correctPredictions: metadata.correctPredictions,
      totalPredictions: metadata.totalPredictions,
      metadata
    };
  });
}
EOF

cat > services/ranking/rankingMapper.ts <<'EOF'
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
EOF

cat > services/ranking/rankingService.ts <<'EOF'
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
EOF

cat > services/ranking/index.ts <<'EOF'
export * from "./rankingMapper.ts";
export * from "./rankingService.ts";
EOF

cat > actions/ranking.ts <<'EOF'
"use server";

import { randomUUID } from "node:crypto";
import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { RANKING_TYPE } from "../lib/contracts/enums.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { success, error as actionError } from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { recalculateRanking } from "../services/ranking/rankingService.ts";

export async function recalculateIndividualRankingAction(): Promise<
  ActionResult<{ snapshotId: string }>
> {
  try {
    const admin = await requireAdminGlobalUser();
    const snapshot = await recalculateRanking({
      type: RANKING_TYPE.INDIVIDUAL,
      requestedByUserId: admin.id,
      idempotencyKey: `manual:${RANKING_TYPE.INDIVIDUAL}:${randomUUID()}`
    });

    revalidatePath(APP_ROUTES.RANKING_INDIVIDUAL);

    return success({
      snapshotId: snapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function recalculateTeamRankingAction(): Promise<
  ActionResult<{ snapshotId: string }>
> {
  try {
    const admin = await requireAdminGlobalUser();
    const snapshot = await recalculateRanking({
      type: RANKING_TYPE.TEAM,
      requestedByUserId: admin.id,
      idempotencyKey: `manual:${RANKING_TYPE.TEAM}:${randomUUID()}`
    });

    revalidatePath(APP_ROUTES.RANKING_TEAMS);

    return success({
      snapshotId: snapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}
EOF

cat > components/ranking/RankingTable.tsx <<'EOF'
import type { RankingSnapshotDTO } from "../../lib/contracts/ranking.ts";

type RankingTableProps = {
  snapshot: RankingSnapshotDTO | null;
  emptyMessage: string;
};

export function RankingTable({ snapshot, emptyMessage }: RankingTableProps) {
  if (!snapshot || snapshot.entries.length === 0) {
    return (
      <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
        {emptyMessage}
      </div>
    );
  }

  return (
    <section className="overflow-hidden rounded-app border border-app-border bg-app-surface shadow-app">
      <div className="border-b border-app-border p-4">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Atualizado em
        </p>
        <h2 className="mt-1 text-lg font-bold">
          {new Intl.DateTimeFormat("pt-BR", {
            dateStyle: "short",
            timeStyle: "short"
          }).format(new Date(snapshot.calculatedAt))}
        </h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[640px] text-left text-sm">
          <thead className="bg-app-bg text-xs uppercase tracking-wide text-app-muted">
            <tr>
              <th className="px-4 py-3">#</th>
              <th className="px-4 py-3">Participante</th>
              <th className="px-4 py-3">Pontos</th>
              <th className="px-4 py-3">Acertos</th>
              <th className="px-4 py-3">Previsões</th>
            </tr>
          </thead>
          <tbody>
            {snapshot.entries.map((entry) => (
              <tr className="border-t border-app-border" key={entry.id}>
                <td className="px-4 py-3 font-bold">{entry.rank}</td>
                <td className="px-4 py-3">{entry.participantKey}</td>
                <td className="px-4 py-3 font-semibold">{entry.score}</td>
                <td className="px-4 py-3">{entry.correctPredictions}</td>
                <td className="px-4 py-3">{entry.totalPredictions}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
EOF

cat > app/ranking/individual/page.tsx <<'EOF'
import Link from "next/link";
import { RankingTable } from "../../../components/ranking/RankingTable.tsx";
import { RANKING_TYPE } from "../../../lib/contracts/enums.ts";
import { APP_ROUTES } from "../../../lib/contracts/routes.ts";
import { getLatestRankingSnapshot } from "../../../services/ranking/rankingService.ts";

export default async function IndividualRankingPage() {
  const snapshot = await getLatestRankingSnapshot(RANKING_TYPE.INDIVIDUAL);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-5xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Ranking
          </p>
          <h1 className="mt-3 text-2xl font-bold">Ranking individual</h1>
          <p className="mt-3 text-sm text-app-muted">
            Classificação global dos usuários conforme os resultados reais cadastrados.
          </p>
          <Link className="mt-4 inline-flex text-sm font-semibold text-app-primary" href={APP_ROUTES.RANKING_TEAMS}>
            Ver ranking por equipes →
          </Link>
        </div>

        <RankingTable
          emptyMessage="Nenhum ranking individual calculado ainda."
          snapshot={snapshot}
        />
      </section>
    </main>
  );
}
EOF

cat > app/ranking/equipes/page.tsx <<'EOF'
import Link from "next/link";
import { RankingTable } from "../../../components/ranking/RankingTable.tsx";
import { RANKING_TYPE } from "../../../lib/contracts/enums.ts";
import { APP_ROUTES } from "../../../lib/contracts/routes.ts";
import { getLatestRankingSnapshot } from "../../../services/ranking/rankingService.ts";

export default async function TeamRankingPage() {
  const snapshot = await getLatestRankingSnapshot(RANKING_TYPE.TEAM);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-5xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Ranking
          </p>
          <h1 className="mt-3 text-2xl font-bold">Ranking por equipes</h1>
          <p className="mt-3 text-sm text-app-muted">
            Classificação global das equipes com base nos consensos definidos.
          </p>
          <Link className="mt-4 inline-flex text-sm font-semibold text-app-primary" href={APP_ROUTES.RANKING_INDIVIDUAL}>
            Ver ranking individual →
          </Link>
        </div>

        <RankingTable
          emptyMessage="Nenhum ranking por equipes calculado ainda."
          snapshot={snapshot}
        />
      </section>
    </main>
  );
}
EOF

cat > docs/scoring-ranking.md <<'EOF'
# Bloco 11 — Pontuação e rankings

## Objetivo

Criar a fundação de pontuação, ranking individual, ranking por equipes e recálculo idempotente.

## Regras de pontuação

As regras de pontuação são regras de gamificação do produto, não regras oficiais FIFA.

Pontuação inicial:

- 1º colocado exato do grupo: 10 pontos;
- 2º colocado exato do grupo: 10 pontos;
- 3º colocado exato do grupo: 8 pontos;
- 4º colocado exato do grupo: 5 pontos;
- seleção classificada em posição diferente: 3 pontos;
- vencedor de confronto de mata-mata: 15 pontos.

## Resultados reais esperados

`RealTournamentResult.payload` para grupo:

```json
{
  "orderedTeamIds": ["team_1", "team_2", "team_3", "team_4"]
}
```

`RealTournamentResult.payload` para mata-mata:

```json
{
  "winnerTeamId": "team_1"
}
```

## Ranking individual

Usa previsões individuais salvas em:

- `IndividualGroupPrediction`;
- `IndividualKnockoutPrediction`.

## Ranking por equipes

Usa consensos salvos em:

- `TeamGroupConsensus`;
- `TeamKnockoutConsensus`.

## Idempotência

`RankingRecalculationJob.idempotencyKey` impede execução duplicada para a mesma chave.

Se o job já foi concluído, o mesmo snapshot é retornado.
EOF

cat > tests/scoring-ranking.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  mergeScoreBreakdowns,
  scoreGroupPrediction,
  scoreKnockoutPrediction
} from "../services/scoring/scoringCalculator.ts";

describe("scoring and ranking foundation", () => {
  it("deve pontuar previsão exata de grupo", () => {
    const result = scoreGroupPrediction(
      {
        firstPlaceTeamId: "team_1",
        secondPlaceTeamId: "team_2",
        thirdPlaceTeamId: "team_3",
        fourthPlaceTeamId: "team_4"
      },
      ["team_1", "team_2", "team_3", "team_4"]
    );

    expect(result.totalScore).toBe(33);
    expect(result.correctPredictions).toBe(4);
  });

  it("deve pontuar vencedor de mata-mata", () => {
    expect(
      scoreKnockoutPrediction(
        {
          winnerTeamId: "team_1"
        },
        "team_1"
      )
    ).toMatchObject({
      totalScore: 15,
      correctPredictions: 1
    });
  });

  it("não deve pontuar vencedor errado de mata-mata", () => {
    expect(
      scoreKnockoutPrediction(
        {
          winnerTeamId: "team_2"
        },
        "team_1"
      )
    ).toMatchObject({
      totalScore: 0,
      correctPredictions: 0
    });
  });

  it("deve mesclar breakdowns de pontuação", () => {
    const group = scoreGroupPrediction(
      {
        firstPlaceTeamId: "team_1",
        secondPlaceTeamId: "team_2",
        thirdPlaceTeamId: "team_3",
        fourthPlaceTeamId: "team_4"
      },
      ["team_1", "team_2", "team_3", "team_4"]
    );

    const knockout = scoreKnockoutPrediction(
      {
        winnerTeamId: "team_1"
      },
      "team_1"
    );

    expect(mergeScoreBreakdowns([group, knockout])).toMatchObject({
      totalScore: 48,
      correctPredictions: 5,
      totalPredictions: 5
    });
  });
});
EOF

echo "==> Bloco 11 aplicado."
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
echo "  git commit -m \"feat: add scoring and ranking foundation\""
echo "  git push"
