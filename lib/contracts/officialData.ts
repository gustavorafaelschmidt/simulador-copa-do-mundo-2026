import type { GroupLetter, KnockoutPhase, OfficialDataStatus } from "./enums.ts";

export type OfficialDataVersionId = string;
export type NationalTeamId = string;
export type TournamentGroupId = string;
export type OfficialBracketSlotId = string;
export type OfficialMatchId = string;

export type OfficialDataVersionDTO = {
  id: OfficialDataVersionId;
  code: string;
  description: string;
  status: OfficialDataStatus;
  sourceDocumentRef: string | null;
  importedAt: string | null;
  isActive: boolean;
};

export type TournamentGroupDTO = {
  id: TournamentGroupId;
  letter: GroupLetter;
  name: string;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type NationalTeamDTO = {
  id: NationalTeamId;
  fifaCode: string;
  name: string;
  shortName: string;
  flagUrl: string | null;
  groupId: TournamentGroupId | null;
  groupLetter?: GroupLetter | null;
  groupPosition: number | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialBracketSlotDTO = {
  id: OfficialBracketSlotId;
  slotCode: string;
  phase: KnockoutPhase;
  sortOrder: number;
  sourceSlotCodeA: string | null;
  sourceSlotCodeB: string | null;
  winnerGoesToSlotCode: string | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialMatchDTO = {
  id: OfficialMatchId;
  matchNumber: number | null;
  matchCode: string;
  groupId: TournamentGroupId | null;
  knockoutPhase: KnockoutPhase | null;
  bracketSlotId: OfficialBracketSlotId | null;
  homeTeamId: NationalTeamId | null;
  awayTeamId: NationalTeamId | null;
  homeSlotCode: string | null;
  awaySlotCode: string | null;
  startsAt: string | null;
  stadium: string | null;
  city: string | null;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialThirdPlaceMatrixRuleDTO = {
  id: string;
  combinationKey: string;
  qualifiedThirdGroups: GroupLetter[];
  slotAssignments: Record<string, string>;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};
