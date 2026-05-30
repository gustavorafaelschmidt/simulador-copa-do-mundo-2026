import { prisma } from "../../lib/db/prisma.ts";
import { OFFICIAL_DATA_STATUS } from "../../lib/contracts/enums.ts";
import type {
  NationalTeamDTO,
  OfficialBracketSlotDTO,
  TournamentGroupDTO
} from "../../lib/contracts/officialData.ts";
import type {
  IndividualGroupPredictionDTO,
  IndividualKnockoutPredictionDTO
} from "../../lib/contracts/prediction.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import { assertOfficialDataCanBeUsedInProduction } from "../../lib/fifa/officialDataGuards.ts";
import type {
  SaveIndividualGroupTopThreePredictionInput,
  SaveIndividualKnockoutPredictionInput
} from "../../lib/validations/individualPrediction.ts";
import { deriveFourthPlaceTeamId } from "./predictionUtils.ts";
import {
  toIndividualGroupPredictionDTO,
  toIndividualKnockoutPredictionDTO
} from "./predictionMapper.ts";

export type GroupPredictionBoardItem = TournamentGroupDTO & {
  teams: NationalTeamDTO[];
  prediction: IndividualGroupPredictionDTO | null;
};

export type KnockoutPredictionBoardItem = OfficialBracketSlotDTO & {
  prediction: IndividualKnockoutPredictionDTO | null;
};

function arePredictionsLocked(): boolean {
  return process.env.PREDICTIONS_LOCKED === "true";
}

function assertPredictionsAreOpen(): void {
  if (arePredictionsLocked()) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "As previsões estão bloqueadas no momento.",
      statusCode: 423
    });
  }
}

function toNationalTeamDTO(team: {
  id: string;
  fifaCode: string;
  name: string;
  shortName: string;
  flagUrl: string | null;
  groupId: string | null;
  group?: {
    letter: NationalTeamDTO["groupLetter"];
  } | null;
  groupPosition: number | null;
  officialDataStatus: NationalTeamDTO["officialDataStatus"];
  officialDataVersionId: string | null;
}): NationalTeamDTO {
  return {
    id: team.id,
    fifaCode: team.fifaCode,
    name: team.name,
    shortName: team.shortName,
    flagUrl: team.flagUrl,
    groupId: team.groupId,
    groupLetter: team.group?.letter ?? null,
    groupPosition: team.groupPosition,
    officialDataStatus: team.officialDataStatus,
    officialDataVersionId: team.officialDataVersionId
  };
}

function toTournamentGroupDTO(group: {
  id: string;
  letter: TournamentGroupDTO["letter"];
  name: string;
  officialDataStatus: TournamentGroupDTO["officialDataStatus"];
  officialDataVersionId: string | null;
}): TournamentGroupDTO {
  return {
    id: group.id,
    letter: group.letter,
    name: group.name,
    officialDataStatus: group.officialDataStatus,
    officialDataVersionId: group.officialDataVersionId
  };
}

function toOfficialBracketSlotDTO(slot: {
  id: string;
  slotCode: string;
  phase: OfficialBracketSlotDTO["phase"];
  sortOrder: number;
  sourceSlotCodeA: string | null;
  sourceSlotCodeB: string | null;
  winnerGoesToSlotCode: string | null;
  officialDataStatus: OfficialBracketSlotDTO["officialDataStatus"];
  officialDataVersionId: string | null;
}): OfficialBracketSlotDTO {
  return {
    id: slot.id,
    slotCode: slot.slotCode,
    phase: slot.phase,
    sortOrder: slot.sortOrder,
    sourceSlotCodeA: slot.sourceSlotCodeA,
    sourceSlotCodeB: slot.sourceSlotCodeB,
    winnerGoesToSlotCode: slot.winnerGoesToSlotCode,
    officialDataStatus: slot.officialDataStatus,
    officialDataVersionId: slot.officialDataVersionId
  };
}

export async function listGroupPredictionBoard(
  userId: string
): Promise<GroupPredictionBoardItem[]> {
  const [groups, predictions] = await Promise.all([
    prisma.tournamentGroup.findMany({
      include: {
        nationalTeams: {
          include: {
            group: {
              select: {
                letter: true
              }
            }
          },
          orderBy: {
            groupPosition: "asc"
          }
        }
      },
      orderBy: {
        letter: "asc"
      }
    }),
    prisma.individualGroupPrediction.findMany({
      where: {
        userId
      }
    })
  ]);

  const predictionsByGroup = new Map(
    predictions.map((prediction) => [prediction.group, toIndividualGroupPredictionDTO(prediction)])
  );

  return groups.map((group) => ({
    ...toTournamentGroupDTO(group),
    teams: group.nationalTeams.map(toNationalTeamDTO),
    prediction: predictionsByGroup.get(group.letter) ?? null
  }));
}

