import { REAL_RESULT_TYPE } from "../../lib/contracts/enums.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import {
  groupStandingResultPayloadSchema,
  knockoutMatchResultPayloadSchema
} from "../scoring/resultPayloads.ts";

export function parseJsonPayload(rawPayload: string): unknown {
  try {
    return JSON.parse(rawPayload);
  } catch {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Payload precisa ser um JSON válido.",
      statusCode: 422
    });
  }
}

export function validateRealResultPayload(type: string, payload: unknown): unknown {
  if (type === REAL_RESULT_TYPE.GROUP_STANDING) {
    const parsedPayload = groupStandingResultPayloadSchema.safeParse(payload);

    if (!parsedPayload.success) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message:
          "Payload de classificação de grupo inválido. Esperado: { \"orderedTeamIds\": [\"id1\", \"id2\", \"id3\", \"id4\"] }.",
        statusCode: 422,
        details: parsedPayload.error.flatten().fieldErrors
      });
    }

    return parsedPayload.data;
  }

  if (type === REAL_RESULT_TYPE.KNOCKOUT_MATCH) {
    const parsedPayload = knockoutMatchResultPayloadSchema.safeParse(payload);

    if (!parsedPayload.success) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message:
          "Payload de mata-mata inválido. Esperado: { \"winnerTeamId\": \"id\" }.",
        statusCode: 422,
        details: parsedPayload.error.flatten().fieldErrors
      });
    }

    return parsedPayload.data;
  }

  if (payload === null || typeof payload !== "object") {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Payload de resultado precisa ser um objeto JSON.",
      statusCode: 422
    });
  }

  return payload;
}

export function buildGroupStandingResultKey(group: string): string {
  return `group_standing:${group}`;
}

export function buildKnockoutMatchResultKey(bracketSlotId: string): string {
  return `knockout_match:${bracketSlotId}`;
}
