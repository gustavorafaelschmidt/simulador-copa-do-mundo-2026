import type { GroupLetter } from "@/lib/contracts/enums";
import type { NationalTeamId, OfficialBracketSlotId } from "@/lib/contracts/officialData";
import type { UserId } from "@/lib/contracts/user";

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
