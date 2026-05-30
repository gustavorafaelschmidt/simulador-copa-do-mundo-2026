import type { RealTournamentResultDTO } from "../../lib/contracts/admin.ts";

export type RealTournamentResultRecord = {
  id: string;
  resultKey: string;
  type: RealTournamentResultDTO["type"];
  group: RealTournamentResultDTO["group"];
  knockoutPhase: RealTournamentResultDTO["knockoutPhase"];
  officialMatchId: string | null;
  bracketSlotId: string | null;
  payload: unknown;
  sourceDocumentRef: string | null;
  officialDataStatus: RealTournamentResultDTO["officialDataStatus"];
  officialDataVersionId: string | null;
};

export function toRealTournamentResultDTO(
  result: RealTournamentResultRecord
): RealTournamentResultDTO {
  return {
    id: result.id,
    resultKey: result.resultKey,
    type: result.type,
    group: result.group,
    knockoutPhase: result.knockoutPhase,
    officialMatchId: result.officialMatchId,
    bracketSlotId: result.bracketSlotId,
    payload: result.payload,
    sourceDocumentRef: result.sourceDocumentRef,
    officialDataStatus: result.officialDataStatus,
    officialDataVersionId: result.officialDataVersionId
  };
}
