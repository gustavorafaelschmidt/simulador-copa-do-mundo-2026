"use server";

import { AuthError } from "next-auth";
import { signIn, signOut } from "@/auth";
import { APP_ROUTES } from "@/lib/contracts/routes";
import type { ActionResult } from "@/lib/contracts/actionResult";
import { error as actionError, success, validationError } from "@/lib/errors/actionResponses";
import {
  loginWithCredentialsSchema,
  registerWithCredentialsSchema
} from "@/lib/validations/auth";
import { registerUserWithCredentials } from "@/services/auth/authService";

function formDataToObject(formData: FormData) {
  return Object.fromEntries(formData.entries());
}

export async function registerWithCredentialsAction(
  formData: FormData
): Promise<ActionResult<{ userId: string; redirectTo: string }>> {
  const parsedInput = registerWithCredentialsSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de cadastro inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const user = await registerUserWithCredentials(parsedInput.data);

    await signIn("credentials", {
      email: parsedInput.data.email,
      password: parsedInput.data.password,
      redirect: false
    });

    return success({
      userId: user.id,
      redirectTo: APP_ROUTES.DASHBOARD
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function loginWithCredentialsAction(
  formData: FormData
): Promise<ActionResult<{ redirectTo: string }>> {
  const parsedInput = loginWithCredentialsSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Credenciais inválidas.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    await signIn("credentials", {
      email: parsedInput.data.email,
      password: parsedInput.data.password,
      redirect: false
    });

    return success({
      redirectTo: APP_ROUTES.DASHBOARD
    });
  } catch (error) {
    if (error instanceof AuthError) {
      return validationError("Email ou senha inválidos.");
    }

    return actionError(error);
  }
}

export async function signInWithGoogleAction(): Promise<void> {
  await signIn("google", {
    redirectTo: APP_ROUTES.DASHBOARD
  });
}

export async function logoutAction(): Promise<void> {
  await signOut({
    redirectTo: APP_ROUTES.HOME
  });
}
