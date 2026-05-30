import { z } from "zod";
import { cuidSchema } from "./common.ts";

export const joinTeamSocketSchema = z.object({
  teamId: cuidSchema
});

export type JoinTeamSocketInput = z.infer<typeof joinTeamSocketSchema>;
