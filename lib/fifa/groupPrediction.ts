import type {
  GroupSelection,
  QualifiedGroupTeams,
  ThirdPlacedCandidate
} from "@/lib/fifa/types";
import { AppError } from "@/lib/errors/AppError";

export function getGroupSelectionTeamIds(selection: GroupSelection): string[] {
  return [
    selection.firstPlaceTeamId,
    selection.secondPlaceTeamId,
    selection.thirdPlaceTeamId,
    selection.fourthPlaceTeamId
  ];
}

export function assertGroupSelectionIsComplete(selection: GroupSelection): void {
  const ids = getGroupSelectionTeamIds(selection);

  if (ids.some((id) => !id || id.trim().length === 0)) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as quatro posições do grupo devem ser preenchidas.",
      statusCode: 422
    });
  }

  if (new Set(ids).size !== ids.length) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Uma seleção não pode ocupar mais de uma posição no mesmo grupo.",
      statusCode: 422
    });
  }
}

export function toQualifiedGroupTeams(selection: GroupSelection): QualifiedGroupTeams {
  assertGroupSelectionIsComplete(selection);

  return {
    group: selection.group,
    firstPlaceTeamId: selection.firstPlaceTeamId,
    secondPlaceTeamId: selection.secondPlaceTeamId,
    thirdPlaceTeamId: selection.thirdPlaceTeamId
  };
}

export function toThirdPlacedCandidate(selection: GroupSelection): ThirdPlacedCandidate {
  assertGroupSelectionIsComplete(selection);

  return {
    group: selection.group,
    teamId: selection.thirdPlaceTeamId
  };
}

/*
  Não escolhe os 8 melhores terceiros.
  A seleção dos melhores terceiros depende de critérios oficiais e dados reais/completos.
  Este helper apenas extrai candidatos a partir das escolhas do usuário/equipe.
*/
export function extractThirdPlacedCandidates(
  selections: GroupSelection[]
): ThirdPlacedCandidate[] {
  return selections.map(toThirdPlacedCandidate);
}
