#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 7 — servidor Socket.io e handlers em tempo real..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p lib/socket
mkdir -p lib/validations
mkdir -p server
mkdir -p docs
mkdir -p tests

cat > lib/contracts/voting.ts <<'EOF'
import type {
  ConsensusDecisionType,
  GroupLetter,
  VotingSessionStatus,
  VotingSessionType
} from "@/lib/contracts/enums";
import type {
  NationalTeamId,
  OfficialBracketSlotId
} from "@/lib/contracts/officialData";
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

export type SubmitKnockoutTiebreakerInputDTO = {
  teamId: TeamId;
  votingSessionId: VotingSessionId;
  selectedTeamId: NationalTeamId;
};

export type SubmitGroupTiebreakerInputDTO = {
  teamId: TeamId;
  votingSessionId: VotingSessionId;
  group: GroupLetter;
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
};

export type SubmitTiebreakerInputDTO = SubmitKnockoutTiebreakerInputDTO;

export type SubmitAnyTiebreakerInputDTO =
  | SubmitGroupTiebreakerInputDTO
  | SubmitKnockoutTiebreakerInputDTO;

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

cat > lib/contracts/socketPayloads.ts <<'EOF'
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
import type { VotingSessionDTO } from "@/lib/contracts/voting";
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

export const openVotingSessionSchema = z.union([
  openGroupVotingSessionSchema,
  openKnockoutVotingSessionSchema
]);

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

export const submitKnockoutTiebreakerSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  selectedTeamId: nationalTeamIdSchema
});

export const submitGroupTiebreakerSchema = groupPredictionSelectionSchema.extend({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  group: groupLetterSchema
});

export const submitTiebreakerSchema = submitKnockoutTiebreakerSchema;

export const submitAnyTiebreakerSchema = z.union([
  submitGroupTiebreakerSchema,
  submitKnockoutTiebreakerSchema
]);

export type OpenGroupVotingSessionInput = z.infer<typeof openGroupVotingSessionSchema>;
export type OpenKnockoutVotingSessionInput = z.infer<typeof openKnockoutVotingSessionSchema>;
export type CloseVotingSessionInput = z.infer<typeof closeVotingSessionSchema>;
export type SubmitGroupVoteInput = z.infer<typeof submitGroupVoteSchema>;
export type SubmitKnockoutVoteInput = z.infer<typeof submitKnockoutVoteSchema>;
export type SubmitKnockoutTiebreakerInput = z.infer<typeof submitKnockoutTiebreakerSchema>;
export type SubmitGroupTiebreakerInput = z.infer<typeof submitGroupTiebreakerSchema>;
export type SubmitTiebreakerInput = z.infer<typeof submitTiebreakerSchema>;
export type SubmitAnyTiebreakerInput = z.infer<typeof submitAnyTiebreakerSchema>;
EOF

cat > lib/validations/socket.ts <<'EOF'
import { z } from "zod";
import { cuidSchema } from "@/lib/validations/common";

export const joinTeamSocketSchema = z.object({
  teamId: cuidSchema
});

export type JoinTeamSocketInput = z.infer<typeof joinTeamSocketSchema>;
EOF

cat > lib/socket/rooms.ts <<'EOF'
export function getTeamRoomName(teamId: string): string {
  return `team:${teamId}`;
}

export function getVotingSessionRoomName(votingSessionId: string): string {
  return `voting_session:${votingSessionId}`;
}
EOF

cat > lib/socket/socketAck.ts <<'EOF'
import type { ActionError } from "@/lib/contracts/actionResult";
import { AppError } from "@/lib/errors/AppError";

export function toSocketActionError(error: unknown): ActionError {
  if (error instanceof AppError) {
    return {
      code: error.code,
      message: error.message,
      statusCode: error.statusCode,
      details: error.details
    };
  }

  if (error instanceof Error) {
    return {
      code: "INTERNAL_SERVER_ERROR",
      message: error.message,
      statusCode: 500
    };
  }

  return {
    code: "INTERNAL_SERVER_ERROR",
    message: "Erro interno inesperado no servidor Socket.io.",
    statusCode: 500
  };
}

