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
