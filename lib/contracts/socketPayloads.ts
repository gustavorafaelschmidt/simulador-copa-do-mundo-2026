import type {
  CloseVotingSessionInputDTO,
  OpenGroupVotingSessionInputDTO,
  OpenKnockoutVotingSessionInputDTO,
  SubmitAnyTiebreakerInputDTO,
  SubmitGroupVoteInputDTO,
  SubmitKnockoutVoteInputDTO,
  TeamGroupConsensusDTO,
  TeamKnockoutConsensusDTO,
  VotingSessionDTO
} from "./voting.ts";
import type { TeamId } from "./team.ts";

export type JoinTeamSocketPayload = {
  teamId: TeamId;
};

export type OpenVotingSessionSocketPayload =
  | OpenGroupVotingSessionInputDTO
  | OpenKnockoutVotingSessionInputDTO;

export type CloseVotingSessionSocketPayload = CloseVotingSessionInputDTO;

export type SubmitGroupVoteSocketPayload = SubmitGroupVoteInputDTO;

export type SubmitKnockoutVoteSocketPayload = SubmitKnockoutVoteInputDTO;

export type SubmitTiebreakerSocketPayload = SubmitAnyTiebreakerInputDTO;

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
