export type AppErrorDetails = Record<string, unknown> | Array<Record<string, unknown>> | string;

export type AppErrorCode =
  | "INTERNAL_ERROR"
  | "VALIDATION_ERROR"
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "OFFICIAL_DATA_UNAVAILABLE"
  | "BUSINESS_RULE_VIOLATION";

type AppErrorParams = {
  code: AppErrorCode;
  message: string;
  statusCode: number;
  details?: AppErrorDetails;
};

export class AppError extends Error {
  public readonly code: AppErrorCode;
  public readonly statusCode: number;
  public readonly details?: AppErrorDetails;
  public readonly isOperational = true;

  constructor(params: AppErrorParams) {
    super(params.message);

    this.name = "AppError";
    this.code = params.code;
    this.statusCode = params.statusCode;

    if (params.details !== undefined) {
      this.details = params.details;
    }

    Error.captureStackTrace?.(this, AppError);
  }
}

export function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}

export function toAppError(error: unknown): AppError {
  if (isAppError(error)) {
    return error;
  }

  return new AppError({
    code: "INTERNAL_ERROR",
    message: "Erro interno inesperado.",
    statusCode: 500
  });
}