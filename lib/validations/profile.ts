import { z } from "zod";
import { nicknameSchema } from "./common.ts";

export const completeUserProfileSchema = z.object({
  firstName: z
    .string()
    .trim()
    .min(2, "Nome deve ter pelo menos 2 caracteres.")
    .max(80, "Nome deve ter no máximo 80 caracteres."),
  lastName: z
    .string()
    .trim()
    .min(2, "Sobrenome deve ter pelo menos 2 caracteres.")
    .max(120, "Sobrenome deve ter no máximo 120 caracteres."),
  nickname: nicknameSchema,
  birthDate: z.string().date("Data de nascimento inválida.")
});

export const updateUserProfileSchema = completeUserProfileSchema;

export type CompleteUserProfileInput = z.infer<typeof completeUserProfileSchema>;
export type UpdateUserProfileInput = z.infer<typeof updateUserProfileSchema>;
