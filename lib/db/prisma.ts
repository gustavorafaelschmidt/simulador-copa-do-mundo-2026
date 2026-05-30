import { PrismaClient } from "../../prisma/generated/client/client.ts";
import { PrismaPg } from "@prisma/adapter-pg";

const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient;
};

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL deve estar definido para inicializar o Prisma Client.");
}

function createPrismaClient() {
  const adapter = new PrismaPg({ connectionString });

  return new PrismaClient({
    adapter,
    log:
      process.env.NODE_ENV === "development"
        ? ["query", "info", "warn", "error"]
        : ["warn", "error"]
  });
}

/*
  Singleton seguro em desenvolvimento:
  evita múltiplas instâncias do Prisma Client durante hot reload do Next.js.
  Em produção, cada processo cria seu próprio client normalmente.
*/
export const prisma = globalForPrisma.prisma ?? createPrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}

export default prisma;