import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  OFFICIAL_DATA_STATUS_VALUES,
  REAL_RESULT_TYPE_VALUES
} from "../contracts/enums.ts";
import { cuidSchema } from "./common.ts";

export const upsertRealTournamentResultSchema = z.object({
  resultKey: z
    .string()
    .trim()
    .min(3, "Chave do resultado obrigatória.")
    .max(160, "Chave do resultado muito longa."),
  type: z.enum(REAL_RESULT_TYPE_VALUES),
  group: z.enum(GROUP_LETTER_VALUES).optional(),
  knockoutPhase: z.enum(KNOCKOUT_PHASE_VALUES).optional(),
  officialMatchId: cuidSchema.optional(),
  bracketSlotId: cuidSchema.optional(),
  payload: z.unknown(),
  sourceDocumentRef: z.string().trim().max(1000).optional(),
  officialDataStatus: z.enum(OFFICIAL_DATA_STATUS_VALUES).optional(),
  officialDataVersionId: cuidSchema.optional()
});

export type UpsertRealTournamentResultInput = z.infer<
  typeof upsertRealTournamentResultSchema
>;