export function ackSuccess<TData>(data: TData) {
  return {
    ok: true,
    data
  } as const;
}

export function ackError(error: unknown) {
  return {
    ok: false,
    error: toSocketActionError(error)
  } as const;
}
EOF

cat > lib/socket/socketAuth.ts <<'EOF'
import type { IncomingMessage } from "node:http";
import { getToken } from "next-auth/jwt";
import { prisma } from "@/lib/db/prisma";
import { AppError } from "@/lib/errors/AppError";

type RequestForGetToken = Parameters<typeof getToken>[0]["req"];

export type AuthenticatedSocketUser = {
  userId: string;
};

export async function authenticateSocketRequest(
  req: IncomingMessage
): Promise<AuthenticatedSocketUser> {
  const secret = process.env.AUTH_SECRET ?? process.env.NEXTAUTH_SECRET;

  if (!secret) {
    throw new AppError({
      code: "CONFIGURATION_ERROR",
      message: "AUTH_SECRET ou NEXTAUTH_SECRET precisa estar configurado para autenticar Socket.io.",
      statusCode: 500
    });
  }

  const token = await getToken({
    req: req as RequestForGetToken,
    secret
  });

  const tokenUserId =
    typeof token?.userId === "string"
      ? token.userId
      : typeof token?.sub === "string"
        ? token.sub
        : null;

  if (!tokenUserId) {
    throw new AppError({
      code: "UNAUTHORIZED",
      message: "Sessão inválida ou ausente no Socket.io.",
      statusCode: 401
    });
  }

  const user = await prisma.user.findUnique({
    where: {
      id: tokenUserId
    },
    select: {
      id: true
    }
  });

  if (!user) {
    throw new AppError({
      code: "UNAUTHORIZED",
      message: "Usuário da sessão Socket.io não encontrado.",
      statusCode: 401
    });
  }

  return {
    userId: user.id
  };
}
EOF

cat > lib/socket/votingSessionMapper.ts <<'EOF'
import type { VotingSessionDTO } from "@/lib/contracts/voting";

type VotingSessionLike = {
  id: string;
  teamId: string;
  type: VotingSessionDTO["type"];
  status: VotingSessionDTO["status"];
  group: VotingSessionDTO["group"];
  bracketSlotId: string | null;
  openedByUserId: string | null;
  closedByUserId: string | null;
  openedAt: Date | null;
  closedAt: Date | null;
  tiebreakerPayload: unknown | null;
  createdAt: Date;
  updatedAt: Date;
};

export function toVotingSessionDTO(votingSession: VotingSessionLike): VotingSessionDTO {
  return {
    id: votingSession.id,
    teamId: votingSession.teamId,
    type: votingSession.type,
    status: votingSession.status,
    group: votingSession.group,
    bracketSlotId: votingSession.bracketSlotId,
    openedByUserId: votingSession.openedByUserId,
    closedByUserId: votingSession.closedByUserId,
    openedAt: votingSession.openedAt?.toISOString() ?? null,
    closedAt: votingSession.closedAt?.toISOString() ?? null,
    tiebreakerPayload: votingSession.tiebreakerPayload,
    createdAt: votingSession.createdAt.toISOString(),
    updatedAt: votingSession.updatedAt.toISOString()
  };
}
EOF

cat > server/socket.ts <<'EOF'
import { createServer } from "node:http";
import express from "express";
import { loadEnvConfig } from "@next/env";
import { Server } from "socket.io";
import { SOCKET_EVENTS } from "@/lib/contracts/socketEvents";
import type {
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
  SocketData
} from "@/lib/contracts/socketTypes";
import { VOTING_SESSION_STATUS } from "@/lib/contracts/enums";
import { logger } from "@/lib/logger";
import { ackError, ackSuccess, toSocketActionError } from "@/lib/socket/socketAck";
import { authenticateSocketRequest } from "@/lib/socket/socketAuth";
import { getTeamRoomName, getVotingSessionRoomName } from "@/lib/socket/rooms";
import { toVotingSessionDTO } from "@/lib/socket/votingSessionMapper";
import { joinTeamSocketSchema } from "@/lib/validations/socket";
import {
  closeVotingSessionSchema,
  openGroupVotingSessionSchema,
  openKnockoutVotingSessionSchema,
  submitAnyTiebreakerSchema,
  submitGroupVoteSchema,
  submitKnockoutVoteSchema
} from "@/lib/validations/voting";
import { assertApprovedTeamMember } from "@/services/team/teamService";
import {
  applyCaptainGroupTiebreaker,
  applyCaptainKnockoutTiebreaker,
  closeVotingSession,
  openGroupVotingSession,
  openKnockoutVotingSession,
  submitGroupVote,
  submitKnockoutVote
} from "@/services/consensus/consensusService";

