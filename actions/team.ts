"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "@/lib/contracts/actionResult";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { error as actionError, success, validationError } from "@/lib/errors/actionResponses";
import { requireCurrentUser } from "@/lib/auth/currentUser";
import {
  changeTeamMemberRoleSchema,
  createTeamSchema,
  joinTeamByCodeSchema,
  removeTeamMemberSchema,
  reviewTeamMemberSchema
} from "@/lib/validations/team";
import {
  changeTeamMemberRole,
  createTeam,
  joinTeamByInviteCode,
  removeTeamMember,
  reviewTeamMember
} from "@/services/team/teamService";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  const entries = Object.entries(Object.fromEntries(formData.entries()));

  return Object.fromEntries(entries.filter(([, value]) => value !== ""));
}

export async function createTeamAction(
  formData: FormData
): Promise<ActionResult<{ teamId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = createTeamSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados da equipe inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const team = await createTeam(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAMS);

    return success({
      teamId: team.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function joinTeamByCodeAction(
  formData: FormData
): Promise<ActionResult<{ teamId: string; memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = joinTeamByCodeSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Código de convite inválido.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const membership = await joinTeamByInviteCode(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAMS);

    return success({
      teamId: membership.teamId,
      memberId: membership.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function reviewTeamMemberAction(
  formData: FormData
): Promise<ActionResult<{ memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = reviewTeamMemberSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de revisão inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const member = await reviewTeamMember(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAMS);
    revalidatePath(APP_ROUTES.TEAM_DETAILS(parsedInput.data.teamId));

    return success({
      memberId: member.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function changeTeamMemberRoleAction(
  formData: FormData
): Promise<ActionResult<{ memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = changeTeamMemberRoleSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de alteração de papel inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const member = await changeTeamMemberRole(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAM_DETAILS(parsedInput.data.teamId));

    return success({
      memberId: member.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function removeTeamMemberAction(
  formData: FormData
): Promise<ActionResult<{ memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = removeTeamMemberSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de remoção inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const member = await removeTeamMember(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAM_DETAILS(parsedInput.data.teamId));

    return success({
      memberId: member.id
    });
  } catch (error) {
    return actionError(error);
  }
}
