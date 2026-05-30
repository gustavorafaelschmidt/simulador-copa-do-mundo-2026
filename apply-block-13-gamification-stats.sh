#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 13 — gamificação, badges e estatísticas globais..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/badges
mkdir -p services/stats
mkdir -p components/badges
mkdir -p components/stats
mkdir -p app/dashboard/gamificacao
mkdir -p app/admin/estatisticas
mkdir -p docs
mkdir -p tests

cat > services/badges/badgeRules.ts <<'EOF'
export const BADGE_RULE_CODES = {
  FIRST_GROUP_PREDICTION: "FIRST_GROUP_PREDICTION",
  ALL_GROUPS_PREDICTED: "ALL_GROUPS_PREDICTED",
  FIRST_TEAM_CREATED: "FIRST_TEAM_CREATED",
  FIRST_TEAM_JOINED: "FIRST_TEAM_JOINED",
  FIRST_TEAM_CONSENSUS: "FIRST_TEAM_CONSENSUS",
  FIRST_RANKING_POINTS: "FIRST_RANKING_POINTS"
} as const;

export type BadgeRuleCode = (typeof BADGE_RULE_CODES)[keyof typeof BADGE_RULE_CODES];

export type BadgeEvaluationContext = {
  groupPredictionsCount: number;
  teamsOwnedCount: number;
  approvedTeamMembershipsCount: number;
  teamConsensusCount: number;
  rankingScore: number;
};

export type BadgeAwardCandidate = {
  badgeCode: BadgeRuleCode;
  reason: string;
};

export function evaluateUserBadgeCandidates(
  context: BadgeEvaluationContext
): BadgeAwardCandidate[] {
  const candidates: BadgeAwardCandidate[] = [];

  if (context.groupPredictionsCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_GROUP_PREDICTION,
      reason: "Usuário salvou a primeira previsão de grupo."
    });
  }

  if (context.groupPredictionsCount >= 12) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.ALL_GROUPS_PREDICTED,
      reason: "Usuário salvou previsões para todos os 12 grupos."
    });
  }

  if (context.teamsOwnedCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_TEAM_CREATED,
      reason: "Usuário criou sua primeira equipe."
    });
  }

  if (context.approvedTeamMembershipsCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_TEAM_JOINED,
      reason: "Usuário entrou em uma equipe aprovada."
    });
  }

  if (context.teamConsensusCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_TEAM_CONSENSUS,
      reason: "Usuário participa de equipe com primeiro consenso definido."
    });
  }

  if (context.rankingScore > 0) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_RANKING_POINTS,
      reason: "Usuário somou seus primeiros pontos no ranking."
    });
  }

  return candidates;
}
EOF

cat > services/badges/badgeMapper.ts <<'EOF'
import type { BadgeDTO, TeamBadgeDTO, UserBadgeDTO } from "../../lib/contracts/badge.ts";

export type BadgeRecord = {
  id: string;
  code: string;
  name: string;
  description: string;
  targetType: BadgeDTO["targetType"];
  rarity: BadgeDTO["rarity"];
  iconKey: string | null;
  isActive: boolean;
};

export type UserBadgeRecord = {
  id: string;
  userId: string;
  badgeId: string;
  awardedAt: Date;
  metadata: unknown | null;
};

export type TeamBadgeRecord = {
  id: string;
  teamId: string;
  badgeId: string;
  awardedAt: Date;
  metadata: unknown | null;
};

export function toBadgeDTO(badge: BadgeRecord): BadgeDTO {
  return {
    id: badge.id,
    code: badge.code,
    name: badge.name,
    description: badge.description,
    targetType: badge.targetType,
    rarity: badge.rarity,
    iconKey: badge.iconKey,
    isActive: badge.isActive
  };
}

export function toUserBadgeDTO(userBadge: UserBadgeRecord): UserBadgeDTO {
  return {
    id: userBadge.id,
    userId: userBadge.userId,
    badgeId: userBadge.badgeId,
    awardedAt: userBadge.awardedAt.toISOString(),
    metadata: userBadge.metadata
  };
}

export function toTeamBadgeDTO(teamBadge: TeamBadgeRecord): TeamBadgeDTO {
  return {
    id: teamBadge.id,
    teamId: teamBadge.teamId,
    badgeId: teamBadge.badgeId,
    awardedAt: teamBadge.awardedAt.toISOString(),
    metadata: teamBadge.metadata
  };
}
EOF

