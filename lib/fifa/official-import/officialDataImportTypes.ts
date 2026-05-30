import type {
  GroupLetter,
  KnockoutPhase,
  OfficialDataStatus
} from "../../contracts/enums.ts";

export type OfficialDataImportSource = {
  code: string;
  description: string;
  sourceDocumentRef: string;
  status: OfficialDataStatus;
};

export type OfficialTeamImportItem = {
  fifaCode: string;
  name: string;
  shortName: string;
  flagUrl?: string | null;
  group: GroupLetter;
  groupPosition: number;
};

export type OfficialGroupImportItem = {
  letter: GroupLetter;
  name: string;
};

export type OfficialMatchImportItem = {
  matchCode: string;
  matchNumber?: number | null;
  group?: GroupLetter | null;
  knockoutPhase?: KnockoutPhase | null;
  bracketSlotCode?: string | null;
  homeTeamFifaCode?: string | null;
  awayTeamFifaCode?: string | null;
  homeSlotCode?: string | null;
  awaySlotCode?: string | null;
  startsAt?: string | null;
  stadium?: string | null;
  city?: string | null;
};

export type OfficialBracketSlotImportItem = {
  slotCode: string;
  phase: KnockoutPhase;
  sortOrder: number;
  sourceSlotCodeA?: string | null;
  sourceSlotCodeB?: string | null;
  winnerGoesToSlotCode?: string | null;
};

export type OfficialThirdPlaceMatrixImportItem = {
  combinationKey: string;
  qualifiedThirdGroups: GroupLetter[];
  slotAssignments: Record<string, GroupLetter>;
};

export type OfficialDataImportManifest = {
  source: OfficialDataImportSource;
  groups: OfficialGroupImportItem[];
  teams: OfficialTeamImportItem[];
  matches: OfficialMatchImportItem[];
  bracketSlots: OfficialBracketSlotImportItem[];
  thirdPlaceMatrix: OfficialThirdPlaceMatrixImportItem[];
};
