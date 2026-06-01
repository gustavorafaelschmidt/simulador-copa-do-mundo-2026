import type { ActionError, ActionResult } from "../contracts/actionResult.ts";
import { AppError } from "./AppError.ts";

function toActionError(error: unknown): ActionError {
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
      code: "INTERNAL_ERROR",
      message: error.message,
      statusCode: 500
    };
  }

  return {
    code: "INTERNAL_ERROR",
    message: "Erro interno inesperado.",
    statusCode: 500
  };
}

export function success<TData>(data: TData, message?: string): ActionResult<TData> {
  return {
    ok: true,
    data,
    ...(message ? { message } : {})
  };
}

export function error<TData = never>(errorInput: unknown): ActionResult<TData> {
  return {
    ok: false,
    error: toActionError(errorInput)
  };
}

export function validationError<TData = never>(
  message = "Dados inválidos.",
  details?: unknown
): ActionResult<TData> {
  return {
    ok: false,
    error: {
      code: "VALIDATION_ERROR",
      message,
      statusCode: 422,
      details: details as ActionError["details"]
    }
  };
}

export function unauthorized<TData = never>(
  message = "Autenticação obrigatória."
): ActionResult<TData> {
  return {
    ok: false,
    error: {
      code: "UNAUTHORIZED",
      message,
      statusCode: 401
    }
  };
}

export function forbidden<TData = never>(
  message = "Você não tem permissão para executar esta ação."
): ActionResult<TData> {
  return {
    ok: false,
    error: {
      code: "FORBIDDEN",
      message,
      statusCode: 403
    }
  };
}
