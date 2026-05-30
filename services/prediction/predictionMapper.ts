import type { IndividualGroupPredictionDTO, IndividualKnockoutPredictionDTO } from "../../lib/contracts/prediction.ts";

export type IndividualGroupPredictionRecord = {
  id: string;
  userId: string;
  group: IndividualGroupPredictionDTO["group"];
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
  fourthPlaceTeamId: string;
  lockedAt: Date | null;
  submittedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export type IndividualKnockoutPredictionRecord = {
  id: string;
  userId: string;
  bracketSlotId: string;
  winnerTeamId: string;
  lockedAt: Date | null;
  submittedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export function toIndividualGroupPredictionDTO(
  prediction: IndividualGroupPredictionRecord
): IndividualGroupPredictionDTO {
  return {
    id: prediction.id,
    userId: prediction.userId,
    group: prediction.group,
    firstPlaceTeamId: prediction.firstPlaceTeamId,
    secondPlaceTeamId: prediction.secondPlaceTeamId,
    thirdPlaceTeamId: prediction.thirdPlaceTeamId,
    fourthPlaceTeamId: prediction.fourthPlaceTeamId,
    lockedAt: prediction.lockedAt?.toISOString() ?? null,
    submittedAt: prediction.submittedAt?.toISOString() ?? null,
    createdAt: prediction.createdAt.toISOString(),
    updatedAt: prediction.updatedAt.toISOString()
  };
}

export function toIndividualKnockoutPredictionDTO(
  prediction: IndividualKnockoutPredictionRecord
): IndividualKnockoutPredictionDTO {
  return {
    id: prediction.id,
    userId: prediction.userId,
    bracketSlotId: prediction.bracketSlotId,
    winnerTeamId: prediction.winnerTeamId,
    lockedAt: prediction.lockedAt?.toISOString() ?? null,
    submittedAt: prediction.submittedAt?.toISOString() ?? null,
    createdAt: prediction.createdAt.toISOString(),
    updatedAt: prediction.updatedAt.toISOString()
  };
}
