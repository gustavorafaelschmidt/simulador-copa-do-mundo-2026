import { z } from "zod";
import { BADGE_RARITY_VALUES, BADGE_TARGET_TYPE_VALUES } from "../contracts/enums.ts";

export const badgeCodeSchema = z
  .string()
  .trim()
  .min(3)
  .max(80)
  .regex(/^[A-Z0-9_]+$/, "Código de badge deve estar em formato SNAKE_CASE.");

export const badgeSchema = z.object({
  code: badgeCodeSchema,
  name: z.string().trim().min(3).max(80),
  description: z.string().trim().min(10).max(500),
  targetType: z.enum(BADGE_TARGET_TYPE_VALUES),
  rarity: z.enum(BADGE_RARITY_VALUES),
  iconKey: z.string().trim().min(1).max(80).optional()
});

export type BadgeInput = z.infer<typeof badgeSchema>;
