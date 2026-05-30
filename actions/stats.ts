"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { error as actionError, success } from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { createGlobalStatSnapshot } from "../services/stats/globalStatsService.ts";

export async function createGlobalStatSnapshotAction(): Promise<
  ActionResult<{ snapshotId: string }>
> {
  try {
    await requireAdminGlobalUser();
    const snapshot = await createGlobalStatSnapshot();

    revalidatePath(APP_ROUTES.ADMIN);

    return success({
      snapshotId: snapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}
