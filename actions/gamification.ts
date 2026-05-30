"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { error as actionError, success } from "../lib/errors/actionResponses.ts";
import { requireCurrentUser } from "../lib/auth/currentUser";
import { evaluateAndAwardUserBadges } from "../services/badges/badgeService.ts";

export async function refreshMyBadgesAction(): Promise<ActionResult<{ awardedCount: number }>> {
  try {
    const user = await requireCurrentUser();
    const badges = await evaluateAndAwardUserBadges(user.id);

    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      awardedCount: badges.length
    });
  } catch (error) {
    return actionError(error);
  }
}
