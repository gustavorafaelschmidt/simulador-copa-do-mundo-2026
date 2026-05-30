import type { TeamMemberApprovalStatus, TeamMemberRole } from "@/lib/contracts/enums";
import type { PublicUserDTO, UserId } from "@/lib/contracts/user";

export type TeamId = string;
export type TeamInviteCode = string;

export type TeamDTO = {
  id: TeamId;
  name: string;
  slug: string;
  description: string | null;
  inviteCode: string;
  ownerId: UserId;
  isActive: boolean;
  maxMembers: number;
  createdAt: string;
  updatedAt: string;
};

export type TeamMemberDTO = {
  id: string;
  teamId: TeamId;
  userId: UserId;
  role: TeamMemberRole;
  approvalStatus: TeamMemberApprovalStatus;
  user?: PublicUserDTO;
  approvedAt: string | null;
  joinedAt: string | null;
  removedAt: string | null;
};

export type TeamInviteDTO = {
  id: string;
  teamId: TeamId;
  code: TeamInviteCode;
  expiresAt: string | null;
  maxUses: number | null;
  usedCount: number;
  revokedAt: string | null;
};

export type CreateTeamInputDTO = {
  name: string;
  slug?: string;
  description?: string;
  maxMembers?: number;
};

export type UpdateTeamInputDTO = {
  teamId: TeamId;
  name?: string;
  description?: string | null;
  maxMembers?: number;
};

export type JoinTeamByCodeInputDTO = {
  inviteCode: TeamInviteCode;
};

export type ReviewTeamMemberInputDTO = {
  teamId: TeamId;
  memberId: string;
  approvalStatus: Extract<TeamMemberApprovalStatus, "APPROVED" | "REJECTED">;
};

export type ChangeTeamMemberRoleInputDTO = {
  teamId: TeamId;
  memberId: string;
  role: Exclude<TeamMemberRole, "CAPTAIN">;
};

export type RemoveTeamMemberInputDTO = {
  teamId: TeamId;
  memberId: string;
};
