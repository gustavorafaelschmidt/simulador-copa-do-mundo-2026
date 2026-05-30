import { AppError } from "../../errors/AppError.ts";
import { buildThirdPlaceCombinationKey } from "../roundOf32.ts";
import type { OfficialDataImportManifest } from "./officialDataImportTypes.ts";

export function assertOfficialImportManifestConsistency(
  manifest: OfficialDataImportManifest
): void {
  const groupLetters = new Set(manifest.groups.map((group) => group.letter));

  if (groupLetters.size !== 12) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Manifesto oficial precisa conter exatamente 12 grupos distintos.",
      statusCode: 422
    });
  }

  for (const group of manifest.groups) {
    const teamsInGroup = manifest.teams.filter((team) => team.group === group.letter);
    const groupPositions = new Set(teamsInGroup.map((team) => team.groupPosition));

    if (teamsInGroup.length !== 4 || groupPositions.size !== 4) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: `Grupo ${group.letter} precisa conter exatamente quatro seleções nas posições 1 a 4.`,
        statusCode: 422
      });
    }
  }

  const fifaCodes = manifest.teams.map((team) => team.fifaCode);
  const duplicatedFifaCodes = fifaCodes.filter(
    (fifaCode, index) => fifaCodes.indexOf(fifaCode) !== index
  );

  if (duplicatedFifaCodes.length > 0) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Manifesto possui códigos FIFA duplicados.",
      statusCode: 422,
      details: {
        duplicatedFifaCodes
      }
    });
  }

  const bracketSlotCodes = new Set(manifest.bracketSlots.map((slot) => slot.slotCode));

  for (const match of manifest.matches) {
    if (match.bracketSlotCode && !bracketSlotCodes.has(match.bracketSlotCode)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Partida aponta para slot de mata-mata inexistente.",
        statusCode: 422,
        details: {
          matchCode: match.matchCode,
          bracketSlotCode: match.bracketSlotCode
        }
      });
    }
  }

  for (const matrixRule of manifest.thirdPlaceMatrix) {
    const combinationKey = buildThirdPlaceCombinationKey(matrixRule.qualifiedThirdGroups);

    if (combinationKey !== matrixRule.combinationKey) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Chave de combinação da matriz de terceiros não corresponde aos grupos informados.",
        statusCode: 422,
        details: {
          expected: combinationKey,
          received: matrixRule.combinationKey
        }
      });
    }
  }
}

export function assertOfficialManifestIsProductionSafe(
  manifest: OfficialDataImportManifest
): void {
  if (process.env.NODE_ENV !== "production") {
    return;
  }

  if (manifest.source.status !== "OFFICIAL") {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Em produção, somente manifesto com status OFFICIAL pode ser importado.",
      statusCode: 500
    });
  }

  if (manifest.teams.length !== 48) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Em produção, o manifesto oficial precisa conter as 48 seleções.",
      statusCode: 500
    });
  }

  if (manifest.thirdPlaceMatrix.length !== 495) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Em produção, a matriz oficial dos terceiros precisa conter as 495 combinações do Annexe C.",
      statusCode: 500
    });
  }
}
