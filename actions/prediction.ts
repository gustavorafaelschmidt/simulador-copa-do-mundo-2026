"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { error as actionError, success, validationError } from "../lib/errors/actionResponses.ts";
import { requireCurrentUser } from "../lib/auth/currentUser";
import {
  saveIndividualGroupTopThreePredictionSchema,
  saveIndividualKnockoutPredictionInputSchema
} from "../lib/validations/individualPrediction.ts";
import {
  saveIndividualGroupPrediction,
  saveIndividualKnockoutPrediction
} from "../services/prediction/predictionService.ts";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  return Object.fromEntries(formData.entries());
}

export async function saveIndividualGroupPredictionAction(
  formData: FormData
): Promise<ActionResult<{ predictionId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = saveIndividualGroupTopThreePredictionSchema.safeParse(
    formDataToObject(formData)
  );

  if (!parsedInput.success) {
    return validationError("Previsão de grupo inválida.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const prediction = await saveIndividualGroupPrediction(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      predictionId: prediction.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function saveIndividualKnockoutPredictionAction(
  formData: FormData
): Promise<ActionResult<{ predictionId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = saveIndividualKnockoutPredictionInputSchema.safeParse(
    formDataToObject(formData)
  );

  if (!parsedInput.success) {
    return validationError(
      "Previsão de mata-mata inválida.",
      parsedInput.error.flatten().fieldErrors
    );
  }

  try {
    const prediction = await saveIndividualKnockoutPrediction(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      predictionId: prediction.id
    });
  } catch (error) {
    return actionError(error);
  }
}
