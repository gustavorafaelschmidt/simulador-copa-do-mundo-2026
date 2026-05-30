#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 2 — contratos compartilhados, DTOs e validações..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p lib/contracts
mkdir -p lib/validations
mkdir -p tests

cat > lib/contracts/enums.ts <<'EOF'
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
EOF

cat > lib/contracts/http.ts <<'EOF'
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER_ERROR: 500
} as const;

export type HttpStatus = (typeof HTTP_STATUS)[keyof typeof HTTP_STATUS];
EOF

cat > lib/contracts/routes.ts <<'EOF'
/*
  Rotas canônicas do projeto.

  Regra:
  - páginas públicas e privadas devem importar daqui quando fizer sentido;
  - evitar strings soltas em redirects, links e Server Actions.
*/

export const APP_ROUTES = {
  HOME: "/",
  LOGIN: "/entrar",
  REGISTER: "/cadastro",
  ONBOARDING: "/onboarding",
  DASHBOARD: "/dashboard",

  TEAMS: "/equipes",
  TEAM_DETAILS: (teamId: string) => `/equipes/${teamId}`,

  RANKING: "/ranking",
  RANKING_INDIVIDUAL: "/ranking/individual",
  RANKING_TEAMS: "/ranking/equipes",

  SETTINGS: "/configuracoes",
  PROFILE_SETTINGS: "/configuracoes/perfil",

  ADMIN: "/admin",
  ADMIN_RESULTS: "/admin/resultados"
} as const;

export const API_ROUTES = {
  HEALTH: "/api/health",
  AUTH: "/api/auth",

  TEAMS: "/api/equipes",
  TEAM_BY_ID: (teamId: string) => `/api/equipes/${teamId}`,
  TEAM_INVITES: (teamId: string) => `/api/equipes/${teamId}/convites`,

  RANKING_INDIVIDUAL: "/api/ranking/individual",
  RANKING_TEAMS: "/api/ranking/equipes",

  ADMIN_RESULTS: "/api/admin/resultados"
} as const;
EOF

cat > lib/contracts/pagination.ts <<'EOF'
export type PaginationParams = {
  page: number;
  perPage: number;
};

export type PaginatedResult<TItem> = {
  items: TItem[];
  pagination: {
    page: number;
    perPage: number;
    totalItems: number;
    totalPages: number;
  };
};

export const DEFAULT_PAGE = 1;
export const DEFAULT_PER_PAGE = 20;
export const MAX_PER_PAGE = 100;
EOF

cat > lib/contracts/user.ts <<'EOF'
import type { AuthProvider, GlobalRole } from "@/lib/contracts/enums";

export type UserId = string;

export type PublicUserDTO = {
  id: UserId;
  name: string | null;
  nickname: string | null;
  image: string | null;
};

export type CurrentUserDTO = {
  id: UserId;
  name: string | null;
  email: string | null;
  firstName: string | null;
  lastName: string | null;
  nickname: string | null;
  birthDate: string | null;
  image: string | null;
  globalRole: GlobalRole;
  primaryAuthProvider: AuthProvider;
  profileCompleted: boolean;
  onboardingCompleted: boolean;
};

export type CompleteProfileInputDTO = {
  firstName: string;
  lastName: string;
  nickname: string;
  birthDate: string;
};

export type UpdateProfileImageInputDTO = {
  image: string;
};
EOF

cat > lib/contracts/team.ts <<'EOF'
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
EOF

cat > lib/contracts/officialData.ts <<'EOF'
import type { GroupLetter, KnockoutPhase, OfficialDataStatus } from "@/lib/contracts/enums";

export type OfficialDataVersionId = string;
export type NationalTeamId = string;
export type TournamentGroupId = string;
export type OfficialBracketSlotId = string;
export type OfficialMatchId = string;

export type OfficialDataVersionDTO = {
  id: OfficialDataVersionId;
  code: string;
  description: string;
  status: OfficialDataStatus;
  sourceDocumentRef: string | null;
  importedAt: string | null;
  isActive: boolean;
};

