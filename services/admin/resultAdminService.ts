import { prisma } from "../../lib/db/prisma.ts";
import {
  OFFICIAL_DATA_STATUS,
  REAL_RESULT_TYPE
} from "../../lib/contracts/enums.ts";
import type { RealTournamentResultDTO } from "../../lib/contracts/admin.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import {
  buildGroupStandingResultKey,
  buildKnockoutMatchResultKey,
  validateRealResultPayload
} from "./resultPayloadUtils.ts";
import { toRealTournamentResultDTO } from "./resultMapper.ts";

export type UpsertRealResultServiceInput = {
  resultKey?: string;
  type: keyof typeof REAL_RESULT_TYPE;
  group?: string;
  knockoutPhase?: string;
  officialMatchId?: string;
  bracketSlotId?: string;
  payload: unknown;
  sourceDocumentRef?: string;
  officialDataVersionId?: string;
};

function resolveResultKey(input: UpsertRealResultServiceInput): string {
  if (input.resultKey?.trim()) {
    return input.resultKey.trim();
  }

  if (input.type === REAL_RESULT_TYPE.GROUP_STANDING && input.group) {
    return buildGroupStandingResultKey(input.group);
  }

  if (input.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && input.bracketSlotId) {
    return buildKnockoutMatchResultKey(input.bracketSlotId);
  }

  throw new AppError({
    code: "VALIDATION_ERROR",
    message: "resultKey é obrigatório quando não puder ser derivado do tipo de resultado.",
    statusCode: 422
  });
}

function assertResultContextIsValid(input: UpsertRealResultServiceInput): void {
  if (input.type === REAL_RESULT_TYPE.GROUP_STANDING && !input.group) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Resultado de classificação de grupo exige grupo.",
      statusCode: 422
    });
  }

  if (input.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && !input.bracketSlotId) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Resultado de mata-mata exige bracketSlotId.",
      statusCode: 422
    });
  }
}

export async function listRealTournamentResults(): Promise<RealTournamentResultDTO[]> {
  const results = await prisma.realTournamentResult.findMany({
    orderBy: [
      {
        type: "asc"
      },
      {
        resultKey: "asc"
      }
    ]
  });

  return results.map(toRealTournamentResultDTO);
}

export async function upsertRealTournamentResult(
  input: UpsertRealResultServiceInput
): Promise<RealTournamentResultDTO> {
  assertResultContextIsValid(input);

  const resultKey = resolveResultKey(input);
  const validatedPayload = validateRealResultPayload(input.type, input.payload);

  const result = await prisma.realTournamentResult.upsert({
    where: {
      resultKey
    },
    update: {
      type: input.type,
      group: input.group ?? null,
      knockoutPhase: input.knockoutPhase ?? null,
      officialMatchId: input.officialMatchId ?? null,
      bracketSlotId: input.bracketSlotId ?? null,
      payload: validatedPayload,
      sourceDocumentRef: input.sourceDocumentRef?.trim() || null,
      officialDataStatus: OFFICIAL_DATA_STATUS.OFFICIAL,
      officialDataVersionId: input.officialDataVersionId ?? null
    },
    create: {
      resultKey,
      type: input.type,
      group: input.group ?? null,
      knockoutPhase: input.knockoutPhase ?? null,
      officialMatchId: input.officialMatchId ?? null,
      bracketSlotId: input.bracketSlotId ?? null,
      payload: validatedPayload,
      sourceDocumentRef: input.sourceDocumentRef?.trim() || null,
      officialDataStatus: OFFICIAL_DATA_STATUS.OFFICIAL,
      officialDataVersionId: input.officialDataVersionId ?? null
    }
  });

  return toRealTournamentResultDTO(result);
}