loadEnvConfig(process.cwd());

const socketPort = Number(process.env.SOCKET_PORT ?? 4001);
const webOrigin = process.env.NEXTAUTH_URL ?? "http://localhost:3000";

const app = express();

app.get("/health", (_request, response) => {
  response.status(200).json({
    ok: true,
    service: "socket",
    timestamp: new Date().toISOString()
  });
});

const httpServer = createServer(app);

const io = new Server<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>(httpServer, {
  cors: {
    origin: webOrigin,
    credentials: true
  }
});

function requireSocketUserId(socket: { data: SocketData }): string {
  if (!socket.data.userId) {
    throw new Error("Socket sem usuário autenticado.");
  }

  return socket.data.userId;
}

io.use((socket, next) => {
  void (async () => {
    try {
      const authenticatedUser = await authenticateSocketRequest(socket.request);
      socket.data.userId = authenticatedUser.userId;
      next();
    } catch (error) {
      logger.warn("Falha de autenticação Socket.io.", {
        error: toSocketActionError(error)
      });

      next(new Error("UNAUTHORIZED"));
    }
  })();
});

io.on("connection", (socket) => {
  logger.info("Cliente Socket.io conectado.", {
    socketId: socket.id,
    userId: socket.data.userId
  });

  socket.on(SOCKET_EVENTS.JOIN_TEAM, (payload, ack) => {
    void (async () => {
      try {
        const userId = requireSocketUserId(socket);
        const input = joinTeamSocketSchema.parse(payload);

        await assertApprovedTeamMember(input.teamId, userId);

        socket.join(getTeamRoomName(input.teamId));
        socket.data.teamId = input.teamId;

        ack?.(ackSuccess({ teamId: input.teamId }));
      } catch (error) {
        ack?.(ackError(error));
        socket.emit(SOCKET_EVENTS.SOCKET_ERROR, toSocketActionError(error));
      }
    })();
  });

  socket.on(SOCKET_EVENTS.OPEN_VOTING_SESSION, (payload, ack) => {
    void (async () => {
      try {
        const userId = requireSocketUserId(socket);
        const votingSession =
          "group" in payload
            ? await openGroupVotingSession(
                userId,
                openGroupVotingSessionSchema.parse(payload)
              )
            : await openKnockoutVotingSession(
                userId,
                openKnockoutVotingSessionSchema.parse(payload)
              );

        const votingSessionDTO = toVotingSessionDTO(votingSession);
        const teamRoom = getTeamRoomName(votingSession.teamId);
        const votingRoom = getVotingSessionRoomName(votingSession.id);

        socket.join(teamRoom);
        socket.join(votingRoom);

        io.to(teamRoom).emit(SOCKET_EVENTS.VOTING_STATUS_UPDATED, {
          votingSession: votingSessionDTO
        });

        ack?.(ackSuccess({ votingSession: votingSessionDTO }));
      } catch (error) {
        ack?.(ackError(error));
        socket.emit(SOCKET_EVENTS.SOCKET_ERROR, toSocketActionError(error));
      }
    })();
  });

  socket.on(SOCKET_EVENTS.SUBMIT_GROUP_VOTE, (payload, ack) => {
    void (async () => {
      try {
        const userId = requireSocketUserId(socket);
        const input = submitGroupVoteSchema.parse(payload);
        const vote = await submitGroupVote(userId, input);

        io.to(getTeamRoomName(input.teamId)).emit(SOCKET_EVENTS.GROUP_VOTE_UPDATED, {
          votingSessionId: input.votingSessionId,
          teamId: input.teamId,
          group: input.group,
          voteSummary: null
        });

        ack?.(ackSuccess({ voteId: vote.id }));
      } catch (error) {
        ack?.(ackError(error));
        socket.emit(SOCKET_EVENTS.SOCKET_ERROR, toSocketActionError(error));
      }
    })();
  });

  socket.on(SOCKET_EVENTS.SUBMIT_KNOCKOUT_VOTE, (payload, ack) => {
    void (async () => {
      try {
        const userId = requireSocketUserId(socket);
        const input = submitKnockoutVoteSchema.parse(payload);
        const vote = await submitKnockoutVote(userId, input);

        io.to(getTeamRoomName(input.teamId)).emit(SOCKET_EVENTS.KNOCKOUT_VOTE_UPDATED, {
          votingSessionId: input.votingSessionId,
          teamId: input.teamId,
          bracketSlotId: input.bracketSlotId,
          voteSummary: null
        });

        ack?.(ackSuccess({ voteId: vote.id }));
      } catch (error) {
        ack?.(ackError(error));
        socket.emit(SOCKET_EVENTS.SOCKET_ERROR, toSocketActionError(error));
      }
    })();
  });

  socket.on(SOCKET_EVENTS.CLOSE_VOTING_SESSION, (payload, ack) => {
    void (async () => {
      try {
        const userId = requireSocketUserId(socket);
        const input = closeVotingSessionSchema.parse(payload);
        const votingSession = await closeVotingSession(userId, input);
        const votingSessionDTO = toVotingSessionDTO(votingSession);
        const teamRoom = getTeamRoomName(input.teamId);

        io.to(teamRoom).emit(SOCKET_EVENTS.VOTING_STATUS_UPDATED, {
          votingSession: votingSessionDTO
        });

        if (votingSession.status === VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED) {
          io.to(teamRoom).emit(SOCKET_EVENTS.TIEBREAKER_REQUIRED, {
            votingSession: votingSessionDTO,
            options: []
          });
        }

        if (votingSession.status === VOTING_SESSION_STATUS.CLOSED) {
          io.to(teamRoom).emit(SOCKET_EVENTS.VOTING_CLOSED, {
            votingSession: votingSessionDTO,
            consensus: null
          });
        }

        ack?.(ackSuccess({ votingSession: votingSessionDTO }));
      } catch (error) {
        ack?.(ackError(error));
        socket.emit(SOCKET_EVENTS.SOCKET_ERROR, toSocketActionError(error));
      }
    })();
  });

  socket.on(SOCKET_EVENTS.SUBMIT_TIEBREAKER, (payload, ack) => {
    void (async () => {
      try {
        const userId = requireSocketUserId(socket);
        const input = submitAnyTiebreakerSchema.parse(payload);
        const votingSession =
          "group" in input
            ? await applyCaptainGroupTiebreaker(userId, input)
            : await applyCaptainKnockoutTiebreaker(userId, input);

        const votingSessionDTO = toVotingSessionDTO(votingSession);

        io.to(getTeamRoomName(input.teamId)).emit(SOCKET_EVENTS.VOTING_CLOSED, {
          votingSession: votingSessionDTO,
          consensus: null
        });

        io.to(getTeamRoomName(input.teamId)).emit(SOCKET_EVENTS.VOTING_STATUS_UPDATED, {
          votingSession: votingSessionDTO
        });

        ack?.(ackSuccess({ votingSession: votingSessionDTO }));
      } catch (error) {
        ack?.(ackError(error));
        socket.emit(SOCKET_EVENTS.SOCKET_ERROR, toSocketActionError(error));
      }
    })();
  });

  socket.on("disconnect", (reason) => {
    logger.info("Cliente Socket.io desconectado.", {
      socketId: socket.id,
      userId: socket.data.userId,
      reason
    });
  });
});

