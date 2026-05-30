import { z } from "zod";

export const groupStandingResultPayloadSchema = z.object({
  orderedTeamIds: z.array(z.string().min(1)).length(4)
});

export const knockoutMatchResultPayloadSchema = z.object({
  winnerTeamId: z.string().min(1)
});

export type GroupStandingResultPayload = z.infer<typeof groupStandingResultPayloadSchema>;
export type KnockoutMatchResultPayload = z.infer<typeof knockoutMatchResultPayloadSchema>;
