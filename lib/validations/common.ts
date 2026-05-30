import { z } from "zod";
import { DEFAULT_PAGE, DEFAULT_PER_PAGE, MAX_PER_PAGE } from "../contracts/pagination.ts";

export const cuidSchema = z.string().min(1, "Identificador obrigatório.");

export const nonEmptyStringSchema = z.string().trim().min(1, "Campo obrigatório.");

export const optionalTrimmedStringSchema = z.string().trim().optional();

export const nullableTrimmedStringSchema = z.string().trim().nullable();

export const isoDateStringSchema = z.string().datetime("Data inválida.");

export const birthDateSchema = z.string().date("Data de nascimento inválida.");

export const paginationParamsSchema = z.object({
  page: z.coerce.number().int().positive().default(DEFAULT_PAGE),
  perPage: z.coerce.number().int().positive().max(MAX_PER_PAGE).default(DEFAULT_PER_PAGE)
});

export const slugSchema = z
  .string()
  .trim()
  .min(3, "Slug deve ter pelo menos 3 caracteres.")
  .max(60, "Slug deve ter no máximo 60 caracteres.")
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Slug inválido.");

export const nicknameSchema = z
  .string()
  .trim()
  .min(3, "Nickname deve ter pelo menos 3 caracteres.")
  .max(30, "Nickname deve ter no máximo 30 caracteres.")
  .regex(/^[a-zA-Z0-9_]+$/, "Nickname deve conter apenas letras, números e underline.");

export const urlSchema = z.string().url("URL inválida.");
