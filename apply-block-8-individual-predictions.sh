#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 8 — previsões individuais de grupos e mata-mata..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/prediction
mkdir -p actions
mkdir -p app/dashboard/previsoes/grupos
mkdir -p app/dashboard/previsoes/mata-mata
mkdir -p docs
mkdir -p tests

cat > lib/validations/individualPrediction.ts <<'EOF'
import { z } from "zod";
import {
  groupLetterSchema,
  nationalTeamIdSchema,
  officialBracketSlotIdSchema
} from "./officialData.ts";

function hasDistinctTopThreeTeams(value: {
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
}) {
  const ids = [value.firstPlaceTeamId, value.secondPlaceTeamId, value.thirdPlaceTeamId];

  return new Set(ids).size === ids.length;
}

export const saveIndividualGroupTopThreePredictionSchema = z
  .object({
    group: groupLetterSchema,
    firstPlaceTeamId: nationalTeamIdSchema,
    secondPlaceTeamId: nationalTeamIdSchema,
    thirdPlaceTeamId: nationalTeamIdSchema
  })
  .refine(hasDistinctTopThreeTeams, {
    message: "1º, 2º e 3º colocados devem ser seleções diferentes."
  });

export const saveIndividualKnockoutPredictionInputSchema = z.object({
  bracketSlotId: officialBracketSlotIdSchema,
  winnerTeamId: nationalTeamIdSchema
});

export type SaveIndividualGroupTopThreePredictionInput = z.infer<
  typeof saveIndividualGroupTopThreePredictionSchema
>;

export type SaveIndividualKnockoutPredictionInput = z.infer<
  typeof saveIndividualKnockoutPredictionInputSchema
>;
EOF

cat > services/prediction/predictionUtils.ts <<'EOF'
import { AppError } from "../../lib/errors/AppError.ts";

export function assertDistinctTeamIds(teamIds: string[]): void {
  if (teamIds.some((teamId) => !teamId || teamId.trim().length === 0)) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as seleções obrigatórias devem ser informadas.",
      statusCode: 422
    });
  }

  if (new Set(teamIds).size !== teamIds.length) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Uma mesma seleção não pode ocupar mais de uma posição.",
      statusCode: 422
    });
  }
}

export function deriveFourthPlaceTeamId(
  groupTeamIds: string[],
  selectedTopThreeTeamIds: string[]
): string {
  assertDistinctTeamIds(selectedTopThreeTeamIds);

  const uniqueGroupTeamIds = [...new Set(groupTeamIds)];

  if (uniqueGroupTeamIds.length !== 4) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "O grupo precisa ter exatamente quatro seleções para calcular o 4º colocado.",
      statusCode: 500,
      details: {
        groupTeamCount: uniqueGroupTeamIds.length
      }
    });
  }

  const invalidSelections = selectedTopThreeTeamIds.filter(
    (teamId) => !uniqueGroupTeamIds.includes(teamId)
  );

  if (invalidSelections.length > 0) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as seleções escolhidas devem pertencer ao grupo informado.",
      statusCode: 422,
      details: {
        invalidSelections
      }
    });
  }

  const fourthPlaceTeamId = uniqueGroupTeamIds.find(
    (teamId) => !selectedTopThreeTeamIds.includes(teamId)
  );

  if (!fourthPlaceTeamId) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Não foi possível calcular o 4º colocado do grupo.",
      statusCode: 422
    });
  }

  return fourthPlaceTeamId;
}

export function buildPredictionLockErrorMessage(): string {
  return "As previsões estão bloqueadas no momento.";
}
EOF

cat > services/prediction/predictionMapper.ts <<'EOF'
import type { IndividualGroupPredictionDTO, IndividualKnockoutPredictionDTO } from "../../lib/contracts/prediction.ts";

