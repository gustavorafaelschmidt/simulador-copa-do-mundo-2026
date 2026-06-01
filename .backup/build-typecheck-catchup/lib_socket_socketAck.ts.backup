import type { ActionError } from "../contracts/actionResult.ts";
import { AppError } from "../errors/AppError.ts";

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
