/*
  Eventos Socket.io canônicos.

  Regra do projeto:
  - todos os nomes de eventos ficam exclusivamente neste arquivo;
  - handlers não podem escrever strings manualmente;
  - Socket.io apenas orquestra services centralizados;
  - regra de consenso nunca deve ser duplicada nos handlers.
*/

export const SOCKET_EVENTS = {
  CONNECTION: "connection",
  DISCONNECT: "disconnect",

  JOIN_TEAM: "join_team",

  OPEN_VOTING_SESSION: "open_voting_session",
  CLOSE_VOTING_SESSION: "close_voting_session",

  SUBMIT_GROUP_VOTE: "submit_group_vote",
  SUBMIT_KNOCKOUT_VOTE: "submit_knockout_vote",
  SUBMIT_TIEBREAKER: "submit_tiebreaker",

  VOTING_STATUS_UPDATED: "voting_status_updated",
  VOTING_CLOSED: "voting_closed",
  TIEBREAKER_REQUIRED: "tiebreaker_required",
  CONSENSUS_DEFINED: "consensus_defined",

  GROUP_VOTE_UPDATED: "group_vote_updated",
  KNOCKOUT_VOTE_UPDATED: "knockout_vote_updated",

  SOCKET_ERROR: "socket_error"
} as const;

export type SocketEventName = (typeof SOCKET_EVENTS)[keyof typeof SOCKET_EVENTS];