/*
  Enums canônicos do projeto.

  Regra:
  - valores técnicos em inglês;
  - labels em português devem ficar na camada de UI;
  - Prisma, services, DTOs, Socket.io e Server Actions devem respeitar estes nomes.
*/

export const AUTH_PROVIDER = {
  CREDENTIALS: "CREDENTIALS",
  GOOGLE: "GOOGLE"
} as const;

export type AuthProvider = (typeof AUTH_PROVIDER)[keyof typeof AUTH_PROVIDER];

export const GLOBAL_ROLE = {
  USER: "USER",
  ADMIN_GLOBAL: "ADMIN_GLOBAL"
} as const;

export type GlobalRole = (typeof GLOBAL_ROLE)[keyof typeof GLOBAL_ROLE];

export const TEAM_MEMBER_ROLE = {
  CAPTAIN: "CAPTAIN",
  ADMIN: "ADMIN",
  MEMBER: "MEMBER"
} as const;

export type TeamMemberRole = (typeof TEAM_MEMBER_ROLE)[keyof typeof TEAM_MEMBER_ROLE];

export const TEAM_MEMBER_APPROVAL_STATUS = {
  PENDING: "PENDING",
  APPROVED: "APPROVED",
  REJECTED: "REJECTED",
  REMOVED: "REMOVED"
} as const;

export type TeamMemberApprovalStatus =
  (typeof TEAM_MEMBER_APPROVAL_STATUS)[keyof typeof TEAM_MEMBER_APPROVAL_STATUS];

export const VOTING_SESSION_TYPE = {
  GROUP_STAGE: "GROUP_STAGE",
  KNOCKOUT: "KNOCKOUT"
} as const;

export type VotingSessionType =
  (typeof VOTING_SESSION_TYPE)[keyof typeof VOTING_SESSION_TYPE];

export const VOTING_SESSION_STATUS = {
  DRAFT: "DRAFT",
  OPEN: "OPEN",
  TIEBREAKER_REQUIRED: "TIEBREAKER_REQUIRED",
  CLOSED: "CLOSED",
  CANCELLED: "CANCELLED"
} as const;

export type VotingSessionStatus =
  (typeof VOTING_SESSION_STATUS)[keyof typeof VOTING_SESSION_STATUS];

export const KNOCKOUT_PHASE = {
  ROUND_OF_32: "ROUND_OF_32",
  ROUND_OF_16: "ROUND_OF_16",
  QUARTER_FINAL: "QUARTER_FINAL",
  SEMI_FINAL: "SEMI_FINAL",
  THIRD_PLACE: "THIRD_PLACE",
  FINAL: "FINAL"
} as const;

export type KnockoutPhase = (typeof KNOCKOUT_PHASE)[keyof typeof KNOCKOUT_PHASE];

export const CONSENSUS_DECISION_TYPE = {
  MAJORITY: "MAJORITY",
  CAPTAIN_TIEBREAK: "CAPTAIN_TIEBREAK",
  ADMIN_OVERRIDE: "ADMIN_OVERRIDE"
} as const;

export type ConsensusDecisionType =
  (typeof CONSENSUS_DECISION_TYPE)[keyof typeof CONSENSUS_DECISION_TYPE];

export const RANKING_TYPE = {
  INDIVIDUAL: "INDIVIDUAL",
  TEAM: "TEAM"
} as const;

export type RankingType = (typeof RANKING_TYPE)[keyof typeof RANKING_TYPE];

export const REAL_RESULT_TYPE = {
  GROUP_STANDING: "GROUP_STANDING",
  GROUP_MATCH: "GROUP_MATCH",
  KNOCKOUT_MATCH: "KNOCKOUT_MATCH",
  CHAMPION: "CHAMPION",
  RUNNER_UP: "RUNNER_UP",
  THIRD_PLACE: "THIRD_PLACE"
} as const;

export type RealResultType = (typeof REAL_RESULT_TYPE)[keyof typeof REAL_RESULT_TYPE];

export const GROUP_LETTER = {
  A: "A",
  B: "B",
  C: "C",
  D: "D",
  E: "E",
  F: "F",
  G: "G",
  H: "H",
  I: "I",
  J: "J",
  K: "K",
  L: "L"
} as const;

export type GroupLetter = (typeof GROUP_LETTER)[keyof typeof GROUP_LETTER];

export const RANKING_JOB_STATUS = {
  PENDING: "PENDING",
  RUNNING: "RUNNING",
  COMPLETED: "COMPLETED",
  FAILED: "FAILED",
  CANCELLED: "CANCELLED"
} as const;

export type RankingJobStatus =
  (typeof RANKING_JOB_STATUS)[keyof typeof RANKING_JOB_STATUS];

export const OFFICIAL_DATA_STATUS = {
  PLACEHOLDER: "PLACEHOLDER",
  PARTIAL: "PARTIAL",
  OFFICIAL: "OFFICIAL",
  DEPRECATED: "DEPRECATED"
} as const;

export type OfficialDataStatus =
  (typeof OFFICIAL_DATA_STATUS)[keyof typeof OFFICIAL_DATA_STATUS];

export const BADGE_TARGET_TYPE = {
  USER: "USER",
  TEAM: "TEAM"
} as const;

export type BadgeTargetType = (typeof BADGE_TARGET_TYPE)[keyof typeof BADGE_TARGET_TYPE];

export const BADGE_RARITY = {
  COMMON: "COMMON",
  RARE: "RARE",
  EPIC: "EPIC",
  LEGENDARY: "LEGENDARY"
} as const;

export type BadgeRarity = (typeof BADGE_RARITY)[keyof typeof BADGE_RARITY];