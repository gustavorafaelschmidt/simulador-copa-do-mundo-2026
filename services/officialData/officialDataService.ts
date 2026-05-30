import { prisma } from "@/lib/db/prisma";
import { assertOfficialDataCanBeUsedInProduction } from "@/lib/fifa/officialDataGuards";

export async function getActiveOfficialDataVersion() {
  return prisma.officialDataVersion.findFirst({
    where: {
      isActive: true
    },
    orderBy: {
      createdAt: "desc"
    }
  });
}

export async function getOfficialDataReadinessReport() {
  const [groups, nationalTeams, bracketSlots, thirdPlaceRules] = await Promise.all([
    prisma.tournamentGroup.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    }),
    prisma.nationalTeam.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    }),
    prisma.officialBracketSlot.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    }),
    prisma.officialThirdPlaceMatrixRule.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    })
  ]);

  return assertOfficialDataCanBeUsedInProduction([
    ...groups,
    ...nationalTeams,
    ...bracketSlots,
    ...thirdPlaceRules
  ]);
}

export async function listGroupsWithTeams() {
  return prisma.tournamentGroup.findMany({
    include: {
      nationalTeams: {
        orderBy: {
          groupPosition: "asc"
        }
      }
    },
    orderBy: {
      letter: "asc"
    }
  });
}
