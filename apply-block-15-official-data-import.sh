#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 15 — importador oficial FIFA, versionamento e readiness de dados..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p lib/fifa/official-import
mkdir -p services/officialData
mkdir -p actions
mkdir -p components/admin
mkdir -p app/admin/dados-oficiais
mkdir -p docs
mkdir -p scripts
mkdir -p tests

cat > lib/fifa/official-import/officialDataImportTypes.ts <<'EOF'
import type {
  GroupLetter,
  KnockoutPhase,
  OfficialDataStatus
} from "../../contracts/enums.ts";

export type OfficialDataImportSource = {
  code: string;
  description: string;
  sourceDocumentRef: string;
  status: OfficialDataStatus;
};

export type OfficialTeamImportItem = {
  fifaCode: string;
  name: string;
  shortName: string;
  flagUrl?: string | null;
  group: GroupLetter;
  groupPosition: number;
};

export type OfficialGroupImportItem = {
  letter: GroupLetter;
  name: string;
};

export type OfficialMatchImportItem = {
  matchCode: string;
  matchNumber?: number | null;
  group?: GroupLetter | null;
  knockoutPhase?: KnockoutPhase | null;
  bracketSlotCode?: string | null;
  homeTeamFifaCode?: string | null;
  awayTeamFifaCode?: string | null;
  homeSlotCode?: string | null;
  awaySlotCode?: string | null;
  startsAt?: string | null;
  stadium?: string | null;
  city?: string | null;
};

export type OfficialBracketSlotImportItem = {
  slotCode: string;
  phase: KnockoutPhase;
  sortOrder: number;
  sourceSlotCodeA?: string | null;
  sourceSlotCodeB?: string | null;
  winnerGoesToSlotCode?: string | null;
};

export type OfficialThirdPlaceMatrixImportItem = {
  combinationKey: string;
  qualifiedThirdGroups: GroupLetter[];
  slotAssignments: Record<string, GroupLetter>;
};

export type OfficialDataImportManifest = {
  source: OfficialDataImportSource;
  groups: OfficialGroupImportItem[];
  teams: OfficialTeamImportItem[];
  matches: OfficialMatchImportItem[];
  bracketSlots: OfficialBracketSlotImportItem[];
  thirdPlaceMatrix: OfficialThirdPlaceMatrixImportItem[];
};
EOF

cat > lib/fifa/official-import/officialDataManifestSchema.ts <<'EOF'
import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  OFFICIAL_DATA_STATUS_VALUES
} from "../../contracts/enums.ts";

export const officialDataImportSourceSchema = z.object({
  code: z.string().trim().min(3).max(120),
  description: z.string().trim().min(3).max(500),
  sourceDocumentRef: z.string().trim().min(3).max(1000),
  status: z.enum(OFFICIAL_DATA_STATUS_VALUES)
});

export const officialGroupImportItemSchema = z.object({
  letter: z.enum(GROUP_LETTER_VALUES),
  name: z.string().trim().min(1).max(80)
});

export const officialTeamImportItemSchema = z.object({
  fifaCode: z.string().trim().min(2).max(6),
  name: z.string().trim().min(2).max(120),
  shortName: z.string().trim().min(2).max(80),
  flagUrl: z.string().url().nullable().optional(),
  group: z.enum(GROUP_LETTER_VALUES),
  groupPosition: z.number().int().min(1).max(4)
});

export const officialMatchImportItemSchema = z.object({
  matchCode: z.string().trim().min(2).max(40),
  matchNumber: z.number().int().positive().nullable().optional(),
  group: z.enum(GROUP_LETTER_VALUES).nullable().optional(),
  knockoutPhase: z.enum(KNOCKOUT_PHASE_VALUES).nullable().optional(),
  bracketSlotCode: z.string().trim().nullable().optional(),
  homeTeamFifaCode: z.string().trim().nullable().optional(),
  awayTeamFifaCode: z.string().trim().nullable().optional(),
  homeSlotCode: z.string().trim().nullable().optional(),
  awaySlotCode: z.string().trim().nullable().optional(),
  startsAt: z.string().datetime().nullable().optional(),
  stadium: z.string().trim().nullable().optional(),
  city: z.string().trim().nullable().optional()
});

