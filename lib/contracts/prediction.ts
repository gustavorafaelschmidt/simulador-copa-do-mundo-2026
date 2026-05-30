import type { GroupLetter } from "./enums.ts";
import type { NationalTeamId, OfficialBracketSlotId } from "./officialData.ts";
import type { UserId } from "./user.ts";

export type GroupPredictionSelectionDTO = {
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
};

export type SaveIndividualGroupPredictionInputDTO = GroupPredictionSelectionDTO & {
  group: GroupLetter;
};

export type IndividualGroupPredictionDTO = GroupPredictionSelectionDTO & {
  id: string;
  userId: UserId;
  group: GroupLetter;
  lockedAt: string | null;
  submittedAt: string | null;
  createdAt: string;
  updatedAt: string;
};

export type SaveIndividualKnockoutPredictionInputDTO = {
  bracketSlotId: OfficialBracketSlotId;
  winnerTeamId: NationalTeamId;
};

export type IndividualKnockoutPredictionDTO = {
  id: string;
  userId: UserId;
  bracketSlotId: OfficialBracketSlotId;
  winnerTeamId: NationalTeamId;
  lockedAt: string | null;
  submittedAt: string | null;
  createdAt: string;
  updatedAt: string;
};
