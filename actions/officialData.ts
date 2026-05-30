"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import {
  error as actionError,
  success,
  validationError
} from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { importOfficialDataManifest } from "../services/officialData/officialDataImportService.ts";

export async function importOfficialDataManifestAction(
  formData: FormData
): Promise<ActionResult<{ versionId: string }>> {
  await requireAdminGlobalUser();

  const rawJson = String(formData.get("manifestJson") ?? "").trim();

  if (!rawJson) {
    return validationError("Manifesto JSON é obrigatório.");
  }

  try {
    const manifest = JSON.parse(rawJson);
    const result = await importOfficialDataManifest(manifest);

    revalidatePath(APP_ROUTES.ADMIN);
    revalidatePath(APP_ROUTES.ADMIN_OFFICIAL_DATA);

    return success({
      versionId: result.versionId
    });
  } catch (error) {
    return actionError(error);
  }
}
