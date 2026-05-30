import { z } from "zod";
import {
  groupLetterSchema,
  nationalTeamIdSchema,
  officialBracketSlotIdSchema
} from "./officialData.ts";

function hasDistinctTopThreeTeams(value: {
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
}) {
  const ids = [value.firstPlaceTeamId, value.secondPlaceTeamId, value.thirdPlaceTeamId];

  return new Set(ids).size === ids.length;
}

export const saveIndividualGroupTopThreePredictionSchema = z
  .object({
    group: groupLetterSchema,
    firstPlaceTeamId: nationalTeamIdSchema,
    secondPlaceTeamId: nationalTeamIdSchema,
    thirdPlaceTeamId: nationalTeamIdSchema
  })
  .refine(hasDistinctTopThreeTeams, {
    message: "1º, 2º e 3º colocados devem ser seleções diferentes."
  });

export const saveIndividualKnockoutPredictionInputSchema = z.object({
  bracketSlotId: officialBracketSlotIdSchema,
  winnerTeamId: nationalTeamIdSchema
});

export type SaveIndividualGroupTopThreePredictionInput = z.infer<
  typeof saveIndividualGroupTopThreePredictionSchema
>;

export type SaveIndividualKnockoutPredictionInput = z.infer<
  typeof saveIndividualKnockoutPredictionInputSchema
>;
