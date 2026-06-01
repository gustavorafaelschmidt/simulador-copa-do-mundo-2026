#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção ampla — exports de stats sem ambiguidade..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

if [ ! -f "services/stats/globalStatsService.ts" ] || [ ! -f "services/stats/index.ts" ]; then
  echo "ERRO: arquivos de stats não encontrados."
  exit 1
fi

mkdir -p .backup/stats-exports-wide-typecheck
cp services/stats/globalStatsService.ts .backup/stats-exports-wide-typecheck/globalStatsService.ts.backup
cp services/stats/index.ts .backup/stats-exports-wide-typecheck/index.ts.backup

cat > services/stats/globalStatsService.ts <<'EOF'
import { prisma } from "../../lib/db/prisma.ts";
import {
  buildGlobalStatsPayload,
  type GlobalStatsPayload
} from "./globalStatsCalculator.ts";

const GLOBAL_STATS_SNAPSHOT_KEY_PREFIX = "global_stats";

export type GlobalStatSnapshotDTO = {
  id: string;
  statKey: string;
  calculatedAt: string;
  payload: GlobalStatsPayload;
};

function toGlobalStatSnapshotDTO(snapshot: {
  id: string;
  statKey: string;
  calculatedAt: Date;
  payload: unknown;
}): GlobalStatSnapshotDTO {
  return {
    id: snapshot.id,
    statKey: snapshot.statKey,
    calculatedAt: snapshot.calculatedAt.toISOString(),
    payload: snapshot.payload as GlobalStatsPayload
  };
}

function buildGlobalStatSnapshotKey(date = new Date()): string {
  return `${GLOBAL_STATS_SNAPSHOT_KEY_PREFIX}:${date.toISOString()}`;
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
  const calculatedAt = new Date();

  const snapshot = await prisma.globalStatSnapshot.create({
    data: {
      statKey: buildGlobalStatSnapshotKey(calculatedAt),
      calculatedAt,
      payload: payload as never
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
EOF

cat > services/stats/index.ts <<'EOF'
export * from "./globalStatsCalculator.ts";
export * from "./globalStatsService.ts";
export * from "./statsLabels.ts";
EOF

echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run build"
echo ""
echo "Se passar, pode rodar:"
echo "  npm run dev"
echo "  npm run socket:dev"
