"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import {
  error as actionError,
  success,
  validationError
} from "../lib/errors/actionResponses.ts";
import { requireCurrentUser } from "../lib/auth/currentUser";
import {
  completeUserProfileSchema,
  updateUserProfileSchema
} from "../lib/validations/profile.ts";
import {
  completeUserOnboarding,
  updateUserProfile
} from "../services/user/userProfileService.ts";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  return Object.fromEntries(formData.entries());
}

export async function completeOnboardingAction(
  formData: FormData
): Promise<ActionResult<{ redirectTo: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = completeUserProfileSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de onboarding inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    await completeUserOnboarding(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.ONBOARDING);
    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      redirectTo: APP_ROUTES.DASHBOARD
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function updateProfileAction(
  formData: FormData
): Promise<ActionResult<{ profileUpdated: true }>> {
  const user = await requireCurrentUser();
  const parsedInput = updateUserProfileSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de perfil inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    await updateUserProfile(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.SETTINGS_PROFILE);
    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      profileUpdated: true
    });
  } catch (error) {
    return actionError(error);
  }
}
