import type { ActionError, ActionResult } from "@/lib/contracts/actionResult";
import type { AppErrorDetails } from "@/lib/errors/AppError";
import { AppError, toAppError } from "@/lib/errors/AppError";

export function success<TData>(data: TData, message?: string): ActionResult<TData> {
  return {
    ok: true,
    data,
    ...(message ? { message } : {})
  };
}

export function error(input: unknown): ActionResult {
  const appError = toAppError(input);

  return {
    ok: false,
    error: {
      code: appError.code,
      message: appError.message,
      statusCode: appError.statusCode,
      ...(appError.details !== undefined ? { details: appError.details } : {})
    }
  };
}

export function validationError(
  message = "Dados inválidos.",
  details?: AppErrorDetails
): ActionResult {
  return buildActionError({
    code: "VALIDATION_ERROR",
    message,
    statusCode: 422,
    details
  });
}

export function unauthorized(message = "Autenticação obrigatória."): ActionResult {
  return buildActionError({
    code: "UNAUTHORIZED",
    message,
    statusCode: 401
  });
}

export function forbidden(message = "Você não tem permissão para executar esta ação."): ActionResult {
  return buildActionError({
    code: "FORBIDDEN",
    message,
    statusCode: 403
  });
}

function buildActionError(actionError: ActionError): ActionResult {
  return {
    ok: false,
    error: {
      code: actionError.code,
      message: actionError.message,
      statusCode: actionError.statusCode,
      ...(actionError.details !== undefined ? { details: actionError.details } : {})
    }
  };
}

export function throwAppError(params: ConstructorParameters<typeof AppError>[0]): never {
  throw new AppError(params);
}