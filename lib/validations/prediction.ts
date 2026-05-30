import { z } from "zod";
import {
  groupLetterSchema,
  nationalTeamIdSchema,
  officialBracketSlotIdSchema
} from "@/lib/validations/officialData";

function hasDistinctTeams(value: {
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
  fourthPlaceTeamId: string;
}) {
  const ids = [
    value.firstPlaceTeamId,
    value.secondPlaceTeamId,
    value.thirdPlaceTeamId,
    value.fourthPlaceTeamId
  ];

  return new Set(ids).size === ids.length;
}

export const groupPredictionSelectionSchema = z
  .object({
    firstPlaceTeamId: nationalTeamIdSchema,
    secondPlaceTeamId: nationalTeamIdSchema,
    thirdPlaceTeamId: nationalTeamIdSchema,
    fourthPlaceTeamId: nationalTeamIdSchema
  })
  .refine(hasDistinctTeams, {
    message: "As quatro posições do grupo devem conter seleções diferentes."
  });

export const saveIndividualGroupPredictionSchema = groupPredictionSelectionSchema.extend({
  group: groupLetterSchema
});

export const saveIndividualKnockoutPredictionSchema = z.object({
  bracketSlotId: officialBracketSlotIdSchema,
  winnerTeamId: nationalTeamIdSchema
});

export type GroupPredictionSelectionInput = z.infer<typeof groupPredictionSelectionSchema>;

export type SaveIndividualGroupPredictionInput = z.infer<
  typeof saveIndividualGroupPredictionSchema
>;

export type SaveIndividualKnockoutPredictionInput = z.infer<
  typeof saveIndividualKnockoutPredictionSchema
>;
