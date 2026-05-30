import { z } from "zod";
import { RANKING_TYPE_VALUES } from "../contracts/enums.ts";

export const rankingTypeSchema = z.enum(RANKING_TYPE_VALUES);

export const requestRankingRecalculationSchema = z.object({
  type: rankingTypeSchema,
  idempotencyKey: z
    .string()
    .trim()
    .min(12, "Chave de idempotência deve ter pelo menos 12 caracteres.")
    .max(120, "Chave de idempotência deve ter no máximo 120 caracteres.")
});

export type RequestRankingRecalculationInput = z.infer<
  typeof requestRankingRecalculationSchema
>;