export type TournamentGroupDTO = {
  id: TournamentGroupId;
  letter: GroupLetter;
  name: string;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type NationalTeamDTO = {
  id: NationalTeamId;
  fifaCode: string;
  name: string;
  shortName: string;
  flagUrl: string | null;
  groupId: TournamentGroupId | null;
  groupLetter?: GroupLetter | null;
  groupPosition: number | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialBracketSlotDTO = {
  id: OfficialBracketSlotId;
  slotCode: string;
  phase: KnockoutPhase;
  sortOrder: number;
  sourceSlotCodeA: string | null;
  sourceSlotCodeB: string | null;
  winnerGoesToSlotCode: string | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialMatchDTO = {
  id: OfficialMatchId;
  matchNumber: number | null;
  matchCode: string;
  groupId: TournamentGroupId | null;
  knockoutPhase: KnockoutPhase | null;
  bracketSlotId: OfficialBracketSlotId | null;
  homeTeamId: NationalTeamId | null;
  awayTeamId: NationalTeamId | null;
  homeSlotCode: string | null;
  awaySlotCode: string | null;
  startsAt: string | null;
  stadium: string | null;
  city: string | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialThirdPlaceMatrixRuleDTO = {
  id: string;
  combinationKey: string;
  qualifiedThirdGroups: GroupLetter[];
  slotAssignments: Record<string, string>;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};
EOF

cat > lib/contracts/prediction.ts <<'EOF'
import type { GroupLetter } from "@/lib/contracts/enums";
import type { NationalTeamId, OfficialBracketSlotId } from "@/lib/contracts/officialData";
import type { UserId } from "@/lib/contracts/user";

export type GroupPredictionSelectionDTO = {
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
};

export type SaveIndividualGroupPredictionInputDTO = GroupPredictionSelectionDTO & {
  group: GroupLetter;
};

export type IndividualGroupPredictionDTO = GroupPredictionSelectionDTO & {
  id: string;
  userId: UserId;
  group: GroupLetter;
  lockedAt: string | null;
  submittedAt: string | null;
  createdAt: string;
  updatedAt: string;
};

export type SaveIndividualKnockoutPredictionInputDTO = {
  bracketSlotId: OfficialBracketSlotId;
  winnerTeamId: NationalTeamId;
};

export type IndividualKnockoutPredictionDTO = {
  id: string;
  userId: UserId;
  bracketSlotId: OfficialBracketSlotId;
  winnerTeamId: NationalTeamId;
  lockedAt: string | null;
  submittedAt: string | null;
  createdAt: string;
  updatedAt: string;
};
EOF

cat > lib/contracts/voting.ts <<'EOF'
import type {
  ConsensusDecisionType,
  GroupLetter,
  VotingSessionStatus,
  VotingSessionType
} from "@/lib/contracts/enums";
import type { NationalTeamId, OfficialBracketSlotId } from "@/lib/contracts/officialData";
import type { TeamId } from "@/lib/contracts/team";
import type { UserId } from "@/lib/contracts/user";

export type VotingSessionId = string;

export type VotingSessionDTO = {
  id: VotingSessionId;
  teamId: TeamId;
  type: VotingSessionType;
  status: VotingSessionStatus;
  group: GroupLetter | null;
  bracketSlotId: OfficialBracketSlotId | null;
  openedByUserId: UserId | null;
  closedByUserId: UserId | null;
  openedAt: string | null;
  closedAt: string | null;
  tiebreakerPayload: unknown | null;
  createdAt: string;
  updatedAt: string;
};

export type OpenGroupVotingSessionInputDTO = {
  teamId: TeamId;
  group: GroupLetter;
};

export type OpenKnockoutVotingSessionInputDTO = {
  teamId: TeamId;
  bracketSlotId: OfficialBracketSlotId;
};

export type CloseVotingSessionInputDTO = {
  teamId: TeamId;
  votingSessionId: VotingSessionId;
};

export type SubmitGroupVoteInputDTO = {
  teamId: TeamId;
  votingSessionId: VotingSessionId;
  group: GroupLetter;
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
};

export type SubmitKnockoutVoteInputDTO = {
  teamId: TeamId;
  votingSessionId: VotingSessionId;
  bracketSlotId: OfficialBracketSlotId;
  winnerTeamId: NationalTeamId;
};

export type SubmitTiebreakerInputDTO = {
  teamId: TeamId;
  votingSessionId: VotingSessionId;
  selectedTeamId: NationalTeamId;
};

export type TeamGroupConsensusDTO = {
  id: string;
  votingSessionId: VotingSessionId;
  teamId: TeamId;
  group: GroupLetter;
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
  decisionType: ConsensusDecisionType;
  decidedByUserId: UserId | null;
  decidedAt: string;
  voteSummary: unknown | null;
};

export type TeamKnockoutConsensusDTO = {
  id: string;
  votingSessionId: VotingSessionId;
  teamId: TeamId;
  bracketSlotId: OfficialBracketSlotId;
  winnerTeamId: NationalTeamId;
  decisionType: ConsensusDecisionType;
  decidedByUserId: UserId | null;
  decidedAt: string;
  voteSummary: unknown | null;
};
EOF

cat > lib/contracts/ranking.ts <<'EOF'
import type { RankingJobStatus, RankingType } from "@/lib/contracts/enums";
import type { TeamId } from "@/lib/contracts/team";
import type { UserId } from "@/lib/contracts/user";

export type RankingSnapshotId = string;

export type RankingEntryDTO = {
  id: string;
  snapshotId: RankingSnapshotId;
  rankingType: RankingType;
  userId: UserId | null;
  teamId: TeamId | null;
  participantKey: string;
  rank: number;
  score: number;
  correctPredictions: number;
  totalPredictions: number;
  metadata: unknown | null;
};

export type RankingSnapshotDTO = {
  id: RankingSnapshotId;
  type: RankingType;
  calculatedAt: string;
  sourceJobId: string | null;
  metadata: unknown | null;
  entries: RankingEntryDTO[];
};

export type RankingRecalculationJobDTO = {
  id: string;
  type: RankingType;
  status: RankingJobStatus;
  idempotencyKey: string;
  requestedByUserId: UserId | null;
  startedAt: string | null;
  finishedAt: string | null;
  errorMessage: string | null;
  metadata: unknown | null;
};

export type RequestRankingRecalculationInputDTO = {
  type: RankingType;
  idempotencyKey: string;
};
EOF

cat > lib/contracts/badge.ts <<'EOF'
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
EOF

cat > lib/contracts/admin.ts <<'EOF'
import type {
  GroupLetter,
  KnockoutPhase,
  OfficialDataStatus,
  RealResultType
} from "@/lib/contracts/enums";
import type {
  OfficialBracketSlotId,
  OfficialDataVersionId,
  OfficialMatchId
} from "@/lib/contracts/officialData";

export type RealTournamentResultDTO = {
  id: string;
  resultKey: string;
  type: RealResultType;
  group: GroupLetter | null;
  knockoutPhase: KnockoutPhase | null;
  officialMatchId: OfficialMatchId | null;
  bracketSlotId: OfficialBracketSlotId | null;
  payload: unknown;
  sourceDocumentRef: string | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type UpsertRealTournamentResultInputDTO = {
  resultKey: string;
  type: RealResultType;
  group?: GroupLetter;
  knockoutPhase?: KnockoutPhase;
  officialMatchId?: OfficialMatchId;
  bracketSlotId?: OfficialBracketSlotId;
  payload: unknown;
  sourceDocumentRef?: string;
  officialDataVersionId?: OfficialDataVersionId;
};
EOF

cat > lib/contracts/socketPayloads.ts <<'EOF'
import type {
  CloseVotingSessionInputDTO,
  OpenGroupVotingSessionInputDTO,
  OpenKnockoutVotingSessionInputDTO,
  SubmitGroupVoteInputDTO,
  SubmitKnockoutVoteInputDTO,
  SubmitTiebreakerInputDTO,
  TeamGroupConsensusDTO,
  TeamKnockoutConsensusDTO,
  VotingSessionDTO
} from "@/lib/contracts/voting";
import type { TeamId } from "@/lib/contracts/team";

export type JoinTeamSocketPayload = {
  teamId: TeamId;
};

export type OpenVotingSessionSocketPayload =
  | OpenGroupVotingSessionInputDTO
  | OpenKnockoutVotingSessionInputDTO;

export type CloseVotingSessionSocketPayload = CloseVotingSessionInputDTO;

export type SubmitGroupVoteSocketPayload = SubmitGroupVoteInputDTO;

export type SubmitKnockoutVoteSocketPayload = SubmitKnockoutVoteInputDTO;

export type SubmitTiebreakerSocketPayload = SubmitTiebreakerInputDTO;

export type VotingStatusUpdatedSocketPayload = {
  votingSession: VotingSessionDTO;
};

export type VotingClosedSocketPayload = {
  votingSession: VotingSessionDTO;
  consensus: TeamGroupConsensusDTO | TeamKnockoutConsensusDTO | null;
};

export type TiebreakerRequiredSocketPayload = {
  votingSession: VotingSessionDTO;
  options: string[];
};

export type ConsensusDefinedSocketPayload = {
  votingSession: VotingSessionDTO;
  consensus: TeamGroupConsensusDTO | TeamKnockoutConsensusDTO;
};

export type GroupVoteUpdatedSocketPayload = {
  votingSessionId: string;
  teamId: TeamId;
  group: string;
  voteSummary: unknown;
};

export type KnockoutVoteUpdatedSocketPayload = {
  votingSessionId: string;
  teamId: TeamId;
  bracketSlotId: string;
  voteSummary: unknown;
};
EOF

cat > lib/contracts/socketTypes.ts <<'EOF'
import type { ActionError } from "@/lib/contracts/actionResult";
import {
  type CloseVotingSessionSocketPayload,
  type ConsensusDefinedSocketPayload,
  type GroupVoteUpdatedSocketPayload,
  type JoinTeamSocketPayload,
  type KnockoutVoteUpdatedSocketPayload,
  type OpenVotingSessionSocketPayload,
  type SubmitGroupVoteSocketPayload,
  type SubmitKnockoutVoteSocketPayload,
  type SubmitTiebreakerSocketPayload,
  type TiebreakerRequiredSocketPayload,
  type VotingClosedSocketPayload,
  type VotingStatusUpdatedSocketPayload
} from "@/lib/contracts/socketPayloads";
import { SOCKET_EVENTS } from "@/lib/contracts/socketEvents";

export type SocketAck<TData = null> =
  | {
      ok: true;
      data: TData;
    }
  | {
      ok: false;
      error: ActionError;
    };

export interface ClientToServerEvents {
  [SOCKET_EVENTS.JOIN_TEAM]: (
    payload: JoinTeamSocketPayload,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.OPEN_VOTING_SESSION]: (
    payload: OpenVotingSessionSocketPayload,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.CLOSE_VOTING_SESSION]: (
    payload: CloseVotingSessionSocketPayload,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_GROUP_VOTE]: (
    payload: SubmitGroupVoteSocketPayload,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_KNOCKOUT_VOTE]: (
    payload: SubmitKnockoutVoteSocketPayload,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_TIEBREAKER]: (
    payload: SubmitTiebreakerSocketPayload,
    ack?: (response: SocketAck) => void
  ) => void;
}

export interface ServerToClientEvents {
  [SOCKET_EVENTS.SOCKET_ERROR]: (payload: ActionError) => void;

  [SOCKET_EVENTS.VOTING_STATUS_UPDATED]: (
    payload: VotingStatusUpdatedSocketPayload
  ) => void;

  [SOCKET_EVENTS.VOTING_CLOSED]: (payload: VotingClosedSocketPayload) => void;

  [SOCKET_EVENTS.TIEBREAKER_REQUIRED]: (
    payload: TiebreakerRequiredSocketPayload
  ) => void;

  [SOCKET_EVENTS.CONSENSUS_DEFINED]: (payload: ConsensusDefinedSocketPayload) => void;

  [SOCKET_EVENTS.GROUP_VOTE_UPDATED]: (payload: GroupVoteUpdatedSocketPayload) => void;

  [SOCKET_EVENTS.KNOCKOUT_VOTE_UPDATED]: (
    payload: KnockoutVoteUpdatedSocketPayload
  ) => void;
}

export interface InterServerEvents {
  ping: () => void;
}

export interface SocketData {
  userId?: string;
  teamId?: string;
}
EOF

cat > lib/validations/common.ts <<'EOF'
import { z } from "zod";
import { DEFAULT_PAGE, DEFAULT_PER_PAGE, MAX_PER_PAGE } from "@/lib/contracts/pagination";

export const cuidSchema = z.string().min(1, "Identificador obrigatório.");

export const nonEmptyStringSchema = z.string().trim().min(1, "Campo obrigatório.");

export const optionalTrimmedStringSchema = z.string().trim().optional();

export const nullableTrimmedStringSchema = z.string().trim().nullable();

export const isoDateStringSchema = z.string().datetime("Data inválida.");

export const birthDateSchema = z.string().date("Data de nascimento inválida.");

export const paginationParamsSchema = z.object({
  page: z.coerce.number().int().positive().default(DEFAULT_PAGE),
  perPage: z.coerce.number().int().positive().max(MAX_PER_PAGE).default(DEFAULT_PER_PAGE)
});

export const slugSchema = z
  .string()
  .trim()
  .min(3, "Slug deve ter pelo menos 3 caracteres.")
  .max(60, "Slug deve ter no máximo 60 caracteres.")
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Slug inválido.");

export const nicknameSchema = z
  .string()
  .trim()
  .min(3, "Nickname deve ter pelo menos 3 caracteres.")
  .max(30, "Nickname deve ter no máximo 30 caracteres.")
  .regex(/^[a-zA-Z0-9_]+$/, "Nickname deve conter apenas letras, números e underline.");

export const urlSchema = z.string().url("URL inválida.");
EOF

cat > lib/validations/user.ts <<'EOF'
import { z } from "zod";
import { nicknameSchema, urlSchema } from "@/lib/validations/common";

export const completeProfileSchema = z.object({
  firstName: z
    .string()
    .trim()
    .min(2, "Nome deve ter pelo menos 2 caracteres.")
    .max(80, "Nome deve ter no máximo 80 caracteres."),
  lastName: z
    .string()
    .trim()
    .min(2, "Sobrenome deve ter pelo menos 2 caracteres.")
    .max(120, "Sobrenome deve ter no máximo 120 caracteres."),
  nickname: nicknameSchema,
  birthDate: z.string().date("Data de nascimento inválida.")
});

export const updateProfileImageSchema = z.object({
  image: urlSchema
});

export type CompleteProfileInput = z.infer<typeof completeProfileSchema>;
export type UpdateProfileImageInput = z.infer<typeof updateProfileImageSchema>;
EOF

cat > lib/validations/team.ts <<'EOF'
import { z } from "zod";
import { TEAM_MEMBER_ROLE_VALUES } from "@/lib/contracts/enums";
import { cuidSchema, slugSchema } from "@/lib/validations/common";

export const createTeamSchema = z.object({
  name: z
    .string()
    .trim()
    .min(3, "Nome da equipe deve ter pelo menos 3 caracteres.")
    .max(80, "Nome da equipe deve ter no máximo 80 caracteres."),
  slug: slugSchema.optional(),
  description: z
    .string()
    .trim()
    .max(500, "Descrição deve ter no máximo 500 caracteres.")
    .optional(),
  maxMembers: z.coerce.number().int().min(2).max(100).optional()
});

export const updateTeamSchema = z.object({
  teamId: cuidSchema,
  name: z
    .string()
    .trim()
    .min(3, "Nome da equipe deve ter pelo menos 3 caracteres.")
    .max(80, "Nome da equipe deve ter no máximo 80 caracteres.")
    .optional(),
  description: z
    .string()
    .trim()
    .max(500, "Descrição deve ter no máximo 500 caracteres.")
    .nullable()
    .optional(),
  maxMembers: z.coerce.number().int().min(2).max(100).optional()
});

export const joinTeamByCodeSchema = z.object({
  inviteCode: z
    .string()
    .trim()
    .min(6, "Código de convite inválido.")
    .max(40, "Código de convite inválido.")
});

export const reviewTeamMemberSchema = z.object({
  teamId: cuidSchema,
  memberId: cuidSchema,
  approvalStatus: z.enum(["APPROVED", "REJECTED"])
});

export const changeTeamMemberRoleSchema = z.object({
  teamId: cuidSchema,
  memberId: cuidSchema,
  role: z.enum(TEAM_MEMBER_ROLE_VALUES).refine((role) => role !== "CAPTAIN", {
    message: "O papel CAPTAIN não pode ser atribuído por esta ação."
  })
});

export const removeTeamMemberSchema = z.object({
  teamId: cuidSchema,
  memberId: cuidSchema
});

export type CreateTeamInput = z.infer<typeof createTeamSchema>;
export type UpdateTeamInput = z.infer<typeof updateTeamSchema>;
export type JoinTeamByCodeInput = z.infer<typeof joinTeamByCodeSchema>;
export type ReviewTeamMemberInput = z.infer<typeof reviewTeamMemberSchema>;
export type ChangeTeamMemberRoleInput = z.infer<typeof changeTeamMemberRoleSchema>;
export type RemoveTeamMemberInput = z.infer<typeof removeTeamMemberSchema>;
EOF

cat > lib/validations/officialData.ts <<'EOF'
import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  OFFICIAL_DATA_STATUS_VALUES
} from "@/lib/contracts/enums";
import { cuidSchema } from "@/lib/validations/common";

export const groupLetterSchema = z.enum(GROUP_LETTER_VALUES);

export const knockoutPhaseSchema = z.enum(KNOCKOUT_PHASE_VALUES);

export const officialDataStatusSchema = z.enum(OFFICIAL_DATA_STATUS_VALUES);

export const nationalTeamIdSchema = cuidSchema;

export const officialBracketSlotIdSchema = cuidSchema;

export const officialMatchIdSchema = cuidSchema;

export const officialDataVersionIdSchema = cuidSchema;

export const thirdPlaceMatrixRuleSchema = z.object({
  combinationKey: z.string().trim().min(1, "Chave da combinação obrigatória."),
  qualifiedThirdGroups: z.array(groupLetterSchema).length(8),
  slotAssignments: z.record(z.string(), z.string()),
  officialDataStatus: officialDataStatusSchema
});

export type ThirdPlaceMatrixRuleInput = z.infer<typeof thirdPlaceMatrixRuleSchema>;
EOF

cat > lib/validations/prediction.ts <<'EOF'
import { z } from "zod";
import {
  groupLetterSchema,
  nationalTeamIdSchema,
  officialBracketSlotIdSchema
} from "@/lib/validations/officialData";

function hasDistinctTeams(value: {
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
  fourthPlaceTeamId: string;
}) {
  const ids = [
    value.firstPlaceTeamId,
    value.secondPlaceTeamId,
    value.thirdPlaceTeamId,
    value.fourthPlaceTeamId
  ];

  return new Set(ids).size === ids.length;
}

export const groupPredictionSelectionSchema = z
  .object({
    firstPlaceTeamId: nationalTeamIdSchema,
    secondPlaceTeamId: nationalTeamIdSchema,
    thirdPlaceTeamId: nationalTeamIdSchema,
    fourthPlaceTeamId: nationalTeamIdSchema
  })
  .refine(hasDistinctTeams, {
    message: "As quatro posições do grupo devem conter seleções diferentes."
  });

export const saveIndividualGroupPredictionSchema = groupPredictionSelectionSchema.extend({
  group: groupLetterSchema
});

export const saveIndividualKnockoutPredictionSchema = z.object({
  bracketSlotId: officialBracketSlotIdSchema,
  winnerTeamId: nationalTeamIdSchema
});

export type GroupPredictionSelectionInput = z.infer<typeof groupPredictionSelectionSchema>;

export type SaveIndividualGroupPredictionInput = z.infer<
  typeof saveIndividualGroupPredictionSchema
>;

export type SaveIndividualKnockoutPredictionInput = z.infer<
  typeof saveIndividualKnockoutPredictionSchema
>;
EOF

cat > lib/validations/voting.ts <<'EOF'
import { z } from "zod";
import { cuidSchema } from "@/lib/validations/common";
import {
  groupLetterSchema,
  nationalTeamIdSchema,
  officialBracketSlotIdSchema
} from "@/lib/validations/officialData";
import { groupPredictionSelectionSchema } from "@/lib/validations/prediction";

export const votingSessionIdSchema = cuidSchema;

export const openGroupVotingSessionSchema = z.object({
  teamId: cuidSchema,
  group: groupLetterSchema
});

export const openKnockoutVotingSessionSchema = z.object({
  teamId: cuidSchema,
  bracketSlotId: officialBracketSlotIdSchema
});

export const closeVotingSessionSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema
});

export const submitGroupVoteSchema = groupPredictionSelectionSchema.extend({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  group: groupLetterSchema
});

export const submitKnockoutVoteSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  bracketSlotId: officialBracketSlotIdSchema,
  winnerTeamId: nationalTeamIdSchema
});

