import { z } from "zod";
import { cuidSchema } from "@/lib/validations/common";
import {
  groupLetterSchema,
  nationalTeamIdSchema,
  officialBracketSlotIdSchema
} from "@/lib/validations/officialData";
import { groupPredictionSelectionSchema } from "@/lib/validations/prediction";

export const votingSessionIdSchema = cuidSchema;

export const openGroupVotingSessionSchema = z.object({
  teamId: cuidSchema,
  group: groupLetterSchema
});

export const openKnockoutVotingSessionSchema = z.object({
  teamId: cuidSchema,
  bracketSlotId: officialBracketSlotIdSchema
});

export const closeVotingSessionSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema
});

export const submitGroupVoteSchema = groupPredictionSelectionSchema.extend({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  group: groupLetterSchema
});

export const submitKnockoutVoteSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  bracketSlotId: officialBracketSlotIdSchema,
  winnerTeamId: nationalTeamIdSchema
});

export const submitTiebreakerSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  selectedTeamId: nationalTeamIdSchema
});

export type OpenGroupVotingSessionInput = z.infer<typeof openGroupVotingSessionSchema>;
export type OpenKnockoutVotingSessionInput = z.infer<typeof openKnockoutVotingSessionSchema>;
export type CloseVotingSessionInput = z.infer<typeof closeVotingSessionSchema>;
export type SubmitGroupVoteInput = z.infer<typeof submitGroupVoteSchema>;
export type SubmitKnockoutVoteInput = z.infer<typeof submitKnockoutVoteSchema>;
export type SubmitTiebreakerInput = z.infer<typeof submitTiebreakerSchema>;
