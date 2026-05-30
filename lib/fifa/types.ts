import type {
  GroupLetter,
  KnockoutPhase,
  OfficialDataStatus
} from "../contracts/enums.ts";
import type {
  NationalTeamId,
  OfficialBracketSlotId,
  OfficialDataVersionId
} from "../contracts/officialData.ts";

export type OfficialDataEntity = {
  id: string;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialDataReadinessReport = {
  canUseOfficialRules: boolean;
  blockingReasons: string[];
  checkedAt: string;
};

export type GroupStandingPosition = 1 | 2 | 3 | 4;

export type GroupSelection = {
  group: GroupLetter;
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
};

export type QualifiedGroupTeams = {
  group: GroupLetter;
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
};

export type ThirdPlacedCandidate = {
  group: GroupLetter;
  teamId: NationalTeamId;
};

/*
  Representa apenas slots versionados. Não contém regra oficial de chaveamento.
  O relacionamento real entre grupos, terceiros e 16-avos deve vir dos documentos oficiais.
*/
export type BracketSlotDescriptor = {
  id: OfficialBracketSlotId;
  slotCode: string;
  phase: KnockoutPhase;
  sortOrder: number;
  sourceSlotCodeA: string | null;
  sourceSlotCodeB: string | null;
};
