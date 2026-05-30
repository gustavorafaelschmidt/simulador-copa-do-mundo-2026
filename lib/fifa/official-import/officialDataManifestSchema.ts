import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  OFFICIAL_DATA_STATUS_VALUES
} from "../../contracts/enums.ts";

export const officialDataImportSourceSchema = z.object({
  code: z.string().trim().min(3).max(120),
  description: z.string().trim().min(3).max(500),
  sourceDocumentRef: z.string().trim().min(3).max(1000),
  status: z.enum(OFFICIAL_DATA_STATUS_VALUES)
});

export const officialGroupImportItemSchema = z.object({
  letter: z.enum(GROUP_LETTER_VALUES),
  name: z.string().trim().min(1).max(80)
});

export const officialTeamImportItemSchema = z.object({
  fifaCode: z.string().trim().min(2).max(6),
  name: z.string().trim().min(2).max(120),
  shortName: z.string().trim().min(2).max(80),
  flagUrl: z.string().url().nullable().optional(),
  group: z.enum(GROUP_LETTER_VALUES),
  groupPosition: z.number().int().min(1).max(4)
});

export const officialMatchImportItemSchema = z.object({
  matchCode: z.string().trim().min(2).max(40),
  matchNumber: z.number().int().positive().nullable().optional(),
  group: z.enum(GROUP_LETTER_VALUES).nullable().optional(),
  knockoutPhase: z.enum(KNOCKOUT_PHASE_VALUES).nullable().optional(),
  bracketSlotCode: z.string().trim().nullable().optional(),
  homeTeamFifaCode: z.string().trim().nullable().optional(),
  awayTeamFifaCode: z.string().trim().nullable().optional(),
  homeSlotCode: z.string().trim().nullable().optional(),
  awaySlotCode: z.string().trim().nullable().optional(),
  startsAt: z.string().datetime().nullable().optional(),
  stadium: z.string().trim().nullable().optional(),
  city: z.string().trim().nullable().optional()
});

export const officialBracketSlotImportItemSchema = z.object({
  slotCode: z.string().trim().min(2).max(80),
  phase: z.enum(KNOCKOUT_PHASE_VALUES),
  sortOrder: z.number().int().positive(),
  sourceSlotCodeA: z.string().trim().nullable().optional(),
  sourceSlotCodeB: z.string().trim().nullable().optional(),
  winnerGoesToSlotCode: z.string().trim().nullable().optional()
});

export const officialThirdPlaceMatrixImportItemSchema = z.object({
  combinationKey: z.string().trim().regex(/^[A-L]{8}$/),
  qualifiedThirdGroups: z.array(z.enum(GROUP_LETTER_VALUES)).length(8),
  slotAssignments: z.record(z.string(), z.enum(GROUP_LETTER_VALUES))
});

export const officialDataImportManifestSchema = z.object({
  source: officialDataImportSourceSchema,
  groups: z.array(officialGroupImportItemSchema).length(12),
  teams: z.array(officialTeamImportItemSchema),
  matches: z.array(officialMatchImportItemSchema),
  bracketSlots: z.array(officialBracketSlotImportItemSchema),
  thirdPlaceMatrix: z.array(officialThirdPlaceMatrixImportItemSchema)
});
