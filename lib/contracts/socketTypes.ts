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

/*
  Bloco 0:
  Tipos mínimos para inicializar o servidor Socket.io.
  Payloads definitivos de votação serão criados após os contracts de equipes,
  grupos, previsões, consenso e dados oficiais.
*/
export interface ClientToServerEvents {
  [SOCKET_EVENTS.TEAM_VOTE_SUBMITTED]: (
    payload: unknown,
    ack?: (response: SocketAck) => void
  ) => void;
}

export interface ServerToClientEvents {
  [SOCKET_EVENTS.SOCKET_ERROR]: (payload: ActionError) => void;
  [SOCKET_EVENTS.TEAM_VOTES_UPDATED]: (payload: unknown) => void;
  [SOCKET_EVENTS.TEAM_VOTING_OPENED]: (payload: unknown) => void;
  [SOCKET_EVENTS.TEAM_VOTING_CLOSED]: (payload: unknown) => void;
  [SOCKET_EVENTS.TEAM_TIEBREAK_APPLIED]: (payload: unknown) => void;
}

export interface InterServerEvents {
  ping: () => void;
}

export interface SocketData {
  userId?: string;
  teamId?: string;
}