export const submitTiebreakerSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  selectedTeamId: nationalTeamIdSchema
});

export type OpenGroupVotingSessionInput = z.infer<typeof openGroupVotingSessionSchema>;
export type OpenKnockoutVotingSessionInput = z.infer<typeof openKnockoutVotingSessionSchema>;
export type CloseVotingSessionInput = z.infer<typeof closeVotingSessionSchema>;
export type SubmitGroupVoteInput = z.infer<typeof submitGroupVoteSchema>;
export type SubmitKnockoutVoteInput = z.infer<typeof submitKnockoutVoteSchema>;
export type SubmitTiebreakerInput = z.infer<typeof submitTiebreakerSchema>;
EOF

cat > lib/validations/ranking.ts <<'EOF'
import { z } from "zod";
import { RANKING_TYPE_VALUES } from "@/lib/contracts/enums";

export const rankingTypeSchema = z.enum(RANKING_TYPE_VALUES);

export const requestRankingRecalculationSchema = z.object({
  type: rankingTypeSchema,
  idempotencyKey: z
    .string()
    .trim()
    .min(12, "Chave de idempotência deve ter pelo menos 12 caracteres.")
    .max(120, "Chave de idempotência deve ter no máximo 120 caracteres.")
});

export type RequestRankingRecalculationInput = z.infer<
  typeof requestRankingRecalculationSchema