export async function listNationalTeamsForPredictionSelect(): Promise<NationalTeamDTO[]> {
  const teams = await prisma.nationalTeam.findMany({
    include: {
      group: {
        select: {
          letter: true
        }
      }
    },
    orderBy: [
      {
        group: {
          letter: "asc"
        }
      },
      {
        groupPosition: "asc"
      },
      {
        name: "asc"
      }
    ]
  });

  return teams.map(toNationalTeamDTO);
}

export async function saveIndividualGroupPrediction(
  userId: string,
  input: SaveIndividualGroupTopThreePredictionInput
): Promise<IndividualGroupPredictionDTO> {
  assertPredictionsAreOpen();

  const group = await prisma.tournamentGroup.findUnique({
    where: {
      letter: input.group
    },
    include: {
      nationalTeams: {
        orderBy: {
          groupPosition: "asc"
        }
      }
    }
  });

  if (!group) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Grupo não encontrado.",
      statusCode: 404
    });
  }

  assertOfficialDataCanBeUsedInProduction([
    {
      id: group.id,
      officialDataStatus: group.officialDataStatus,
      officialDataVersionId: group.officialDataVersionId
    },
    ...group.nationalTeams.map((team) => ({
      id: team.id,
      officialDataStatus: team.officialDataStatus,
      officialDataVersionId: team.officialDataVersionId
    }))
  ]);

  const groupTeamIds = group.nationalTeams.map((team) => team.id);
  const fourthPlaceTeamId = deriveFourthPlaceTeamId(groupTeamIds, [
    input.firstPlaceTeamId,
    input.secondPlaceTeamId,
    input.thirdPlaceTeamId
  ]);

  const prediction = await prisma.individualGroupPrediction.upsert({
    where: {
      userId_group: {
        userId,
        group: input.group
      }
    },
    update: {
      firstPlaceTeamId: input.firstPlaceTeamId,
      secondPlaceTeamId: input.secondPlaceTeamId,
      thirdPlaceTeamId: input.thirdPlaceTeamId,
      fourthPlaceTeamId,
      submittedAt: new Date()
    },
    create: {
      userId,
      group: input.group,
      firstPlaceTeamId: input.firstPlaceTeamId,
      secondPlaceTeamId: input.secondPlaceTeamId,
      thirdPlaceTeamId: input.thirdPlaceTeamId,
      fourthPlaceTeamId,
      submittedAt: new Date()
    }
  });

  return toIndividualGroupPredictionDTO(prediction);
}

export async function listKnockoutPredictionBoard(
  userId: string
): Promise<KnockoutPredictionBoardItem[]> {
  const [slots, predictions] = await Promise.all([
    prisma.officialBracketSlot.findMany({
      orderBy: [
        {
          phase: "asc"
        },
        {
          sortOrder: "asc"
        }
      ]
    }),
    prisma.individualKnockoutPrediction.findMany({
      where: {
        userId
      }
    })
  ]);

  const predictionsBySlot = new Map(
    predictions.map((prediction) => [
      prediction.bracketSlotId,
      toIndividualKnockoutPredictionDTO(prediction)
    ])
  );

  return slots.map((slot) => ({
    ...toOfficialBracketSlotDTO(slot),
    prediction: predictionsBySlot.get(slot.id) ?? null
  }));
}

export async function saveIndividualKnockoutPrediction(
  userId: string,
  input: SaveIndividualKnockoutPredictionInput
): Promise<IndividualKnockoutPredictionDTO> {
  assertPredictionsAreOpen();

  const [slot, winnerTeam] = await Promise.all([
    prisma.officialBracketSlot.findUnique({
      where: {
        id: input.bracketSlotId
      }
    }),
    prisma.nationalTeam.findUnique({
      where: {
        id: input.winnerTeamId
      }
    })
  ]);

  if (!slot) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Slot de mata-mata não encontrado.",
      statusCode: 404
    });
  }

  if (!winnerTeam) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Seleção vencedora não encontrada.",
      statusCode: 404
    });
  }

  assertOfficialDataCanBeUsedInProduction([
    {
      id: slot.id,
      officialDataStatus: slot.officialDataStatus,
      officialDataVersionId: slot.officialDataVersionId
    },
    {
      id: winnerTeam.id,
      officialDataStatus: winnerTeam.officialDataStatus,
      officialDataVersionId: winnerTeam.officialDataVersionId
    }
  ]);

  if (slot.officialDataStatus === OFFICIAL_DATA_STATUS.PLACEHOLDER) {
    /*
      Desenvolvimento/teste:
      slots placeholder existem apenas para permitir construção incremental.
      Produção já é bloqueada pelo guard acima.
    */
  }

  const prediction = await prisma.individualKnockoutPrediction.upsert({
    where: {
      userId_bracketSlotId: {
        userId,
        bracketSlotId: input.bracketSlotId
      }
    },
    update: {
      winnerTeamId: input.winnerTeamId,
      submittedAt: new Date()
    },
    create: {
      userId,
      bracketSlotId: input.bracketSlotId,
      winnerTeamId: input.winnerTeamId,
      submittedAt: new Date()
    }
  });

  return toIndividualKnockoutPredictionDTO(prediction);
}
