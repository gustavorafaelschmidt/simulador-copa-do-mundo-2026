import type {
  GroupLetter,
  KnockoutPhase,
  OfficialDataStatus,
  RealResultType
} from "./enums.ts";
import type {
  OfficialBracketSlotId,
  OfficialDataVersionId,
  OfficialMatchId
} from "./officialData.ts";

export type RealTournamentResultDTO = {
  id: string;
  resultKey: string;
  type: RealResultType;
  group: GroupLetter | null;
  knockoutPhase: KnockoutPhase | null;
  officialMatchId: OfficialMatchId | null;
  bracketSlotId: OfficialBracketSlotId | null;
  payload: unknown;
  sourceDocumentRef: string | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type UpsertRealTournamentResultInputDTO = {
  resultKey: string;
  type: RealResultType;
  group?: GroupLetter;
  knockoutPhase?: KnockoutPhase;
  officialMatchId?: OfficialMatchId;
  bracketSlotId?: OfficialBracketSlotId;
  payload: unknown;
  sourceDocumentRef?: string;
  officialDataVersionId?: OfficialDataVersionId;
};
