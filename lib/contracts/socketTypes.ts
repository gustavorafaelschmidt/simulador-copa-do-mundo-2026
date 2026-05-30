import type { ActionError } from "./actionResult.ts";
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
} from "./socketPayloads.ts";
import type { VotingSessionDTO } from "./voting.ts";
import { SOCKET_EVENTS } from "./socketEvents.ts";

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
    ack?: (response: SocketAck<{ teamId: string }>) => void
  ) => void;

  [SOCKET_EVENTS.OPEN_VOTING_SESSION]: (
    payload: OpenVotingSessionSocketPayload,
    ack?: (response: SocketAck<{ votingSession: VotingSessionDTO }>) => void
  ) => void;

  [SOCKET_EVENTS.CLOSE_VOTING_SESSION]: (
    payload: CloseVotingSessionSocketPayload,
    ack?: (response: SocketAck<{ votingSession: VotingSessionDTO }>) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_GROUP_VOTE]: (
    payload: SubmitGroupVoteSocketPayload,
    ack?: (response: SocketAck<{ voteId: string }>) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_KNOCKOUT_VOTE]: (
    payload: SubmitKnockoutVoteSocketPayload,
    ack?: (response: SocketAck<{ voteId: string }>) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_TIEBREAKER]: (
    payload: SubmitTiebreakerSocketPayload,
    ack?: (response: SocketAck<{ votingSession: VotingSessionDTO }>) => void
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
