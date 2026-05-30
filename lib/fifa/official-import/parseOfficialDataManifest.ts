import { AppError } from "../../errors/AppError.ts";
import { officialDataImportManifestSchema } from "./officialDataManifestSchema.ts";
import {
  assertOfficialImportManifestConsistency,
  assertOfficialManifestIsProductionSafe
} from "./officialDataImportGuards.ts";
import type { OfficialDataImportManifest } from "./officialDataImportTypes.ts";

export function parseOfficialDataManifest(rawManifest: unknown): OfficialDataImportManifest {
  const parsed = officialDataImportManifestSchema.safeParse(rawManifest);

  if (!parsed.success) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Manifesto de dados oficiais inválido.",
      statusCode: 422,
      details: parsed.error.flatten().fieldErrors
    });
  }

  assertOfficialImportManifestConsistency(parsed.data);
  assertOfficialManifestIsProductionSafe(parsed.data);

  return parsed.data;
}
