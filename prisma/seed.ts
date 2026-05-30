import "dotenv/config";
import { PrismaClient } from "./generated/client/client";
import { PrismaPg } from "@prisma/adapter-pg";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL deve estar definido para executar o seed.");
}

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

async function main() {
  /*
    Bloco 0:
    Nenhum dado oficial da Copa é inserido aqui.

    Nos próximos blocos, dados oficiais versionados devem ser carregados somente
    a partir de documentos oficiais fornecidos pelo usuário. Placeholders oficiais
    não podem ser usados em produção.
  */
  console.info("Seed inicial executado. Nenhum dado oficial foi inserido no Bloco 0.");
}

main()
  .catch((error: unknown) => {
    console.error("Erro ao executar seed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });