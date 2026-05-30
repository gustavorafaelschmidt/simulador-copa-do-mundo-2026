import { AppError } from "../../lib/errors/AppError.ts";

export function assertDistinctTeamIds(teamIds: string[]): void {
  if (teamIds.some((teamId) => !teamId || teamId.trim().length === 0)) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as seleções obrigatórias devem ser informadas.",
      statusCode: 422
    });
  }

  if (new Set(teamIds).size !== teamIds.length) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Uma mesma seleção não pode ocupar mais de uma posição.",
      statusCode: 422
    });
  }
}

export function deriveFourthPlaceTeamId(
  groupTeamIds: string[],
  selectedTopThreeTeamIds: string[]
): string {
  assertDistinctTeamIds(selectedTopThreeTeamIds);

  const uniqueGroupTeamIds = [...new Set(groupTeamIds)];

  if (uniqueGroupTeamIds.length !== 4) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "O grupo precisa ter exatamente quatro seleções para calcular o 4º colocado.",
      statusCode: 500,
      details: {
        groupTeamCount: uniqueGroupTeamIds.length
      }
    });
  }

  const invalidSelections = selectedTopThreeTeamIds.filter(
    (teamId) => !uniqueGroupTeamIds.includes(teamId)
  );

  if (invalidSelections.length > 0) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as seleções escolhidas devem pertencer ao grupo informado.",
      statusCode: 422,
      details: {
        invalidSelections
      }
    });
  }

  const fourthPlaceTeamId = uniqueGroupTeamIds.find(
    (teamId) => !selectedTopThreeTeamIds.includes(teamId)
  );

  if (!fourthPlaceTeamId) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Não foi possível calcular o 4º colocado do grupo.",
      statusCode: 422
    });
  }

  return fourthPlaceTeamId;
}

export function buildPredictionLockErrorMessage(): string {
  return "As previsões estão bloqueadas no momento.";
}
