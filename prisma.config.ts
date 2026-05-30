import "dotenv/config";
import { defineConfig } from "prisma/config";

const migrationDatabaseUrl = process.env.DIRECT_URL ?? process.env.DATABASE_URL;

if (!migrationDatabaseUrl) {
  throw new Error(
    "DATABASE_URL ou DIRECT_URL deve estar definido para executar comandos do Prisma."
  );
}

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: "tsx prisma/seed.ts"
  },
  datasource: {
    // DIRECT_URL pode ser usado para migrations/deploy quando DATABASE_URL usa pooling.
    url: migrationDatabaseUrl
  }
});