/*
  Enums canônicos do projeto.

  Regra:
  - valores técnicos em inglês;
  - labels em português ficam na UI;
  - Prisma, services, DTOs, Socket.io e Server Actions devem respeitar estes nomes.
*/

export const AUTH_PROVIDER_VALUES = ["CREDENTIALS", "GOOGLE"] as const;

export const AUTH_PROVIDER = {
  CREDENTIALS: "CREDENTIALS",
  GOOGLE: "GOOGLE"
} as const;

export type AuthProvider = (typeof AUTH_PROVIDER_VALUES)[number];

export const GLOBAL_ROLE_VALUES = ["USER", "ADMIN_GLOBAL"] as const;

export const GLOBAL_ROLE = {
  USER: "USER",
  ADMIN_GLOBAL: "ADMIN_GLOBAL"
} as const;

export type GlobalRole = (typeof GLOBAL_ROLE_VALUES)[number];

export const TEAM_MEMBER_ROLE_VALUES = ["CAPTAIN", "ADMIN", "MEMBER"] as const;

export const TEAM_MEMBER_ROLE = {
  CAPTAIN: "CAPTAIN",
  ADMIN: "ADMIN",
  MEMBER: "MEMBER"
} as const;

export type TeamMemberRole = (typeof TEAM_MEMBER_ROLE_VALUES)[number];

export const TEAM_MEMBER_APPROVAL_STATUS_VALUES = [
  "PENDING",
  "APPROVED",
  "REJECTED",
  "REMOVED"
] as const;

export const TEAM_MEMBER_APPROVAL_STATUS = {
  PENDING: "PENDING",
  APPROVED: "APPROVED",
  REJECTED: "REJECTED",
  REMOVED: "REMOVED"
} as const;

export type TeamMemberApprovalStatus = (typeof TEAM_MEMBER_APPROVAL_STATUS_VALUES)[number];

export const VOTING_SESSION_TYPE_VALUES = ["GROUP_STAGE", "KNOCKOUT"] as const;

export const VOTING_SESSION_TYPE = {
  GROUP_STAGE: "GROUP_STAGE",
  KNOCKOUT: "KNOCKOUT"
} as const;

export type VotingSessionType = (typeof VOTING_SESSION_TYPE_VALUES)[number];

export const VOTING_SESSION_STATUS_VALUES = [
  "DRAFT",
  "OPEN",
  "TIEBREAKER_REQUIRED",
  "CLOSED",
  "CANCELLED"
] as const;

export const VOTING_SESSION_STATUS = {
  DRAFT: "DRAFT",
  OPEN: "OPEN",
  TIEBREAKER_REQUIRED: "TIEBREAKER_REQUIRED",
  CLOSED: "CLOSED",
  CANCELLED: "CANCELLED"
} as const;

export type VotingSessionStatus = (typeof VOTING_SESSION_STATUS_VALUES)[number];

export const KNOCKOUT_PHASE_VALUES = [
  "ROUND_OF_32",
  "ROUND_OF_16",
  "QUARTER_FINAL",
  "SEMI_FINAL",
  "THIRD_PLACE",
  "FINAL"
] as const;

export const KNOCKOUT_PHASE = {
  ROUND_OF_32: "ROUND_OF_32",
  ROUND_OF_16: "ROUND_OF_16",
  QUARTER_FINAL: "QUARTER_FINAL",
  SEMI_FINAL: "SEMI_FINAL",
  THIRD_PLACE: "THIRD_PLACE",
  FINAL: "FINAL"
} as const;

export type KnockoutPhase = (typeof KNOCKOUT_PHASE_VALUES)[number];

export const CONSENSUS_DECISION_TYPE_VALUES = [
  "MAJORITY",
  "CAPTAIN_TIEBREAK",
  "ADMIN_OVERRIDE"
] as const;

export const CONSENSUS_DECISION_TYPE = {
  MAJORITY: "MAJORITY",
  CAPTAIN_TIEBREAK: "CAPTAIN_TIEBREAK",
  ADMIN_OVERRIDE: "ADMIN_OVERRIDE"
} as const;

export type ConsensusDecisionType = (typeof CONSENSUS_DECISION_TYPE_VALUES)[number];

export const RANKING_TYPE_VALUES = ["INDIVIDUAL", "TEAM"] as const;

export const RANKING_TYPE = {
  INDIVIDUAL: "INDIVIDUAL",
  TEAM: "TEAM"
} as const;

export type RankingType = (typeof RANKING_TYPE_VALUES)[number];

export const REAL_RESULT_TYPE_VALUES = [
  "GROUP_STANDING",
  "GROUP_MATCH",
  "KNOCKOUT_MATCH",
  "CHAMPION",
  "RUNNER_UP",
  "THIRD_PLACE"
] as const;

export const REAL_RESULT_TYPE = {
  GROUP_STANDING: "GROUP_STANDING",
  GROUP_MATCH: "GROUP_MATCH",
  KNOCKOUT_MATCH: "KNOCKOUT_MATCH",
  CHAMPION: "CHAMPION",
  RUNNER_UP: "RUNNER_UP",
  THIRD_PLACE: "THIRD_PLACE"
} as const;

export type RealResultType = (typeof REAL_RESULT_TYPE_VALUES)[number];

export const GROUP_LETTER_VALUES = [
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L"
] as const;

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

export type GroupLetter = (typeof GROUP_LETTER_VALUES)[number];

export const RANKING_JOB_STATUS_VALUES = [
  "PENDING",
  "RUNNING",
  "COMPLETED",
  "FAILED",
  "CANCELLED"
] as const;

export const RANKING_JOB_STATUS = {
  PENDING: "PENDING",
  RUNNING: "RUNNING",
  COMPLETED: "COMPLETED",
  FAILED: "FAILED",
  CANCELLED: "CANCELLED"
} as const;

export type RankingJobStatus = (typeof RANKING_JOB_STATUS_VALUES)[number];

export const OFFICIAL_DATA_STATUS_VALUES = [
  "PLACEHOLDER",
  "PARTIAL",
  "OFFICIAL",
  "DEPRECATED"
] as const;

export const OFFICIAL_DATA_STATUS = {
  PLACEHOLDER: "PLACEHOLDER",
  PARTIAL: "PARTIAL",
  OFFICIAL: "OFFICIAL",
  DEPRECATED: "DEPRECATED"
} as const;

export type OfficialDataStatus = (typeof OFFICIAL_DATA_STATUS_VALUES)[number];

export const BADGE_TARGET_TYPE_VALUES = ["USER", "TEAM"] as const;

export const BADGE_TARGET_TYPE = {
  USER: "USER",
  TEAM: "TEAM"
} as const;

export type BadgeTargetType = (typeof BADGE_TARGET_TYPE_VALUES)[number];

export const BADGE_RARITY_VALUES = ["COMMON", "RARE", "EPIC", "LEGENDARY"] as const;

export const BADGE_RARITY = {
  COMMON: "COMMON",
  RARE: "RARE",
  EPIC: "EPIC",
  LEGENDARY: "LEGENDARY"
} as const;

export type BadgeRarity = (typeof BADGE_RARITY_VALUES)[number];