httpServer.listen(socketPort, () => {
  logger.info("Servidor Socket.io iniciado.", {
    port: socketPort,
    webOrigin
  });
});
EOF

cat > docs/socket.md <<'EOF'
# Bloco 7 — Socket.io

## Objetivo

Conectar o servidor Socket.io aos services centralizados de consenso.

## Regra arquitetural

Handlers Socket.io não implementam regra de negócio sensível.

Eles apenas:

1. autenticam a conexão;
2. validam payloads com Zod;
3. chamam services;
4. emitem eventos para rooms;
5. retornam ACK padronizado.

## Autenticação

O servidor Socket.io lê o token Auth.js/NextAuth por cookie usando `getToken`.

## Rooms

- `team:{teamId}`
- `voting_session:{votingSessionId}`

## Eventos de entrada

Os nomes continuam centralizados em:

```txt
lib/contracts/socketEvents.ts
```

## Eventos de saída

- `voting_status_updated`
- `group_vote_updated`
- `knockout_vote_updated`
- `tiebreaker_required`
- `voting_closed`
- `socket_error`

## Pontos futuros

- O front ainda precisa de client Socket.io.
- O resumo de votos em tempo real ainda está como `null`.
- O evento `consensus_defined` será usado quando o service retornar o consenso serializado.
EOF

