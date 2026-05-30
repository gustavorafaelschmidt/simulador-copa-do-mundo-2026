import { OFFICIAL_DATA_STATUS } from "../contracts/enums.ts";
import { AppError } from "../errors/AppError.ts";
import type { OfficialDataEntity, OfficialDataReadinessReport } from "./types.ts";

type OfficialDataGuardOptions = {
  nodeEnv?: string;
  allowOfficialDataPlaceholders?: boolean;
};

function isProductionLike(options?: OfficialDataGuardOptions) {
  return (options?.nodeEnv ?? process.env.NODE_ENV) === "production";
}

function allowsPlaceholders(options?: OfficialDataGuardOptions) {
  return (
    options?.allowOfficialDataPlaceholders ??
    process.env.ALLOW_OFFICIAL_DATA_PLACEHOLDERS === "true"
  );
}

export function hasOnlyOfficialData(entities: OfficialDataEntity[]): boolean {
  return entities.every((entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.OFFICIAL);
}

export function buildOfficialDataReadinessReport(
  entities: OfficialDataEntity[]
): OfficialDataReadinessReport {
  const blockingReasons: string[] = [];

  const missingVersionCount = entities.filter((entity) => !entity.officialDataVersionId).length;
  const placeholderCount = entities.filter(
    (entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.PLACEHOLDER
  ).length;
  const partialCount = entities.filter(
    (entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.PARTIAL
  ).length;
  const deprecatedCount = entities.filter(
    (entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.DEPRECATED
  ).length;

  if (entities.length === 0) {
    blockingReasons.push("Nenhum dado oficial foi encontrado.");
  }

  if (missingVersionCount > 0) {
    blockingReasons.push(`${missingVersionCount} registro(s) sem versão oficial vinculada.`);
  }

  if (placeholderCount > 0) {
    blockingReasons.push(`${placeholderCount} registro(s) ainda estão como PLACEHOLDER.`);
  }

  if (partialCount > 0) {
    blockingReasons.push(`${partialCount} registro(s) ainda estão como PARTIAL.`);
  }

  if (deprecatedCount > 0) {
    blockingReasons.push(`${deprecatedCount} registro(s) estão como DEPRECATED.`);
  }

  return {
    canUseOfficialRules: blockingReasons.length === 0,
    blockingReasons,
    checkedAt: new Date().toISOString()
  };
}

export function assertOfficialDataCanBeUsedInProduction(
  entities: OfficialDataEntity[],
  options?: OfficialDataGuardOptions
): OfficialDataReadinessReport {
  const report = buildOfficialDataReadinessReport(entities);

  if (!isProductionLike(options)) {
    return report;
  }

  if (allowsPlaceholders(options)) {
    return report;
  }

  if (!report.canUseOfficialRules) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message:
        "Dados oficiais incompletos. Placeholders, dados parciais ou versões ausentes não podem ser usados em produção.",
      statusCode: 500,
      details: report
    });
  }

  return report;
}
