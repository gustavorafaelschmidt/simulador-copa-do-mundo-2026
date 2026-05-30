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
