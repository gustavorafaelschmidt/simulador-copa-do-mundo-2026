/*
  Regra do projeto:
  Todo evento Socket.io deve ser declarado aqui e importado pelos clientes/servidores.
  Não escrever nomes de eventos manualmente em handlers, components ou services.
*/
export const SOCKET_EVENTS = {
  CONNECTION: "connection",
  DISCONNECT: "disconnect",

  SOCKET_ERROR: "socket_error",

  TEAM_VOTING_OPENED: "team_voting_opened",
  TEAM_VOTING_CLOSED: "team_voting_closed",
  TEAM_VOTE_SUBMITTED: "team_vote_submitted",
  TEAM_VOTES_UPDATED: "team_votes_updated",
  TEAM_TIEBREAK_APPLIED: "team_tiebreak_applied"
} as const;

export type SocketEventName = (typeof SOCKET_EVENTS)[keyof typeof SOCKET_EVENTS];