export const officialBracketSlotImportItemSchema = z.object({
  slotCode: z.string().trim().min(2).max(80),
  phase: z.enum(KNOCKOUT_PHASE_VALUES),
  sortOrder: z.number().int().positive(),
  sourceSlotCodeA: z.string().trim().nullable().optional(),
  sourceSlotCodeB: z.string().trim().nullable().optional(),
  winnerGoesToSlotCode: z.string().trim().nullable().optional()
});

export const officialThirdPlaceMatrixImportItemSchema = z.object({
  combinationKey: z.string().trim().regex(/^[A-L]{8}$/),
  qualifiedThirdGroups: z.array(z.enum(GROUP_LETTER_VALUES)).length(8),
  slotAssignments: z.record(z.string(), z.enum(GROUP_LETTER_VALUES))
});

export const officialDataImportManifestSchema = z.object({
  source: officialDataImportSourceSchema,
  groups: z.array(officialGroupImportItemSchema).length(12),
  teams: z.array(officialTeamImportItemSchema),
  matches: z.array(officialMatchImportItemSchema),
  bracketSlots: z.array(officialBracketSlotImportItemSchema),
  thirdPlaceMatrix: z.array(officialThirdPlaceMatrixImportItemSchema)
});
EOF

cat > lib/fifa/official-import/officialDataImportGuards.ts <<'EOF'
import { AppError } from "../../errors/AppError.ts";
import { buildThirdPlaceCombinationKey } from "../roundOf32.ts";
import type { OfficialDataImportManifest } from "./officialDataImportTypes.ts";

export function assertOfficialImportManifestConsistency(
  manifest: OfficialDataImportManifest
): void {
  const groupLetters = new Set(manifest.groups.map((group) => group.letter));

  if (groupLetters.size !== 12) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Manifesto oficial precisa conter exatamente 12 grupos distintos.",
      statusCode: 422
    });
  }

  for (const group of manifest.groups) {
    const teamsInGroup = manifest.teams.filter((team) => team.group === group.letter);
    const groupPositions = new Set(teamsInGroup.map((team) => team.groupPosition));

    if (teamsInGroup.length !== 4 || groupPositions.size !== 4) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: `Grupo ${group.letter} precisa conter exatamente quatro seleções nas posições 1 a 4.`,
        statusCode: 422
      });
    }
  }

  const fifaCodes = manifest.teams.map((team) => team.fifaCode);
  const duplicatedFifaCodes = fifaCodes.filter(
    (fifaCode, index) => fifaCodes.indexOf(fifaCode) !== index
  );

  if (duplicatedFifaCodes.length > 0) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Manifesto possui códigos FIFA duplicados.",
      statusCode: 422,
      details: {
        duplicatedFifaCodes
      }
    });
  }

  const bracketSlotCodes = new Set(manifest.bracketSlots.map((slot) => slot.slotCode));

  for (const match of manifest.matches) {
    if (match.bracketSlotCode && !bracketSlotCodes.has(match.bracketSlotCode)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Partida aponta para slot de mata-mata inexistente.",
        statusCode: 422,
        details: {
          matchCode: match.matchCode,
          bracketSlotCode: match.bracketSlotCode
        }
      });
    }
  }

  for (const matrixRule of manifest.thirdPlaceMatrix) {
    const combinationKey = buildThirdPlaceCombinationKey(matrixRule.qualifiedThirdGroups);

    if (combinationKey !== matrixRule.combinationKey) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Chave de combinação da matriz de terceiros não corresponde aos grupos informados.",
        statusCode: 422,
        details: {
          expected: combinationKey,
          received: matrixRule.combinationKey
        }
      });
    }
  }
}