cat > services/badges/badgeService.ts <<'EOF'
import { prisma } from "../../lib/db/prisma.ts";
import { BADGE_TARGET_TYPE, TEAM_MEMBER_APPROVAL_STATUS } from "../../lib/contracts/enums.ts";
import type { BadgeDTO, UserBadgeDTO } from "../../lib/contracts/badge.ts";
import { evaluateUserBadgeCandidates } from "./badgeRules.ts";
import { toBadgeDTO, toUserBadgeDTO } from "./badgeMapper.ts";

export type UserBadgeWithBadgeDTO = UserBadgeDTO & {
  badge: BadgeDTO;
};

export async function listActiveBadges(): Promise<BadgeDTO[]> {
  const badges = await prisma.badge.findMany({
    where: {
      isActive: true
    },
    orderBy: [
      {
        rarity: "asc"
      },
      {
        code: "asc"
      }
    ]
  });

  return badges.map(toBadgeDTO);
}

export async function listUserBadges(userId: string): Promise<UserBadgeWithBadgeDTO[]> {
  const userBadges = await prisma.userBadge.findMany({
    where: {
      userId
    },
    include: {
      badge: true
    },
    orderBy: {
      awardedAt: "desc"
    }
  });

  return userBadges.map((userBadge) => ({
    ...toUserBadgeDTO(userBadge),
    badge: toBadgeDTO(userBadge.badge)
  }));
}

export async function evaluateAndAwardUserBadges(userId: string): Promise<UserBadgeWithBadgeDTO[]> {
  const [
    groupPredictionsCount,
    teamsOwnedCount,
    approvedTeamMembershipsCount,
    rankingEntry,
    userMemberships
  ] = await Promise.all([
    prisma.individualGroupPrediction.count({
      where: {
        userId
      }
    }),
    prisma.team.count({
      where: {
        ownerId: userId
      }
    }),
    prisma.teamMember.count({
      where: {
        userId,
        approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.APPROVED
      }
    }),
    prisma.rankingEntry.findFirst({
      where: {
        userId
      },
      orderBy: {
        score: "desc"
      }
    }),
    prisma.teamMember.findMany({
      where: {
        userId,
        approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.APPROVED
      },
      select: {
        teamId: true
      }
    })
  ]);

  const teamIds = userMemberships.map((membership) => membership.teamId);

  const teamConsensusCount =
    teamIds.length === 0
      ? 0
      : await prisma.teamGroupConsensus.count({
          where: {
            teamId: {
              in: teamIds
            }
          }
        });

  const candidates = evaluateUserBadgeCandidates({
    groupPredictionsCount,
    teamsOwnedCount,
    approvedTeamMembershipsCount,
    teamConsensusCount,
    rankingScore: rankingEntry?.score ?? 0
  });

  if (candidates.length === 0) {
    return listUserBadges(userId);
  }

  const badges = await prisma.badge.findMany({
    where: {
      code: {
        in: candidates.map((candidate) => candidate.badgeCode)
      },
      targetType: BADGE_TARGET_TYPE.USER,
      isActive: true
    }
  });

  await prisma.$transaction(
    badges.map((badge) =>
      prisma.userBadge.upsert({
        where: {
          userId_badgeId: {
            userId,
            badgeId: badge.id
          }
        },
        update: {},
        create: {
          userId,
          badgeId: badge.id,
          metadata: {
            reason:
              candidates.find((candidate) => candidate.badgeCode === badge.code)?.reason ??
              "Badge concedida automaticamente."
          }
        }
      })
    )
  );

  return listUserBadges(userId);
}
EOF

cat > services/badges/index.ts <<'EOF'
export * from "./badgeRules.ts";
export * from "./badgeMapper.ts";
export * from "./badgeService.ts";
EOF

cat > services/stats/globalStatsCalculator.ts <<'EOF'
export type GlobalStatsInput = {
  usersCount: number;
  teamsCount: number;
  individualPredictionsCount: number;
  teamConsensusCount: number;
  realResultsCount: number;
  rankingSnapshotsCount: number;
};

export type GlobalStatsPayload = GlobalStatsInput & {
  engagementRate: number;
};

export function calculateEngagementRate(input: GlobalStatsInput): number {
  if (input.usersCount <= 0) {
    return 0;
  }

  return Number(((input.individualPredictionsCount / input.usersCount) * 100).toFixed(2));
}