export type IndividualGroupPredictionRecord = {
  id: string;
  userId: string;
  group: IndividualGroupPredictionDTO["group"];
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
  fourthPlaceTeamId: string;
  lockedAt: Date | null;
  submittedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export type IndividualKnockoutPredictionRecord = {
  id: string;
  userId: string;
  bracketSlotId: string;
  winnerTeamId: string;
  lockedAt: Date | null;
  submittedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export function toIndividualGroupPredictionDTO(
  prediction: IndividualGroupPredictionRecord
): IndividualGroupPredictionDTO {
  return {
    id: prediction.id,
    userId: prediction.userId,
    group: prediction.group,
    firstPlaceTeamId: prediction.firstPlaceTeamId,
    secondPlaceTeamId: prediction.secondPlaceTeamId,
    thirdPlaceTeamId: prediction.thirdPlaceTeamId,
    fourthPlaceTeamId: prediction.fourthPlaceTeamId,
    lockedAt: prediction.lockedAt?.toISOString() ?? null,
    submittedAt: prediction.submittedAt?.toISOString() ?? null,
    createdAt: prediction.createdAt.toISOString(),
    updatedAt: prediction.updatedAt.toISOString()
  };
}

export function toIndividualKnockoutPredictionDTO(
  prediction: IndividualKnockoutPredictionRecord
): IndividualKnockoutPredictionDTO {
  return {
    id: prediction.id,
    userId: prediction.userId,
    bracketSlotId: prediction.bracketSlotId,
    winnerTeamId: prediction.winnerTeamId,
    lockedAt: prediction.lockedAt?.toISOString() ?? null,
    submittedAt: prediction.submittedAt?.toISOString() ?? null,
    createdAt: prediction.createdAt.toISOString(),
    updatedAt: prediction.updatedAt.toISOString()
  };
}
EOF

cat > services/prediction/predictionService.ts <<'EOF'
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
EOF

cat > services/prediction/index.ts <<'EOF'
export * from "./predictionUtils.ts";
export * from "./predictionMapper.ts";
export * from "./predictionService.ts";
EOF

cat > actions/prediction.ts <<'EOF'
"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import { error as actionError, success, validationError } from "../lib/errors/actionResponses.ts";
import { requireCurrentUser } from "../lib/auth/currentUser";
import {
  saveIndividualGroupTopThreePredictionSchema,
  saveIndividualKnockoutPredictionInputSchema
} from "../lib/validations/individualPrediction.ts";
import {
  saveIndividualGroupPrediction,
  saveIndividualKnockoutPrediction
} from "../services/prediction/predictionService.ts";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  return Object.fromEntries(formData.entries());
}

export async function saveIndividualGroupPredictionAction(
  formData: FormData
): Promise<ActionResult<{ predictionId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = saveIndividualGroupTopThreePredictionSchema.safeParse(
    formDataToObject(formData)
  );

  if (!parsedInput.success) {
    return validationError("Previsão de grupo inválida.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const prediction = await saveIndividualGroupPrediction(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      predictionId: prediction.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function saveIndividualKnockoutPredictionAction(
  formData: FormData
): Promise<ActionResult<{ predictionId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = saveIndividualKnockoutPredictionInputSchema.safeParse(
    formDataToObject(formData)
  );

  if (!parsedInput.success) {
    return validationError(
      "Previsão de mata-mata inválida.",
      parsedInput.error.flatten().fieldErrors
    );
  }

  try {
    const prediction = await saveIndividualKnockoutPrediction(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      predictionId: prediction.id
    });
  } catch (error) {
    return actionError(error);
  }
}
EOF

node <<'NODE'
const fs = require("node:fs");

const routesPath = "lib/contracts/routes.ts";
let source = fs.readFileSync(routesPath, "utf8");

if (!source.includes('PREDICTIONS: "/dashboard/previsoes"')) {
  source = source.replace(
    'DASHBOARD: "/dashboard",',
    'DASHBOARD: "/dashboard",\n  PREDICTIONS: "/dashboard/previsoes",\n  PREDICTIONS_GROUPS: "/dashboard/previsoes/grupos",\n  PREDICTIONS_KNOCKOUT: "/dashboard/previsoes/mata-mata",'
  );
}

fs.writeFileSync(routesPath, source);
NODE

cat > app/dashboard/previsoes/page.tsx <<'EOF'
import Link from "next/link";
import { APP_ROUTES } from "../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../lib/auth/currentUser";

export default async function PredictionsPage() {
  await requireCurrentUser();

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-4xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Previsões individuais
        </p>

        <h1 className="mt-3 text-2xl font-bold">Monte seu palpite da Copa 2026</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Salve suas previsões individuais para fase de grupos e mata-mata. As regras
          oficiais completas serão aplicadas conforme os dados oficiais versionados forem
          substituindo os placeholders.
        </p>

        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <Link
            className="rounded-xl border border-app-border p-5 transition hover:border-app-primary"
            href={APP_ROUTES.PREDICTIONS_GROUPS}
          >
            <h2 className="font-semibold">Fase de grupos</h2>
            <p className="mt-2 text-sm text-app-muted">
              Escolha 1º, 2º e 3º colocados. O 4º é calculado automaticamente.
            </p>
          </Link>

          <Link
            className="rounded-xl border border-app-border p-5 transition hover:border-app-primary"
            href={APP_ROUTES.PREDICTIONS_KNOCKOUT}
          >
            <h2 className="font-semibold">Mata-mata</h2>
            <p className="mt-2 text-sm text-app-muted">
              Estrutura preparada para os slots oficiais de 16-avos até a final.
            </p>
          </Link>
        </div>
      </section>
    </main>
  );
}
EOF

cat > app/dashboard/previsoes/grupos/page.tsx <<'EOF'
import Link from "next/link";
import { saveIndividualGroupPredictionAction } from "../../../../actions/prediction.ts";
import { APP_ROUTES } from "../../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../../lib/auth/currentUser";
import { listGroupPredictionBoard } from "../../../../services/prediction/predictionService.ts";

export default async function GroupPredictionsPage() {
  const user = await requireCurrentUser();
  const groups = await listGroupPredictionBoard(user.id);

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-6xl">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.PREDICTIONS}>
          ← Voltar para previsões
        </Link>

        <div className="mt-4 rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Fase de grupos
          </p>

          <h1 className="mt-3 text-2xl font-bold">Previsões dos grupos</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Selecione 1º, 2º e 3º colocados de cada grupo. O backend calcula e
            persiste automaticamente o 4º colocado para manter consistência.
          </p>
        </div>

        <div className="mt-6 grid gap-4 lg:grid-cols-2">
          {groups.map((group) => (
            <article
              key={group.id}
              className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h2 className="text-xl font-bold">{group.name}</h2>
                  <p className="mt-1 text-sm text-app-muted">
                    Status dos dados: {group.officialDataStatus}
                  </p>
                </div>

                {group.prediction ? (
                  <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-800">
                    Salvo
                  </span>
                ) : null}
              </div>

              <form action={saveIndividualGroupPredictionAction} className="mt-5 space-y-4">
                <input name="group" type="hidden" value={group.letter} />

                {[
                  ["firstPlaceTeamId", "1º colocado"],
                  ["secondPlaceTeamId", "2º colocado"],
                  ["thirdPlaceTeamId", "3º colocado"]
                ].map(([fieldName, label]) => (
                  <label className="block" key={fieldName}>
                    <span className="text-sm font-medium">{label}</span>
                    <select
                      className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                      name={fieldName}
                      required
                      defaultValue={
                        fieldName === "firstPlaceTeamId"
                          ? group.prediction?.firstPlaceTeamId ?? ""
                          : fieldName === "secondPlaceTeamId"
                            ? group.prediction?.secondPlaceTeamId ?? ""
                            : group.prediction?.thirdPlaceTeamId ?? ""
                      }
                    >
                      <option value="">Selecione</option>
                      {group.teams.map((team) => (
                        <option key={team.id} value={team.id}>
                          {team.groupPosition}. {team.shortName}
                        </option>
                      ))}
                    </select>
                  </label>
                ))}

                <button
                  className="w-full rounded-xl bg-app-primary px-4 py-2 font-semibold text-white"
                  type="submit"
                >
                  Salvar grupo {group.letter}
                </button>
              </form>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
EOF

cat > app/dashboard/previsoes/mata-mata/page.tsx <<'EOF'
import Link from "next/link";
import { saveIndividualKnockoutPredictionAction } from "../../../../actions/prediction.ts";
import { APP_ROUTES } from "../../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../../lib/auth/currentUser";
import {
  listKnockoutPredictionBoard,
  listNationalTeamsForPredictionSelect
} from "../../../../services/prediction/predictionService.ts";

export default async function KnockoutPredictionsPage() {
  const user = await requireCurrentUser();
  const [slots, teams] = await Promise.all([
    listKnockoutPredictionBoard(user.id),
    listNationalTeamsForPredictionSelect()
  ]);

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-6xl">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.PREDICTIONS}>
          ← Voltar para previsões
        </Link>

        <div className="mt-4 rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Mata-mata
          </p>

          <h1 className="mt-3 text-2xl font-bold">Previsões do mata-mata</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Os slots ainda podem estar como placeholders em desenvolvimento. Em produção,
            o backend bloqueia uso de dados oficiais incompletos.
          </p>
        </div>

        <div className="mt-6 grid gap-4 lg:grid-cols-2">
          {slots.map((slot) => (
            <article
              key={slot.id}
              className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">{slot.slotCode}</h2>
                  <p className="mt-1 text-sm text-app-muted">
                    Fase: {slot.phase} · Status: {slot.officialDataStatus}
                  </p>
                </div>

                {slot.prediction ? (
                  <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-800">
                    Salvo
                  </span>
                ) : null}
              </div>

              <form action={saveIndividualKnockoutPredictionAction} className="mt-5 space-y-4">
                <input name="bracketSlotId" type="hidden" value={slot.id} />

                <label className="block">
                  <span className="text-sm font-medium">Vencedor previsto</span>
                  <select
                    className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                    name="winnerTeamId"
                    required
                    defaultValue={slot.prediction?.winnerTeamId ?? ""}
                  >
                    <option value="">Selecione</option>
                    {teams.map((team) => (
                      <option key={team.id} value={team.id}>
                        {team.groupLetter ? `Grupo ${team.groupLetter} · ` : ""}
                        {team.shortName}
                      </option>
                    ))}
                  </select>
                </label>

                <button
                  className="w-full rounded-xl bg-app-primary px-4 py-2 font-semibold text-white"
                  type="submit"
                >
                  Salvar previsão
                </button>
              </form>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
EOF

cat > docs/individual-predictions.md <<'EOF'
# Bloco 8 — Previsões individuais

## Objetivo

Permitir que usuários autenticados salvem previsões individuais de fase de grupos e mata-mata.

## Fase de grupos

O usuário seleciona:

- 1º colocado;
- 2º colocado;
- 3º colocado.

O backend calcula automaticamente o 4º colocado a partir das quatro seleções do grupo.

## Mata-mata

O usuário escolhe um vencedor por slot de mata-mata.

Enquanto os dados oficiais não estiverem completos, slots podem existir como placeholders em desenvolvimento. Em produção, o guard de dados oficiais bloqueia uso incorreto.

## Integridade

- Uma previsão de grupo por usuário/grupo.
- Uma previsão de mata-mata por usuário/slot.
- Upsert para permitir edição antes do bloqueio.
- `PREDICTIONS_LOCKED=true` bloqueia novas alterações.
EOF

cat > tests/prediction.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { AppError } from "../lib/errors/AppError.ts";
import {
  assertDistinctTeamIds,
  deriveFourthPlaceTeamId
} from "../services/prediction/predictionUtils.ts";
import {
  toIndividualGroupPredictionDTO,
  toIndividualKnockoutPredictionDTO
} from "../services/prediction/predictionMapper.ts";
import { saveIndividualGroupTopThreePredictionSchema } from "../lib/validations/individualPrediction.ts";

describe("individual predictions", () => {
  it("deve validar top 3 distintos", () => {
    const result = saveIndividualGroupTopThreePredictionSchema.safeParse({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_2",
      thirdPlaceTeamId: "team_3"
    });

    expect(result.success).toBe(true);
  });

  it("deve rejeitar top 3 duplicado", () => {
    const result = saveIndividualGroupTopThreePredictionSchema.safeParse({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_1",
      thirdPlaceTeamId: "team_3"
    });

    expect(result.success).toBe(false);
  });

  it("deve calcular automaticamente o quarto colocado", () => {
    expect(
      deriveFourthPlaceTeamId(["team_1", "team_2", "team_3", "team_4"], [
        "team_1",
        "team_3",
        "team_2"
      ])
    ).toBe("team_4");
  });

  it("deve rejeitar grupo com quantidade inválida de seleções", () => {
    expect(() =>
      deriveFourthPlaceTeamId(["team_1", "team_2", "team_3"], [
        "team_1",
        "team_2",
        "team_3"
      ])
    ).toThrow(AppError);
  });

  it("deve rejeitar ids duplicados", () => {
    expect(() => assertDistinctTeamIds(["team_1", "team_1"])).toThrow(AppError);
  });

  it("deve serializar previsão de grupo", () => {
    const now = new Date("2026-01-01T00:00:00.000Z");

    expect(
      toIndividualGroupPredictionDTO({
        id: "prediction_1",
        userId: "user_1",
        group: "A",
        firstPlaceTeamId: "team_1",
        secondPlaceTeamId: "team_2",
        thirdPlaceTeamId: "team_3",
        fourthPlaceTeamId: "team_4",
        lockedAt: null,
        submittedAt: now,
        createdAt: now,
        updatedAt: now
      })
    ).toMatchObject({
      id: "prediction_1",
      submittedAt: "2026-01-01T00:00:00.000Z"
    });
  });

  it("deve serializar previsão de mata-mata", () => {
    const now = new Date("2026-01-01T00:00:00.000Z");

    expect(
      toIndividualKnockoutPredictionDTO({
        id: "prediction_2",
        userId: "user_1",
        bracketSlotId: "slot_1",
        winnerTeamId: "team_1",
        lockedAt: null,
        submittedAt: now,
        createdAt: now,
        updatedAt: now
      })
    ).toMatchObject({
      id: "prediction_2",
      winnerTeamId: "team_1"
    });
  });
});
EOF

echo "==> Bloco 8 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add individual predictions\""
echo "  git push"
