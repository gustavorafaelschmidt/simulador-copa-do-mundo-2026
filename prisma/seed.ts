import "dotenv/config";
import { PrismaClient } from "./generated/client/client";
import { PrismaPg } from "@prisma/adapter-pg";
import {
  AuthProvider,
  BadgeRarity,
  BadgeTargetType,
  GlobalRole,
  GroupLetter,
  KnockoutPhase,
  OfficialDataStatus
} from "./generated/client/enums";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL deve estar definido para executar o seed.");
}

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

const isProduction = process.env.NODE_ENV === "production";
const allowOfficialPlaceholders = process.env.ALLOW_OFFICIAL_DATA_PLACEHOLDERS === "true";

/*
  Proteção crítica:
  placeholders oficiais são permitidos apenas para desenvolvimento/teste.
  Em produção, dados oficiais devem vir de documentos oficiais versionados.
*/
if (isProduction && !allowOfficialPlaceholders) {
  throw new Error(
    "Seed bloqueado: placeholders de dados oficiais não podem ser usados em produção."
  );
}

const groupLetters = [
  GroupLetter.A,
  GroupLetter.B,
  GroupLetter.C,
  GroupLetter.D,
  GroupLetter.E,
  GroupLetter.F,
  GroupLetter.G,
  GroupLetter.H,
  GroupLetter.I,
  GroupLetter.J,
  GroupLetter.K,
  GroupLetter.L
] as const;

async function seedOfficialDataVersion() {
  return prisma.officialDataVersion.upsert({
    where: {
      code: "placeholder-2026-v1"
    },
    update: {
      description:
        "Versão placeholder para desenvolvimento. Deve ser substituída por dados oficiais FIFA.",
      status: OfficialDataStatus.PLACEHOLDER,
      sourceDocumentRef:
        "TODO: substituir por documentos oficiais FIFA da Copa do Mundo 2026.",
      isActive: true
    },
    create: {
      code: "placeholder-2026-v1",
      description:
        "Versão placeholder para desenvolvimento. Deve ser substituída por dados oficiais FIFA.",
      status: OfficialDataStatus.PLACEHOLDER,
      sourceDocumentRef:
        "TODO: substituir por documentos oficiais FIFA da Copa do Mundo 2026.",
      importedAt: new Date(),
      isActive: true
    }
  });
}

async function seedBadges() {
  const badges = [
    {
      code: "FIRST_PREDICTION",
      name: "Primeira previsão",
      description: "Concedida ao usuário após registrar sua primeira previsão.",
      targetType: BadgeTargetType.USER,
      rarity: BadgeRarity.COMMON,
      iconKey: "first-prediction"
    },
    {
      code: "GROUP_STAGE_SPECIALIST",
      name: "Especialista em grupos",
      description: "Concedida ao usuário com alto desempenho na fase de grupos.",
      targetType: BadgeTargetType.USER,
      rarity: BadgeRarity.RARE,
      iconKey: "group-stage-specialist"
    },
    {
      code: "KNOCKOUT_MASTER",
      name: "Mestre do mata-mata",
      description: "Concedida ao usuário com alto desempenho no mata-mata.",
      targetType: BadgeTargetType.USER,
      rarity: BadgeRarity.EPIC,
      iconKey: "knockout-master"
    },
    {
      code: "TEAM_CONSENSUS",
      name: "Consenso de equipe",
      description: "Concedida à equipe que participar de votações colaborativas.",
      targetType: BadgeTargetType.TEAM,
      rarity: BadgeRarity.COMMON,
      iconKey: "team-consensus"
    },
    {
      code: "CAPTAIN_DECIDER",
      name: "Voto de minerva",
      description: "Concedida à equipe quando o capitão resolver um empate.",
      targetType: BadgeTargetType.TEAM,
      rarity: BadgeRarity.RARE,
      iconKey: "captain-decider"
    }
  ];

  for (const badge of badges) {
    await prisma.badge.upsert({
      where: {
        code: badge.code
      },
      update: {
        name: badge.name,
        description: badge.description,
        targetType: badge.targetType,
        rarity: badge.rarity,
        iconKey: badge.iconKey,
        isActive: true
      },
      create: badge
    });
  }
}

async function seedTournamentGroups(officialDataVersionId: string) {
  for (const letter of groupLetters) {
    await prisma.tournamentGroup.upsert({
      where: {
        letter
      },
      update: {
        name: `Grupo ${letter}`,
        officialDataStatus: OfficialDataStatus.PLACEHOLDER,
        officialDataVersionId,
        sourceDocumentRef:
          "TODO: substituir por documento oficial FIFA com grupos da Copa 2026."
      },
      create: {
        letter,
        name: `Grupo ${letter}`,
        officialDataStatus: OfficialDataStatus.PLACEHOLDER,
        officialDataVersionId,
        sourceDocumentRef:
          "TODO: substituir por documento oficial FIFA com grupos da Copa 2026."
      }
    });
  }
}

