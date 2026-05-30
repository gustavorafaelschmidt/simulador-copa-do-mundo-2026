import { envSchema } from "@/lib/validations/env";

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error("Variáveis de ambiente inválidas:", parsedEnv.error.flatten().fieldErrors);

  throw new Error("Falha na validação das variáveis de ambiente.");
}

/*
  Importar este módulo apenas em código server-side.
  Variáveis secretas nunca devem ser importadas por Client Components.
*/
export const env = parsedEnv.data;

export const isDevelopment = env.NODE_ENV === "development";
export const isTest = env.NODE_ENV === "test";
export const isProduction = env.NODE_ENV === "production";