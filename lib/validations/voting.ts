import { z } from "zod";
import { cuidSchema } from "./common.ts";
import {
  groupLetterSchema,
  nationalTeamIdSchema,
  officialBracketSlotIdSchema
} from "./officialData.ts";
import { groupPredictionSelectionSchema } from "./prediction.ts";

export const votingSessionIdSchema = cuidSchema;

export const openGroupVotingSessionSchema = z.object({
  teamId: cuidSchema,
  group: groupLetterSchema
});

export const openKnockoutVotingSessionSchema = z.object({
  teamId: cuidSchema,
  bracketSlotId: officialBracketSlotIdSchema
});

export const openVotingSessionSchema = z.union([
  openGroupVotingSessionSchema,
  openKnockoutVotingSessionSchema
]);

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

export const submitKnockoutTiebreakerSchema = z.object({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  selectedTeamId: nationalTeamIdSchema
});

export const submitGroupTiebreakerSchema = groupPredictionSelectionSchema.extend({
  teamId: cuidSchema,
  votingSessionId: votingSessionIdSchema,
  group: groupLetterSchema
});

export const submitTiebreakerSchema = submitKnockoutTiebreakerSchema;

export const submitAnyTiebreakerSchema = z.union([
  submitGroupTiebreakerSchema,
  submitKnockoutTiebreakerSchema
]);

export type OpenGroupVotingSessionInput = z.infer<typeof openGroupVotingSessionSchema>;
export type OpenKnockoutVotingSessionInput = z.infer<typeof openKnockoutVotingSessionSchema>;
export type CloseVotingSessionInput = z.infer<typeof closeVotingSessionSchema>;
export type SubmitGroupVoteInput = z.infer<typeof submitGroupVoteSchema>;
export type SubmitKnockoutVoteInput = z.infer<typeof submitKnockoutVoteSchema>;
export type SubmitKnockoutTiebreakerInput = z.infer<typeof submitKnockoutTiebreakerSchema>;
export type SubmitGroupTiebreakerInput = z.infer<typeof submitGroupTiebreakerSchema>;
export type SubmitTiebreakerInput = z.infer<typeof submitTiebreakerSchema>;
export type SubmitAnyTiebreakerInput = z.infer<typeof submitAnyTiebreakerSchema>;