export function buildGlobalStatsPayload(input: GlobalStatsInput): GlobalStatsPayload {
  return {
    ...input,
    engagementRate: calculateEngagementRate(input)
  };
}
EOF

cat > services/stats/globalStatsService.ts <<'EOF'
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
EOF

cat > services/stats/index.ts <<'EOF'
export * from "./globalStatsCalculator.ts";
export * from "./globalStatsService.ts";
EOF

cat > actions/gamification.ts <<'EOF'
"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { error as actionError, success } from "../lib/errors/actionResponses.ts";
import { requireCurrentUser } from "../lib/auth/currentUser";
import { evaluateAndAwardUserBadges } from "../services/badges/badgeService.ts";

export async function refreshMyBadgesAction(): Promise<ActionResult<{ awardedCount: number }>> {
  try {
    const user = await requireCurrentUser();
    const badges = await evaluateAndAwardUserBadges(user.id);

    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      awardedCount: badges.length
    });
  } catch (error) {
    return actionError(error);
  }
}
EOF

cat > actions/stats.ts <<'EOF'
"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { error as actionError, success } from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { createGlobalStatSnapshot } from "../services/stats/globalStatsService.ts";

export async function createGlobalStatSnapshotAction(): Promise<
  ActionResult<{ snapshotId: string }>
