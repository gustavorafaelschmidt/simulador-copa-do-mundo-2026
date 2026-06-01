import type { IncomingMessage } from "node:http";
import { getToken } from "next-auth/jwt";
import { prisma } from "../db/prisma.ts";
import { AppError } from "../errors/AppError.ts";

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
