import { prisma } from "../../lib/db/prisma.ts";
import type { OfficialDataImportManifest } from "../../lib/fifa/official-import/officialDataImportTypes.ts";
import { officialDataImportManifestSchema } from "../../lib/fifa/official-import/officialDataManifestSchema.ts";
import {
  assertOfficialImportManifestConsistency,
  assertOfficialManifestIsProductionSafe
} from "../../lib/fifa/official-import/officialDataImportGuards.ts";
import { AppError } from "../../lib/errors/AppError.ts";

export type OfficialDataImportResult = {
  versionId: string;
  groupsCount: number;
  teamsCount: number;
  matchesCount: number;
  bracketSlotsCount: number;
  thirdPlaceMatrixCount: number;
};

export function parseOfficialDataManifest(rawManifest: unknown): OfficialDataImportManifest {
  const parsed = officialDataImportManifestSchema.safeParse(rawManifest);

  if (!parsed.success) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Manifesto de dados oficiais inválido.",
      statusCode: 422,
      details: parsed.error.flatten().fieldErrors
    });
  }

  assertOfficialImportManifestConsistency(parsed.data);
  assertOfficialManifestIsProductionSafe(parsed.data);

  return parsed.data;
}

export async function importOfficialDataManifest(
  rawManifest: unknown
): Promise<OfficialDataImportResult> {
  const manifest = parseOfficialDataManifest(rawManifest);

  return prisma.$transaction(async (tx) => {
    await tx.officialDataVersion.updateMany({
      where: {
        isActive: true
      },
      data: {
        isActive: false
      }
    });

    const version = await tx.officialDataVersion.create({
      data: {
        code: manifest.source.code,
        description: manifest.source.description,
        status: manifest.source.status,
        sourceDocumentRef: manifest.source.sourceDocumentRef,
        importedAt: new Date(),
        isActive: true
      }
    });

    const groupByLetter = new Map<string, { id: string }>();

    for (const group of manifest.groups) {
      const savedGroup = await tx.tournamentGroup.upsert({
        where: {
          letter: group.letter
        },
        update: {
          name: group.name,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        create: {
          letter: group.letter,
          name: group.name,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        select: {
          id: true
        }
      });

      groupByLetter.set(group.letter, savedGroup);
    }

    const teamByFifaCode = new Map<string, { id: string }>();

    for (const team of manifest.teams) {
      const group = groupByLetter.get(team.group);

      if (!group) {
        throw new AppError({
          code: "VALIDATION_ERROR",
          message: "Seleção aponta para grupo inexistente.",
          statusCode: 422
        });
      }

      const savedTeam = await tx.nationalTeam.upsert({
        where: {
          fifaCode: team.fifaCode
        },
        update: {
          name: team.name,
          shortName: team.shortName,
          flagUrl: team.flagUrl ?? null,
          groupId: group.id,
          groupPosition: team.groupPosition,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        create: {
          fifaCode: team.fifaCode,
          name: team.name,
          shortName: team.shortName,
          flagUrl: team.flagUrl ?? null,
          groupId: group.id,
          groupPosition: team.groupPosition,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        select: {
          id: true
        }
      });

      teamByFifaCode.set(team.fifaCode, savedTeam);
    }

    const bracketSlotByCode = new Map<string, { id: string }>();

    for (const slot of manifest.bracketSlots) {
      const savedSlot = await tx.officialBracketSlot.upsert({
        where: {
          slotCode: slot.slotCode
        },
        update: {
          phase: slot.phase,
          sortOrder: slot.sortOrder,
          sourceSlotCodeA: slot.sourceSlotCodeA ?? null,
          sourceSlotCodeB: slot.sourceSlotCodeB ?? null,
          winnerGoesToSlotCode: slot.winnerGoesToSlotCode ?? null,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        create: {
          slotCode: slot.slotCode,
          phase: slot.phase,
          sortOrder: slot.sortOrder,
          sourceSlotCodeA: slot.sourceSlotCodeA ?? null,
          sourceSlotCodeB: slot.sourceSlotCodeB ?? null,
          winnerGoesToSlotCode: slot.winnerGoesToSlotCode ?? null,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        select: {
          id: true
        }
      });

      bracketSlotByCode.set(slot.slotCode, savedSlot);
    }

    for (const match of manifest.matches) {
      const group = match.group ? groupByLetter.get(match.group) : null;
      const bracketSlot = match.bracketSlotCode
        ? bracketSlotByCode.get(match.bracketSlotCode)
        : null;
      const homeTeam = match.homeTeamFifaCode
        ? teamByFifaCode.get(match.homeTeamFifaCode)
        : null;
      const awayTeam = match.awayTeamFifaCode
        ? teamByFifaCode.get(match.awayTeamFifaCode)
        : null;

      await tx.officialMatch.upsert({
        where: {
          matchCode: match.matchCode
        },
        update: {
          matchNumber: match.matchNumber ?? null,
          groupId: group?.id ?? null,
          knockoutPhase: match.knockoutPhase ?? null,
          bracketSlotId: bracketSlot?.id ?? null,
          homeTeamId: homeTeam?.id ?? null,
          awayTeamId: awayTeam?.id ?? null,
          homeSlotCode: match.homeSlotCode ?? null,
          awaySlotCode: match.awaySlotCode ?? null,
          startsAt: match.startsAt ? new Date(match.startsAt) : null,
          stadium: match.stadium ?? null,
          city: match.city ?? null,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        create: {
          matchCode: match.matchCode,
          matchNumber: match.matchNumber ?? null,
          groupId: group?.id ?? null,
          knockoutPhase: match.knockoutPhase ?? null,
          bracketSlotId: bracketSlot?.id ?? null,
          homeTeamId: homeTeam?.id ?? null,
          awayTeamId: awayTeam?.id ?? null,
          homeSlotCode: match.homeSlotCode ?? null,
          awaySlotCode: match.awaySlotCode ?? null,
          startsAt: match.startsAt ? new Date(match.startsAt) : null,
          stadium: match.stadium ?? null,
          city: match.city ?? null,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        }
      });
    }

    for (const rule of manifest.thirdPlaceMatrix) {
      await tx.officialThirdPlaceMatrixRule.upsert({
        where: {
          combinationKey: rule.combinationKey
        },
        update: {
          qualifiedThirdGroups: rule.qualifiedThirdGroups,
          slotAssignments: rule.slotAssignments,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        },
        create: {
          combinationKey: rule.combinationKey,
          qualifiedThirdGroups: rule.qualifiedThirdGroups,
          slotAssignments: rule.slotAssignments,
          officialDataStatus: manifest.source.status,
          officialDataVersionId: version.id
        }
      });
    }

    return {
      versionId: version.id,
      groupsCount: manifest.groups.length,
      teamsCount: manifest.teams.length,
      matchesCount: manifest.matches.length,
      bracketSlotsCount: manifest.bracketSlots.length,
      thirdPlaceMatrixCount: manifest.thirdPlaceMatrix.length
    };
  });
}

export async function getOfficialDataVersions() {
  return prisma.officialDataVersion.findMany({
    orderBy: {
      createdAt: "desc"
    }
  });
}
