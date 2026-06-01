import { z } from "zod";

const booleanStringSchema = z
  .enum(["true", "false"])
  .transform((value) => value === "true");

export const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),

  DATABASE_URL: z.string().min(1).optional(),
  DIRECT_URL: z.string().min(1).optional(),

  NEXTAUTH_SECRET: z.string().min(1).optional(),
  NEXTAUTH_URL: z.string().url().optional(),

  GOOGLE_CLIENT_ID: z.string().optional(),
  GOOGLE_CLIENT_SECRET: z.string().optional(),

  RECAPTCHA_SECRET_KEY: z.string().optional(),
  NEXT_PUBLIC_RECAPTCHA_SITE_KEY: z.string().optional(),

  PREDICTIONS_LOCKED: booleanStringSchema.default("false"),
  ALLOW_OFFICIAL_DATA_PLACEHOLDERS: booleanStringSchema.default("false"),

  SOCKET_PORT: z.coerce.number().int().positive().default(4001),
  NEXT_PUBLIC_SOCKET_URL: z.string().url().optional(),

  CLOUD_STORAGE_PROVIDER: z
    .enum(["cloudinary", "s3", "supabase", "local"])
    .default("local"),

  CLOUDINARY_CLOUD_NAME: z.string().optional(),
  CLOUDINARY_API_KEY: z.string().optional(),
  CLOUDINARY_API_SECRET: z.string().optional(),

  AWS_ACCESS_KEY_ID: z.string().optional(),
  AWS_SECRET_ACCESS_KEY: z.string().optional(),
  AWS_REGION: z.string().optional(),
  AWS_S3_BUCKET: z.string().optional(),

  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SUPABASE_BUCKET: z.string().optional()
});

export type AppEnv = z.infer<typeof envSchema>;