> {
  try {
    await requireAdminGlobalUser();
    const snapshot = await createGlobalStatSnapshot();

    revalidatePath(APP_ROUTES.ADMIN);

    return success({
      snapshotId: snapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}
EOF

node <<'NODE'
const fs = require("node:fs");

const routesPath = "lib/contracts/routes.ts";
let source = fs.readFileSync(routesPath, "utf8");

if (!source.includes('GAMIFICATION: "/dashboard/gamificacao"')) {
  source = source.replace(
    'DASHBOARD: "/dashboard",',
    'DASHBOARD: "/dashboard",\n  GAMIFICATION: "/dashboard/gamificacao",'
  );
}

if (!source.includes('ADMIN_STATS: "/admin/estatisticas"')) {
  source = source.replace(
    'ADMIN_RESULTS: "/admin/resultados"',
    'ADMIN_RESULTS: "/admin/resultados",\n  ADMIN_STATS: "/admin/estatisticas"'
  );
}

fs.writeFileSync(routesPath, source);
NODE

cat > components/badges/BadgeCard.tsx <<'EOF'
import type { BadgeDTO } from "../../lib/contracts/badge.ts";

type BadgeCardProps = {
  badge: BadgeDTO;
  awardedAt?: string;
};

const rarityClassName = {
  COMMON: "border-app-border",
  RARE: "border-blue-200",
  EPIC: "border-purple-200",
  LEGENDARY: "border-yellow-300"
} as const;

export function BadgeCard({ badge, awardedAt }: BadgeCardProps) {
  return (
    <article className={`rounded-app border bg-app-surface p-4 shadow-app ${rarityClassName[badge.rarity]}`}>
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-app-primary">
            {badge.rarity}
          </p>
          <h3 className="mt-2 font-bold">{badge.name}</h3>
        </div>

        <span className="rounded-xl bg-app-bg px-3 py-2 text-lg" aria-hidden="true">
          {badge.iconKey ?? "🏆"}
        </span>
      </div>

      <p className="mt-3 text-sm leading-6 text-app-muted">{badge.description}</p>

      {awardedAt ? (
        <p className="mt-3 text-xs text-app-muted">
          Conquistada em{" "}
          {new Intl.DateTimeFormat("pt-BR", {
            dateStyle: "short",
            timeStyle: "short"
          }).format(new Date(awardedAt))}
        </p>
      ) : null}
    </article>
  );
}
EOF

cat > components/stats/GlobalStatsCards.tsx <<'EOF'
import type { GlobalStatsPayload } from "../../services/stats/globalStatsCalculator.ts";

type GlobalStatsCardsProps = {
  payload: GlobalStatsPayload;
};

const statItems = [
  ["usersCount", "Usuários"],
  ["teamsCount", "Equipes"],
  ["individualPredictionsCount", "Previsões individuais"],
  ["teamConsensusCount", "Consensos de equipe"],
  ["realResultsCount", "Resultados reais"],
  ["rankingSnapshotsCount", "Rankings calculados"],
  ["engagementRate", "Engajamento (%)"]
] as const;

export function GlobalStatsCards({ payload }: GlobalStatsCardsProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {statItems.map(([key, label]) => (
        <article
          className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
          key={key}
        >
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            {label}
          </p>
          <p className="mt-3 text-3xl font-bold">{payload[key]}</p>
        </article>
      ))}
    </div>
  );
}
EOF

cat > app/dashboard/gamificacao/page.tsx <<'EOF'
import { refreshMyBadgesAction } from "../../../actions/gamification.ts";
import { BadgeCard } from "../../../components/badges/BadgeCard.tsx";
import { requireCurrentUser } from "../../../lib/auth/currentUser";
import { evaluateAndAwardUserBadges } from "../../../services/badges/badgeService.ts";

export default async function GamificationPage() {
  const user = await requireCurrentUser();
  const userBadges = await evaluateAndAwardUserBadges(user.id);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Gamificação
          </p>

          <h1 className="mt-3 text-2xl font-bold">Minhas conquistas</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Badges são concedidas automaticamente conforme você participa do simulador.
          </p>

          <form action={refreshMyBadgesAction} className="mt-5">
            <button
              className="rounded-xl border border-app-border px-4 py-2 font-semibold"
              type="submit"
            >
              Atualizar badges
            </button>
          </form>
        </div>

        {userBadges.length === 0 ? (
          <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
            Nenhuma badge conquistada ainda. Faça previsões, entre em equipes e acompanhe
            o ranking para desbloquear conquistas.
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {userBadges.map((userBadge) => (
              <BadgeCard
                awardedAt={userBadge.awardedAt}
                badge={userBadge.badge}
                key={userBadge.id}
              />
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
EOF

cat > app/admin/estatisticas/page.tsx <<'EOF'
import { createGlobalStatSnapshotAction } from "../../../actions/stats.ts";
import { GlobalStatsCards } from "../../../components/stats/GlobalStatsCards.tsx";
import { requireAdminGlobalUser } from "../../../lib/auth/currentUser";
import {
  createGlobalStatSnapshot,
  getLatestGlobalStatSnapshot
} from "../../../services/stats/globalStatsService.ts";

export default async function AdminStatsPage() {
  await requireAdminGlobalUser();

  const snapshot = (await getLatestGlobalStatSnapshot()) ?? (await createGlobalStatSnapshot());

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Admin
          </p>

          <h1 className="mt-3 text-2xl font-bold">Estatísticas globais</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Snapshot administrativo com volume de usuários, equipes, previsões,
            consensos, resultados e rankings.
          </p>

          <p className="mt-3 text-xs text-app-muted">
            Último snapshot:{" "}
            {new Intl.DateTimeFormat("pt-BR", {
              dateStyle: "short",
              timeStyle: "short"
            }).format(new Date(snapshot.calculatedAt))}
          </p>

          <form action={createGlobalStatSnapshotAction} className="mt-5">
            <button
              className="rounded-xl border border-app-border px-4 py-2 font-semibold"
              type="submit"
            >
              Gerar novo snapshot
            </button>
          </form>
        </div>

        <GlobalStatsCards payload={snapshot.payload} />
      </section>
    </main>
  );
}
EOF

cat > docs/gamification-stats.md <<'EOF'
# Bloco 13 — Gamificação, badges e estatísticas globais

## Objetivo

Adicionar uma camada inicial de gamificação com badges e estatísticas globais.

## Badges iniciais

- `FIRST_GROUP_PREDICTION`
- `ALL_GROUPS_PREDICTED`
- `FIRST_TEAM_CREATED`
- `FIRST_TEAM_JOINED`
- `FIRST_TEAM_CONSENSUS`
- `FIRST_RANKING_POINTS`

## Regras

A avaliação de badges é idempotente:

- usa `upsert`;
- respeita badge única por usuário;
- não duplica conquistas.

## Estatísticas globais

Snapshots agregam:

- usuários;
- equipes;
- previsões individuais;
- consensos;
- resultados reais;
- snapshots de ranking;
- taxa simples de engajamento.

## Próximos passos

- Criar badges por equipe.
- Criar eventos de notificação em tempo real.
- Evoluir estatísticas para gráficos.
EOF

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
import { buildRankingStatsLabel } from "../services/stats/globalStatsService.ts";

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

echo "==> Bloco 13 aplicado."
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
echo "  git commit -m \"feat: add gamification and global stats\""
echo "  git push"