cat > tests/socket.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { VOTING_SESSION_STATUS, VOTING_SESSION_TYPE } from "@/lib/contracts/enums";
import { ackError, ackSuccess } from "@/lib/socket/socketAck";
import { getTeamRoomName, getVotingSessionRoomName } from "@/lib/socket/rooms";
import { toVotingSessionDTO } from "@/lib/socket/votingSessionMapper";
import { joinTeamSocketSchema } from "@/lib/validations/socket";
import { submitAnyTiebreakerSchema } from "@/lib/validations/voting";

describe("socket foundation", () => {
  it("deve gerar nomes de rooms canônicos", () => {
    expect(getTeamRoomName("team_1")).toBe("team:team_1");
    expect(getVotingSessionRoomName("vote_1")).toBe("voting_session:vote_1");
  });

  it("deve validar payload de join team", () => {
    expect(
      joinTeamSocketSchema.safeParse({
        teamId: "team_1"
      }).success
    ).toBe(true);
  });

  it("deve validar voto de minerva de grupo", () => {
    expect(
      submitAnyTiebreakerSchema.safeParse({
        teamId: "team_1",
        votingSessionId: "session_1",
        group: "A",
        firstPlaceTeamId: "BRA",
        secondPlaceTeamId: "ARG",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      }).success
    ).toBe(true);
  });

  it("deve validar voto de minerva de mata-mata", () => {
    expect(
      submitAnyTiebreakerSchema.safeParse({
        teamId: "team_1",
        votingSessionId: "session_1",
        selectedTeamId: "BRA"
      }).success
    ).toBe(true);
  });

  it("deve montar ack de sucesso", () => {
    expect(ackSuccess({ ok: true })).toEqual({
      ok: true,
      data: {
        ok: true
      }
    });
  });

  it("deve montar ack de erro", () => {
    expect(ackError(new Error("Falha"))).toMatchObject({
      ok: false,
      error: {
        code: "INTERNAL_SERVER_ERROR",
        message: "Falha",
        statusCode: 500
      }
    });
  });

  it("deve serializar sessão de votação para DTO", () => {
    const now = new Date("2026-01-01T00:00:00.000Z");

    expect(
      toVotingSessionDTO({
        id: "session_1",
        teamId: "team_1",
        type: VOTING_SESSION_TYPE.GROUP_STAGE,
        status: VOTING_SESSION_STATUS.OPEN,
        group: "A",
        bracketSlotId: null,
        openedByUserId: "user_1",
        closedByUserId: null,
        openedAt: now,
        closedAt: null,
        tiebreakerPayload: null,
        createdAt: now,
        updatedAt: now
      })
    ).toEqual({
      id: "session_1",
      teamId: "team_1",
      type: "GROUP_STAGE",
      status: "OPEN",
      group: "A",
      bracketSlotId: null,
      openedByUserId: "user_1",
      closedByUserId: null,
      openedAt: "2026-01-01T00:00:00.000Z",
      closedAt: null,
      tiebreakerPayload: null,
      createdAt: "2026-01-01T00:00:00.000Z",
      updatedAt: "2026-01-01T00:00:00.000Z"
    });
  });
});
EOF

echo "==> Bloco 7 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run socket:dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add socket realtime handlers\""
echo "  git push"
