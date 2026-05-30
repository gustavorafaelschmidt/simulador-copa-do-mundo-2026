import type { AppErrorCode, AppErrorDetails } from "@/lib/errors/AppError";

export type ActionError = {
  code: AppErrorCode;
  message: string;
  statusCode: number;
  details?: AppErrorDetails;
};

export type ActionResult<TData = null> =
  | {
      ok: true;
      data: TData;
      message?: string;
    }
  | {
      ok: false;
      error: ActionError;
    };