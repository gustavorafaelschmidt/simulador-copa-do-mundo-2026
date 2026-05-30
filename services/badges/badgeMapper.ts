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
