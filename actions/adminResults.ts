"use server";

import { randomUUID } from "node:crypto";
import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { RANKING_TYPE } from "../lib/contracts/enums.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import {
  error as actionError,
  success,
  validationError
} from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { adminRealResultFormSchema } from "../lib/validations/adminResults.ts";
import { parseJsonPayload } from "../services/admin/resultPayloadUtils.ts";
import { upsertRealTournamentResult } from "../services/admin/resultAdminService.ts";
import { recalculateRanking } from "../services/ranking/rankingService.ts";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  return Object.fromEntries(
    Object.entries(Object.fromEntries(formData.entries())).filter(([, value]) => value !== "")
  );
}

export async function upsertRealTournamentResultAction(
  formData: FormData
): Promise<ActionResult<{ resultId: string }>> {
  await requireAdminGlobalUser();

  const parsedInput = adminRealResultFormSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Resultado real inválido.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const payload = parseJsonPayload(parsedInput.data.payloadJson);

    const result = await upsertRealTournamentResult({
      resultKey: parsedInput.data.resultKey,
      type: parsedInput.data.type,
      group: parsedInput.data.group,
      knockoutPhase: parsedInput.data.knockoutPhase,
      officialMatchId: parsedInput.data.officialMatchId,
      bracketSlotId: parsedInput.data.bracketSlotId,
      sourceDocumentRef: parsedInput.data.sourceDocumentRef,
      officialDataVersionId: parsedInput.data.officialDataVersionId,
      payload
    });

    revalidatePath(APP_ROUTES.ADMIN_RESULTS);
    revalidatePath(APP_ROUTES.RANKING_INDIVIDUAL);
    revalidatePath(APP_ROUTES.RANKING_TEAMS);

    return success({
      resultId: result.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function recalculateAllRankingsAction(): Promise<
  ActionResult<{ individualSnapshotId: string; teamSnapshotId: string }>
> {
  const admin = await requireAdminGlobalUser();

  try {
    const [individualSnapshot, teamSnapshot] = await Promise.all([
      recalculateRanking({
        type: RANKING_TYPE.INDIVIDUAL,
        requestedByUserId: admin.id,
        idempotencyKey: `admin-results:${RANKING_TYPE.INDIVIDUAL}:${randomUUID()}`
      }),
      recalculateRanking({
        type: RANKING_TYPE.TEAM,
        requestedByUserId: admin.id,
        idempotencyKey: `admin-results:${RANKING_TYPE.TEAM}:${randomUUID()}`
      })
    ]);

    revalidatePath(APP_ROUTES.RANKING_INDIVIDUAL);
    revalidatePath(APP_ROUTES.RANKING_TEAMS);
    revalidatePath(APP_ROUTES.ADMIN_RESULTS);

    return success({
      individualSnapshotId: individualSnapshot.id,
      teamSnapshotId: teamSnapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}
