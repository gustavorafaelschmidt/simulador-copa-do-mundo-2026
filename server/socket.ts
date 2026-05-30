import "dotenv/config";
import http from "node:http";
import express from "express";
import { Server } from "socket.io";
import { SOCKET_EVENTS } from "../lib/contracts/socketEvents";
import type {
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
  SocketData
} from "../lib/contracts/socketTypes";
import { logger } from "../lib/logger/index";

const app = express();
const server = http.createServer(app);

const port = Number(process.env.SOCKET_PORT ?? 4001);
const webOrigin = process.env.NEXTAUTH_URL ?? "http://localhost:3000";

const io = new Server<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>(server, {
  cors: {
    origin: webOrigin,
    credentials: true
  }
});

app.get("/health", (_request, response) => {
  response.status(200).json({
    ok: true,
    service: "socket",
    timestamp: new Date().toISOString()
  });
});

io.on(SOCKET_EVENTS.CONNECTION, (socket) => {
  logger.info("Socket conectado.", {
    socketId: socket.id
  });

  /*
    Blocos futuros:
    - validar sessão antes de entrar em rooms;
    - importar services de team/consensus;
    - nunca duplicar regra de consenso aqui;
    - usar apenas eventos declarados em SOCKET_EVENTS.
  */

  socket.on(SOCKET_EVENTS.DISCONNECT, (reason) => {
    logger.info("Socket desconectado.", {
      socketId: socket.id,
      reason
    });
  });
});

server.listen(port, () => {
  logger.info("Servidor Socket.io iniciado.", {
    port,
    webOrigin
  });
});