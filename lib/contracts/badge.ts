import type { BadgeRarity, BadgeTargetType } from "@/lib/contracts/enums";
import type { TeamId } from "@/lib/contracts/team";
import type { UserId } from "@/lib/contracts/user";

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
