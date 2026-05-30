"use server";

import { randomUUID } from "node:crypto";
import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { RANKING_TYPE } from "../lib/contracts/enums.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { success, error as actionError } from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { recalculateRanking } from "../services/ranking/rankingService.ts";

export async function recalculateIndividualRankingAction(): Promise<
  ActionResult<{ snapshotId: string }>
> {
  try {
    const admin = await requireAdminGlobalUser();
    const snapshot = await recalculateRanking({
      type: RANKING_TYPE.INDIVIDUAL,
      requestedByUserId: admin.id,
      idempotencyKey: `manual:${RANKING_TYPE.INDIVIDUAL}:${randomUUID()}`
    });

    revalidatePath(APP_ROUTES.RANKING_INDIVIDUAL);

    return success({
      snapshotId: snapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function recalculateTeamRankingAction(): Promise<
  ActionResult<{ snapshotId: string }>
> {
  try {
    const admin = await requireAdminGlobalUser();
    const snapshot = await recalculateRanking({
      type: RANKING_TYPE.TEAM,
      requestedByUserId: admin.id,
      idempotencyKey: `manual:${RANKING_TYPE.TEAM}:${randomUUID()}`
    });

    revalidatePath(APP_ROUTES.RANKING_TEAMS);

    return success({
      snapshotId: snapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}
