#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 13 — isolando helpers puros de stats sem Prisma nos testes..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/stats tests

cat > services/stats/statsLabels.ts <<'EOF'
import type { RankingType } from "../../lib/contracts/enums.ts";

export function buildRankingStatsLabel(type: RankingType): string {
  return type === "INDIVIDUAL" ? "Ranking individual" : "Ranking por equipes";
}
EOF

node <<'NODE'
const fs = require("node:fs");

const indexPath = "services/stats/index.ts";
let indexSource = fs.existsSync(indexPath) ? fs.readFileSync(indexPath, "utf8") : "";

if (!indexSource.includes('export * from "./statsLabels.ts";')) {
  indexSource += '\nexport * from "./statsLabels.ts";\n';
}

fs.writeFileSync(indexPath, indexSource.trimStart());
NODE

cat > tests/gamification-stats.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  BADGE_RULE_CODES,
  evaluateUserBadgeCandidates
} from "../services/badges/badgeRules.ts";
import { toBadgeDTO, toUserBadgeDTO } from "../services/badges/badgeMapper.ts";
import {
  buildGlobalStatsPayload,
  calculateEngagementRate
} from "../services/stats/globalStatsCalculator.ts";
import { buildRankingStatsLabel } from "../services/stats/statsLabels.ts";

describe("gamification and stats", () => {
  it("deve conceder badge de primeira previsão", () => {
    const candidates = evaluateUserBadgeCandidates({
      groupPredictionsCount: 1,
      teamsOwnedCount: 0,
      approvedTeamMembershipsCount: 0,
      teamConsensusCount: 0,
      rankingScore: 0
    });

    expect(candidates.map((candidate) => candidate.badgeCode)).toContain(
      BADGE_RULE_CODES.FIRST_GROUP_PREDICTION
    );
  });

  it("deve conceder badge de todos os grupos previstos", () => {
    const candidates = evaluateUserBadgeCandidates({
      groupPredictionsCount: 12,
      teamsOwnedCount: 0,
      approvedTeamMembershipsCount: 0,
      teamConsensusCount: 0,
      rankingScore: 0
    });

    expect(candidates.map((candidate) => candidate.badgeCode)).toContain(
      BADGE_RULE_CODES.ALL_GROUPS_PREDICTED
    );
  });

  it("deve mapear badge para DTO", () => {
    expect(
      toBadgeDTO({
        id: "badge_1",
        code: "FIRST_GROUP_PREDICTION",
        name: "Primeiro palpite",
        description: "Salvou a primeira previsão.",
        targetType: "USER",
        rarity: "COMMON",
        iconKey: "🏆",
        isActive: true
      })
    ).toMatchObject({
      id: "badge_1",
      rarity: "COMMON"
    });
  });

  it("deve mapear user badge para DTO", () => {
    expect(
      toUserBadgeDTO({
        id: "user_badge_1",
        userId: "user_1",
        badgeId: "badge_1",
        awardedAt: new Date("2026-01-01T00:00:00.000Z"),
        metadata: null
      })
    ).toMatchObject({
      id: "user_badge_1",
      awardedAt: "2026-01-01T00:00:00.000Z"
    });
  });

  it("deve calcular taxa de engajamento", () => {
    expect(
      calculateEngagementRate({
        usersCount: 10,
        teamsCount: 0,
        individualPredictionsCount: 25,
        teamConsensusCount: 0,
        realResultsCount: 0,
        rankingSnapshotsCount: 0
      })
    ).toBe(250);
  });

  it("deve montar payload de estatísticas globais", () => {
    expect(
      buildGlobalStatsPayload({
        usersCount: 2,
        teamsCount: 1,
        individualPredictionsCount: 4,
        teamConsensusCount: 1,
        realResultsCount: 0,
        rankingSnapshotsCount: 0
      })
    ).toMatchObject({
      usersCount: 2,
      engagementRate: 200
    });
  });

  it("deve retornar label do tipo de ranking", () => {
    expect(buildRankingStatsLabel("INDIVIDUAL")).toBe("Ranking individual");
    expect(buildRankingStatsLabel("TEAM")).toBe("Ranking por equipes");
  });
});
EOF

echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run dev"
echo ""
echo "Se passar, commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add gamification and global stats\""
echo "  git push"
