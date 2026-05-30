import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  REAL_RESULT_TYPE_VALUES
} from "../contracts/enums.ts";

export const adminRealResultFormSchema = z.object({
  resultKey: z.string().trim().max(160).optional(),
  type: z.enum(REAL_RESULT_TYPE_VALUES),
  group: z.enum(GROUP_LETTER_VALUES).optional(),
  knockoutPhase: z.enum(KNOCKOUT_PHASE_VALUES).optional(),
  officialMatchId: z.string().trim().optional(),
  bracketSlotId: z.string().trim().optional(),
  sourceDocumentRef: z.string().trim().max(1000).optional(),
  officialDataVersionId: z.string().trim().optional(),
  payloadJson: z.string().trim().min(2, "Payload JSON é obrigatório.")
});

export type AdminRealResultFormInput = z.infer<typeof adminRealResultFormSchema>;