async function seedPlaceholderNationalTeams(officialDataVersionId: string) {
  /*
    TODO FIFA:
    Substituir por seleções oficiais, códigos FIFA reais, grupos oficiais
    e URLs de bandeiras assim que os documentos oficiais forem fornecidos.
  */
  const groups = await prisma.tournamentGroup.findMany({
    orderBy: {
      letter: "asc"
    }
  });

  for (const group of groups) {
    for (let position = 1; position <= 4; position += 1) {
      const fifaCode = `TBD_${group.letter}${position}`;

      await prisma.nationalTeam.upsert({
        where: {
          fifaCode
        },
        update: {
          name: `Seleção pendente ${group.letter}${position}`,
          shortName: `Pendente ${group.letter}${position}`,
          flagUrl: null,
          groupId: group.id,
          groupPosition: position,
          officialDataStatus: OfficialDataStatus.PLACEHOLDER,
          officialDataVersionId,
          sourceDocumentRef:
            "TODO: substituir por seleções oficiais FIFA 2026, códigos e bandeiras."
        },
        create: {
          fifaCode,
          name: `Seleção pendente ${group.letter}${position}`,
          shortName: `Pendente ${group.letter}${position}`,
          flagUrl: null,
          groupId: group.id,
          groupPosition: position,
          officialDataStatus: OfficialDataStatus.PLACEHOLDER,
          officialDataVersionId,
          sourceDocumentRef:
            "TODO: substituir por seleções oficiais FIFA 2026, códigos e bandeiras."
        }
      });
    }
  }
}

async function seedPlaceholderBracketSlots(officialDataVersionId: string) {
  /*
    TODO FIFA:
    Estes slots são apenas estrutura técnica.
    Não representam chaveamento oficial.
    A matriz oficial dos terceiros colocados ainda precisa ser importada
    a partir de documento oficial fornecido.
  */
  const slots: Array<{
    slotCode: string;
    phase: KnockoutPhase;
    sortOrder: number;
  }> = [
    ...Array.from({ length: 16 }, (_, index) => ({
      slotCode: `R32_${String(index + 1).padStart(2, "0")}`,
      phase: KnockoutPhase.ROUND_OF_32,
      sortOrder: index + 1
    })),
    ...Array.from({ length: 8 }, (_, index) => ({
      slotCode: `R16_${String(index + 1).padStart(2, "0")}`,
      phase: KnockoutPhase.ROUND_OF_16,
      sortOrder: index + 1
    })),
    ...Array.from({ length: 4 }, (_, index) => ({
      slotCode: `QF_${String(index + 1).padStart(2, "0")}`,
      phase: KnockoutPhase.QUARTER_FINAL,
      sortOrder: index + 1
    })),
    ...Array.from({ length: 2 }, (_, index) => ({
      slotCode: `SF_${String(index + 1).padStart(2, "0")}`,
      phase: KnockoutPhase.SEMI_FINAL,
      sortOrder: index + 1
    })),
    {
      slotCode: "THIRD_PLACE",
      phase: KnockoutPhase.THIRD_PLACE,
      sortOrder: 1
    },
    {
      slotCode: "FINAL",
      phase: KnockoutPhase.FINAL,
      sortOrder: 1
    }
  ];

  for (const slot of slots) {
    await prisma.officialBracketSlot.upsert({
      where: {
        slotCode: slot.slotCode
      },
      update: {
        phase: slot.phase,
        sortOrder: slot.sortOrder,
        officialDataStatus: OfficialDataStatus.PLACEHOLDER,
        officialDataVersionId,
        sourceDocumentRef:
          "TODO: substituir por chaveamento oficial FIFA 2026."
      },
      create: {
        slotCode: slot.slotCode,
        phase: slot.phase,
        sortOrder: slot.sortOrder,
        officialDataStatus: OfficialDataStatus.PLACEHOLDER,
        officialDataVersionId,
        sourceDocumentRef:
          "TODO: substituir por chaveamento oficial FIFA 2026."
      }
    });
  }
}

async function seedDevelopmentAdminUser() {
  if (isProduction) {
    return;
  }

  await prisma.user.upsert({
    where: {
      email: "admin@simulador.local"
    },
    update: {
      name: "Admin Local",
      firstName: "Admin",
      lastName: "Local",
      nickname: "admin",
      globalRole: GlobalRole.ADMIN_GLOBAL,
      primaryAuthProvider: AuthProvider.CREDENTIALS,
      profileCompletedAt: new Date(),
      onboardingCompletedAt: new Date()
    },
    create: {
      name: "Admin Local",
      firstName: "Admin",
      lastName: "Local",
      email: "admin@simulador.local",
      nickname: "admin",
      globalRole: GlobalRole.ADMIN_GLOBAL,
      primaryAuthProvider: AuthProvider.CREDENTIALS,
      profileCompletedAt: new Date(),
      onboardingCompletedAt: new Date()
    }
  });
}

async function main() {
  const officialDataVersion = await seedOfficialDataVersion();

  await seedBadges();
  await seedTournamentGroups(officialDataVersion.id);
  await seedPlaceholderNationalTeams(officialDataVersion.id);
  await seedPlaceholderBracketSlots(officialDataVersion.id);
  await seedDevelopmentAdminUser();

  console.info("Seed do Bloco 1 executado com sucesso.");
  console.info(
    "Atenção: dados oficiais ainda são PLACEHOLDER e não podem ser usados como chaveamento oficial em produção."
  );
}

main()
  .catch((error: unknown) => {
    console.error("Erro ao executar seed do Bloco 1:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });