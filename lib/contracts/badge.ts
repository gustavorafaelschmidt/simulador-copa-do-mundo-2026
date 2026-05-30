import type { BadgeRarity, BadgeTargetType } from "./enums.ts";
import type { TeamId } from "./team.ts";
import type { UserId } from "./user.ts";

export type BadgeDTO = {
  id: string;
  code: string;
  name: string;
  description: string;
  targetType: BadgeTargetType;
  rarity: BadgeRarity;
  iconKey: string | null;
  isActive: boolean;
};

export type UserBadgeDTO = {
  id: string;
  userId: UserId;
  badgeId: string;
  awardedAt: string;
  metadata: unknown | null;
};

export type TeamBadgeDTO = {
  id: string;
  teamId: TeamId;
  badgeId: string;
  awardedAt: string;
  metadata: unknown | null;
};