>;
EOF

cat > lib/validations/badge.ts <<'EOF'
import { z } from "zod";
import { BADGE_RARITY_VALUES, BADGE_TARGET_TYPE_VALUES } from "@/lib/contracts/enums";

export const badgeCodeSchema = z
  .string()
  .trim()
  .min(3)
  .max(80)
  .regex(/^[A-Z0-9_]+$/, "Código de badge deve estar em formato SNAKE_CASE.");

export const badgeSchema = z.object({
  code: badgeCodeSchema,
  name: z.string().trim().min(3).max(80),
  description: z.string().trim().min(10).max(500),
  targetType: z.enum(BADGE_TARGET_TYPE_VALUES),
  rarity: z.enum(BADGE_RARITY_VALUES),
  iconKey: z.string().trim().min(1).max(80).optional()
});

export type BadgeInput = z.infer<typeof badgeSchema>;
EOF

cat > lib/validations/admin.ts <<'EOF'
import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  OFFICIAL_DATA_STATUS_VALUES,
  REAL_RESULT_TYPE_VALUES
} from "@/lib/contracts/enums";
import { cuidSchema } from "@/lib/validations/common";

export const upsertRealTournamentResultSchema = z.object({
  resultKey: z
    .string()
    .trim()
    .min(3, "Chave do resultado obrigatória.")
    .max(160, "Chave do resultado muito longa."),
  type: z.enum(REAL_RESULT_TYPE_VALUES),
  group: z.enum(GROUP_LETTER_VALUES).optional(),
  knockoutPhase: z.enum(KNOCKOUT_PHASE_VALUES).optional(),
  officialMatchId: cuidSchema.optional(),
  bracketSlotId: cuidSchema.optional(),
  payload: z.unknown(),
  sourceDocumentRef: z.string().trim().max(1000).optional(),
  officialDataStatus: z.enum(OFFICIAL_DATA_STATUS_VALUES).optional(),
  officialDataVersionId: cuidSchema.optional()
});

