import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  OFFICIAL_DATA_STATUS_VALUES
} from "@/lib/contracts/enums";
import { cuidSchema } from "@/lib/validations/common";

export const groupLetterSchema = z.enum(GROUP_LETTER_VALUES);

export const knockoutPhaseSchema = z.enum(KNOCKOUT_PHASE_VALUES);

export const officialDataStatusSchema = z.enum(OFFICIAL_DATA_STATUS_VALUES);

export const nationalTeamIdSchema = cuidSchema;

export const officialBracketSlotIdSchema = cuidSchema;

export const officialMatchIdSchema = cuidSchema;

export const officialDataVersionIdSchema = cuidSchema;

export const thirdPlaceMatrixRuleSchema = z.object({
  combinationKey: z.string().trim().min(1, "Chave da combinação obrigatória."),
  qualifiedThirdGroups: z.array(groupLetterSchema).length(8),
  slotAssignments: z.record(z.string(), z.string()),
  officialDataStatus: officialDataStatusSchema
});

export type ThirdPlaceMatrixRuleInput = z.infer<typeof thirdPlaceMatrixRuleSchema>;
