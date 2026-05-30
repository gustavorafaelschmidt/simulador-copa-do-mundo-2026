import { z } from "zod";
import { nicknameSchema } from "./common.ts";

export const emailSchema = z
  .string()
  .trim()
  .email("Email inválido.")
  .max(254, "Email muito longo.")
  .transform((value) => value.toLowerCase());

export const passwordSchema = z
  .string()
  .min(8, "Senha deve ter pelo menos 8 caracteres.")
  .max(128, "Senha deve ter no máximo 128 caracteres.")
  .regex(/[A-Z]/, "Senha deve conter pelo menos uma letra maiúscula.")
  .regex(/[a-z]/, "Senha deve conter pelo menos uma letra minúscula.")
  .regex(/[0-9]/, "Senha deve conter pelo menos um número.");

export const registerWithCredentialsSchema = z
  .object({
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
    birthDate: z.string().date("Data de nascimento inválida."),
    email: emailSchema,
    password: passwordSchema,
    confirmPassword: z.string().min(1, "Confirmação de senha obrigatória.")
  })
  .refine((data) => data.password === data.confirmPassword, {
    path: ["confirmPassword"],
    message: "As senhas não conferem."
  });

export const loginWithCredentialsSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, "Senha obrigatória.")
});

export type RegisterWithCredentialsInput = z.infer<typeof registerWithCredentialsSchema>;
export type LoginWithCredentialsInput = z.infer<typeof loginWithCredentialsSchema>;