export type UpsertRealTournamentResultInput = z.infer<
  typeof upsertRealTournamentResultSchema
>;
EOF

cat > tests/contracts.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { GLOBAL_ROLE, TEAM_MEMBER_ROLE, VOTING_SESSION_STATUS } from "@/lib/contracts/enums";
import { SOCKET_EVENTS } from "@/lib/contracts/socketEvents";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { createTeamSchema } from "@/lib/validations/team";
import { saveIndividualGroupPredictionSchema } from "@/lib/validations/prediction";
import { submitGroupVoteSchema } from "@/lib/validations/voting";

describe("contracts", () => {
  it("deve manter enums canônicos estáveis", () => {
    expect(GLOBAL_ROLE.ADMIN_GLOBAL).toBe("ADMIN_GLOBAL");
    expect(TEAM_MEMBER_ROLE.CAPTAIN).toBe("CAPTAIN");
    expect(VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED).toBe("TIEBREAKER_REQUIRED");
  });

  it("deve manter eventos Socket.io em snake_case", () => {
    expect(SOCKET_EVENTS.SUBMIT_GROUP_VOTE).toBe("submit_group_vote");
    expect(SOCKET_EVENTS.SUBMIT_TIEBREAKER).toBe("submit_tiebreaker");
    expect(SOCKET_EVENTS.CONSENSUS_DEFINED).toBe("consensus_defined");
  });

  it("deve manter rotas principais canônicas", () => {
    expect(APP_ROUTES.DASHBOARD).toBe("/dashboard");
    expect(APP_ROUTES.RANKING_INDIVIDUAL).toBe("/ranking/individual");
    expect(APP_ROUTES.ADMIN_RESULTS).toBe("/admin/resultados");
  });

  it("deve validar criação básica de equipe", () => {
    const result = createTeamSchema.safeParse({
      name: "Minha Equipe",
      slug: "minha-equipe",
      maxMembers: 20
    });

    expect(result.success).toBe(true);
  });

  it("deve rejeitar previsão de grupo com seleções duplicadas", () => {
    const result = saveIndividualGroupPredictionSchema.safeParse({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_1",
      thirdPlaceTeamId: "team_3",
      fourthPlaceTeamId: "team_4"
    });

    expect(result.success).toBe(false);
  });

  it("deve validar payload de voto de grupo", () => {
    const result = submitGroupVoteSchema.safeParse({
      teamId: "team_1",
      votingSessionId: "session_1",
      group: "B",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_2",
      thirdPlaceTeamId: "team_3",
      fourthPlaceTeamId: "team_4"
    });

    expect(result.success).toBe(true);
  });
});
EOF

echo "==> Arquivos do Bloco 2 criados/atualizados."
echo "==> Agora rode:"
echo "    npm run lint"
echo "    npm run test"
echo "    npm run db:generate"
echo "    npm run db:seed"