export function assertOfficialManifestIsProductionSafe(
  manifest: OfficialDataImportManifest
): void {
  if (process.env.NODE_ENV !== "production") {
    return;
  }

  if (manifest.source.status !== "OFFICIAL") {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Em produção, somente manifesto com status OFFICIAL pode ser importado.",
      statusCode: 500
    });
  }

  if (manifest.teams.length !== 48) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Em produção, o manifesto oficial precisa conter as 48 seleções.",
      statusCode: 500
    });
  }

  if (manifest.thirdPlaceMatrix.length !== 495) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Em produção, a matriz oficial dos terceiros precisa conter as 495 combinações do Annexe C.",
      statusCode: 500
    });
  }
}
EOF

cat > lib/fifa/official-import/index.ts <<'EOF'
export * from "./officialDataImportTypes.ts";
export * from "./officialDataManifestSchema.ts";
export * from "./officialDataImportGuards.ts";
EOF

cat > services/officialData/officialDataImportService.ts <<'EOF'
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
EOF

cat > actions/officialData.ts <<'EOF'
"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import {
  error as actionError,
  success,
  validationError
} from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { importOfficialDataManifest } from "../services/officialData/officialDataImportService.ts";

export async function importOfficialDataManifestAction(
  formData: FormData
): Promise<ActionResult<{ versionId: string }>> {
  await requireAdminGlobalUser();

  const rawJson = String(formData.get("manifestJson") ?? "").trim();

  if (!rawJson) {
    return validationError("Manifesto JSON é obrigatório.");
  }

  try {
    const manifest = JSON.parse(rawJson);
    const result = await importOfficialDataManifest(manifest);

    revalidatePath(APP_ROUTES.ADMIN);
    revalidatePath(APP_ROUTES.ADMIN_OFFICIAL_DATA);

    return success({
      versionId: result.versionId
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

if (!source.includes('ADMIN_OFFICIAL_DATA: "/admin/dados-oficiais"')) {
  source = source.replace(
    'ADMIN_RESULTS: "/admin/resultados"',
    'ADMIN_RESULTS: "/admin/resultados",\n  ADMIN_OFFICIAL_DATA: "/admin/dados-oficiais"'
  );
}

fs.writeFileSync(routesPath, source);
NODE

cat > components/admin/OfficialDataImportForm.tsx <<'EOF'
import { importOfficialDataManifestAction } from "../../actions/officialData.ts";

const exampleManifest = {
  source: {
    code: "FWC26_OFFICIAL_TODO",
    description: "TODO: substituir por manifesto oficial completo extraído dos documentos FIFA.",
    sourceDocumentRef: "FWC26_regulations_EN.pdf",
    status: "PARTIAL"
  },
  groups: Array.from({ length: 12 }, (_, index) => {
    const letter = String.fromCharCode(65 + index);

    return {
      letter,
      name: `Grupo ${letter}`
    };
  }),
  teams: [],
  matches: [],
  bracketSlots: [],
  thirdPlaceMatrix: []
};

export function OfficialDataImportForm() {
  return (
    <form
      action={importOfficialDataManifestAction}
      className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
    >
      <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
        Importação oficial
      </p>

      <h2 className="mt-2 text-xl font-bold">Importar manifesto JSON</h2>

      <p className="mt-3 text-sm leading-6 text-app-muted">
        Use somente dados oficiais versionados. Em produção, manifestos parciais ou sem
        as 495 combinações do Annexe C serão bloqueados.
      </p>

      <label className="mt-5 block">
        <span className="text-sm font-medium">Manifesto JSON</span>
        <textarea
          className="mt-1 min-h-96 w-full rounded-xl border border-app-border px-3 py-2 font-mono text-xs"
          name="manifestJson"
          required
          defaultValue={JSON.stringify(exampleManifest, null, 2)}
        />
      </label>

      <button
        className="mt-5 w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white"
        type="submit"
      >
        Importar dados oficiais
      </button>
    </form>
  );
}
EOF

cat > components/admin/OfficialDataVersionsTable.tsx <<'EOF'
type OfficialDataVersionRow = {
  id: string;
  code: string;
  description: string;
  status: string;
  sourceDocumentRef: string | null;
  importedAt: Date | null;
  isActive: boolean;
};

type OfficialDataVersionsTableProps = {
  versions: OfficialDataVersionRow[];
};

export function OfficialDataVersionsTable({ versions }: OfficialDataVersionsTableProps) {
  if (versions.length === 0) {
    return (
      <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
        Nenhuma versão oficial importada ainda.
      </div>
    );
  }

  return (
    <section className="overflow-hidden rounded-app border border-app-border bg-app-surface shadow-app">
      <div className="border-b border-app-border p-4">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Versões
        </p>
        <h2 className="mt-1 text-lg font-bold">Dados oficiais versionados</h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-left text-sm">
          <thead className="bg-app-bg text-xs uppercase tracking-wide text-app-muted">
            <tr>
              <th className="px-4 py-3">Código</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Ativa</th>
              <th className="px-4 py-3">Fonte</th>
              <th className="px-4 py-3">Importada em</th>
            </tr>
          </thead>
          <tbody>
            {versions.map((version) => (
              <tr className="border-t border-app-border" key={version.id}>
                <td className="px-4 py-3 font-medium">{version.code}</td>
                <td className="px-4 py-3">{version.status}</td>
                <td className="px-4 py-3">{version.isActive ? "Sim" : "Não"}</td>
                <td className="px-4 py-3">{version.sourceDocumentRef ?? "-"}</td>
                <td className="px-4 py-3">
                  {version.importedAt
                    ? new Intl.DateTimeFormat("pt-BR", {
                        dateStyle: "short",
                        timeStyle: "short"
                      }).format(version.importedAt)
                    : "-"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
EOF

cat > app/admin/dados-oficiais/page.tsx <<'EOF'
import { OfficialDataImportForm } from "../../../components/admin/OfficialDataImportForm.tsx";
import { OfficialDataVersionsTable } from "../../../components/admin/OfficialDataVersionsTable.tsx";
import { requireAdminGlobalUser } from "../../../lib/auth/currentUser";
import {
  getOfficialDataReadinessReport,
  getOfficialDataVersions
} from "../../../services/officialData/officialDataImportService.ts";

export default async function AdminOfficialDataPage() {
  await requireAdminGlobalUser();

  const [versions, readinessReport] = await Promise.all([
    getOfficialDataVersions(),
    getOfficialDataReadinessReport()
  ]);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Admin
          </p>

          <h1 className="mt-3 text-2xl font-bold">Dados oficiais FIFA</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Importe dados oficiais versionados para grupos, seleções, partidas, slots e
            matriz dos terceiros colocados.
          </p>

          <div className="mt-5 rounded-xl border border-app-border p-4">
            <p className="text-sm font-semibold">Readiness</p>
            <p className="mt-2 text-sm text-app-muted">
              Pode usar regras oficiais:{" "}
              <strong>{readinessReport.canUseOfficialRules ? "Sim" : "Não"}</strong>
            </p>

            {readinessReport.blockingReasons.length > 0 ? (
              <ul className="mt-3 list-disc space-y-1 pl-5 text-sm text-app-muted">
                {readinessReport.blockingReasons.map((reason) => (
                  <li key={reason}>{reason}</li>
                ))}
              </ul>
            ) : null}
          </div>
        </div>

        <OfficialDataImportForm />

        <OfficialDataVersionsTable versions={versions} />
      </section>
    </main>
  );
}
EOF

cat > scripts/official-data-template.ts <<'EOF'
import { writeFileSync } from "node:fs";
import { GROUP_LETTER_VALUES } from "../lib/contracts/enums.ts";

const manifest = {
  source: {
    code: "FWC26_OFFICIAL_TEMPLATE",
    description:
      "Template para importação de dados oficiais. Substitua por dados oficiais FIFA antes de produção.",
    sourceDocumentRef: "FWC26_regulations_EN.pdf",
    status: "PARTIAL"
  },
  groups: GROUP_LETTER_VALUES.map((letter) => ({
    letter,
    name: `Grupo ${letter}`
  })),
  teams: [],
  matches: [],
  bracketSlots: [],
  thirdPlaceMatrix: []
};

writeFileSync("docs/official-data-template.json", `${JSON.stringify(manifest, null, 2)}\n`);

console.log("Template criado em docs/official-data-template.json");
EOF

cat > docs/official-data-import.md <<'EOF'
# Bloco 15 — Importador oficial FIFA

## Objetivo

Criar uma esteira controlada para importar dados oficiais versionados.

## Manifesto

O manifesto contém:

- versão/fonte;
- grupos;
- seleções;
- partidas;
- slots oficiais;
- matriz dos terceiros colocados.

## Proteções

Em produção:

- `status` precisa ser `OFFICIAL`;
- precisa conter 48 seleções;
- a matriz dos terceiros colocados precisa conter as 495 combinações do Annexe C.

## Observação

Este bloco não extrai automaticamente dados do PDF. Ele define o formato seguro de entrada e impede que placeholders sejam usados como dados oficiais em produção.
EOF

cat > tests/official-data-import.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { AppError } from "../lib/errors/AppError.ts";
import { GROUP_LETTER_VALUES } from "../lib/contracts/enums.ts";
import {
  assertOfficialImportManifestConsistency,
  parseOfficialDataManifest
} from "../lib/fifa/official-import/index.ts";

const validPartialManifest = {
  source: {
    code: "FWC26_TEST_PARTIAL",
    description: "Manifesto parcial de teste.",
    sourceDocumentRef: "FWC26_regulations_EN.pdf",
    status: "PARTIAL"
  },
  groups: GROUP_LETTER_VALUES.map((letter) => ({
    letter,
    name: `Grupo ${letter}`
  })),
  teams: GROUP_LETTER_VALUES.flatMap((letter) =>
    [1, 2, 3, 4].map((position) => ({
      fifaCode: `${letter}${position}`,
      name: `Team ${letter}${position}`,
      shortName: `T${letter}${position}`,
      group: letter,
      groupPosition: position
    }))
  ),
  matches: [],
  bracketSlots: [],
  thirdPlaceMatrix: []
};

describe("official data import", () => {
  it("deve validar manifesto parcial consistente em desenvolvimento", () => {
    expect(() => parseOfficialDataManifest(validPartialManifest)).not.toThrow();
  });

  it("deve rejeitar grupos incompletos", () => {
    expect(() =>
      parseOfficialDataManifest({
        ...validPartialManifest,
        groups: validPartialManifest.groups.slice(0, 11)
      })
    ).toThrow();
  });

  it("deve rejeitar seleção duplicada por código FIFA", () => {
    expect(() =>
      assertOfficialImportManifestConsistency({
        ...validPartialManifest,
        teams: [
          ...validPartialManifest.teams,
          {
            fifaCode: "A1",
            name: "Duplicado",
            shortName: "Dup",
            group: "A",
            groupPosition: 1
          }
        ]
      })
    ).toThrow(AppError);
  });

  it("deve rejeitar regra de matriz com chave incoerente", () => {
    expect(() =>
      parseOfficialDataManifest({
        ...validPartialManifest,
        thirdPlaceMatrix: [
          {
            combinationKey: "ABCDEFGH",
            qualifiedThirdGroups: ["A", "B", "C", "D", "E", "F", "G", "I"],
            slotAssignments: {}
          }
        ]
      })
    ).toThrow(AppError);
  });
});
EOF

echo "==> Bloco 15 aplicado."
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
echo "  git commit -m \"feat: add official data import pipeline\""
echo "  git push"
