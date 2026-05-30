import { z } from "zod";
import { TEAM_MEMBER_ROLE_VALUES } from "@/lib/contracts/enums";
import { cuidSchema, slugSchema } from "@/lib/validations/common";

export const createTeamSchema = z.object({
  name: z
    .string()
    .trim()
    .min(3, "Nome da equipe deve ter pelo menos 3 caracteres.")
    .max(80, "Nome da equipe deve ter no máximo 80 caracteres."),
  slug: slugSchema.optional(),
  description: z
    .string()
    .trim()
    .max(500, "Descrição deve ter no máximo 500 caracteres.")
    .optional(),
  maxMembers: z.coerce.number().int().min(2).max(100).optional()
});

export const updateTeamSchema = z.object({
  teamId: cuidSchema,
  name: z
    .string()
    .trim()
    .min(3, "Nome da equipe deve ter pelo menos 3 caracteres.")
    .max(80, "Nome da equipe deve ter no máximo 80 caracteres.")
    .optional(),
  description: z
    .string()
    .trim()
    .max(500, "Descrição deve ter no máximo 500 caracteres.")
    .nullable()
    .optional(),
  maxMembers: z.coerce.number().int().min(2).max(100).optional()
});

export const joinTeamByCodeSchema = z.object({
  inviteCode: z
    .string()
    .trim()
    .min(6, "Código de convite inválido.")
    .max(40, "Código de convite inválido.")
});

export const reviewTeamMemberSchema = z.object({
  teamId: cuidSchema,
  memberId: cuidSchema,
  approvalStatus: z.enum(["APPROVED", "REJECTED"])
});

export const changeTeamMemberRoleSchema = z.object({
  teamId: cuidSchema,
  memberId: cuidSchema,
  role: z.enum(TEAM_MEMBER_ROLE_VALUES).refine((role) => role !== "CAPTAIN", {
    message: "O papel CAPTAIN não pode ser atribuído por esta ação."
  })
});

export const removeTeamMemberSchema = z.object({
  teamId: cuidSchema,
  memberId: cuidSchema
});

export type CreateTeamInput = z.infer<typeof createTeamSchema>;
export type UpdateTeamInput = z.infer<typeof updateTeamSchema>;
export type JoinTeamByCodeInput = z.infer<typeof joinTeamByCodeSchema>;
export type ReviewTeamMemberInput = z.infer<typeof reviewTeamMemberSchema>;
export type ChangeTeamMemberRoleInput = z.infer<typeof changeTeamMemberRoleSchema>;
export type RemoveTeamMemberInput = z.infer<typeof removeTeamMemberSchema>;
