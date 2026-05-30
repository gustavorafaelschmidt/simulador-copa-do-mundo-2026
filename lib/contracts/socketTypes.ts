import type { ActionError } from "@/lib/contracts/actionResult";
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
  [SOCKET_EVENTS.JOIN_TEAM]: (payload: unknown, ack?: (response: SocketAck) => void) => void;

  [SOCKET_EVENTS.OPEN_VOTING_SESSION]: (
    payload: unknown,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.CLOSE_VOTING_SESSION]: (
    payload: unknown,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_GROUP_VOTE]: (
    payload: unknown,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_KNOCKOUT_VOTE]: (
    payload: unknown,
    ack?: (response: SocketAck) => void
  ) => void;

  [SOCKET_EVENTS.SUBMIT_TIEBREAKER]: (
    payload: unknown,
    ack?: (response: SocketAck) => void
  ) => void;
}

export interface ServerToClientEvents {
  [SOCKET_EVENTS.SOCKET_ERROR]: (payload: ActionError) => void;
  [SOCKET_EVENTS.VOTING_STATUS_UPDATED]: (payload: unknown) => void;
  [SOCKET_EVENTS.VOTING_CLOSED]: (payload: unknown) => void;
  [SOCKET_EVENTS.TIEBREAKER_REQUIRED]: (payload: unknown) => void;
  [SOCKET_EVENTS.CONSENSUS_DEFINED]: (payload: unknown) => void;
  [SOCKET_EVENTS.GROUP_VOTE_UPDATED]: (payload: unknown) => void;
  [SOCKET_EVENTS.KNOCKOUT_VOTE_UPDATED]: (payload: unknown) => void;
}

export interface InterServerEvents {
  ping: () => void;
}

export interface SocketData {
  userId?: string;
  teamId?: string;
}