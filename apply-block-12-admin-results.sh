#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 12 — painel admin de resultados reais e gatilhos de ranking..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/admin
mkdir -p actions
mkdir -p components/admin
mkdir -p app/admin/resultados
mkdir -p docs
mkdir -p tests

cat > services/admin/resultPayloadUtils.ts <<'EOF'
import { REAL_RESULT_TYPE } from "../../lib/contracts/enums.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import {
  groupStandingResultPayloadSchema,
  knockoutMatchResultPayloadSchema
} from "../scoring/resultPayloads.ts";

export function parseJsonPayload(rawPayload: string): unknown {
  try {
    return JSON.parse(rawPayload);
  } catch {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Payload precisa ser um JSON válido.",
      statusCode: 422
    });
  }
}

export function validateRealResultPayload(type: string, payload: unknown): unknown {
  if (type === REAL_RESULT_TYPE.GROUP_STANDING) {
    const parsedPayload = groupStandingResultPayloadSchema.safeParse(payload);

    if (!parsedPayload.success) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message:
          "Payload de classificação de grupo inválido. Esperado: { \"orderedTeamIds\": [\"id1\", \"id2\", \"id3\", \"id4\"] }.",
        statusCode: 422,
        details: parsedPayload.error.flatten().fieldErrors
      });
    }

    return parsedPayload.data;
  }

  if (type === REAL_RESULT_TYPE.KNOCKOUT_MATCH) {
    const parsedPayload = knockoutMatchResultPayloadSchema.safeParse(payload);

    if (!parsedPayload.success) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message:
          "Payload de mata-mata inválido. Esperado: { \"winnerTeamId\": \"id\" }.",
        statusCode: 422,
        details: parsedPayload.error.flatten().fieldErrors
      });
    }

    return parsedPayload.data;
  }

  if (payload === null || typeof payload !== "object") {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Payload de resultado precisa ser um objeto JSON.",
      statusCode: 422
    });
  }

  return payload;
}

export function buildGroupStandingResultKey(group: string): string {
  return `group_standing:${group}`;
}

export function buildKnockoutMatchResultKey(bracketSlotId: string): string {
  return `knockout_match:${bracketSlotId}`;
}
EOF

cat > services/admin/resultMapper.ts <<'EOF'
import type { RealTournamentResultDTO } from "../../lib/contracts/admin.ts";

export type RealTournamentResultRecord = {
  id: string;
  resultKey: string;
  type: RealTournamentResultDTO["type"];
  group: RealTournamentResultDTO["group"];
  knockoutPhase: RealTournamentResultDTO["knockoutPhase"];
  officialMatchId: string | null;
  bracketSlotId: string | null;
  payload: unknown;
  sourceDocumentRef: string | null;
  officialDataStatus: RealTournamentResultDTO["officialDataStatus"];
  officialDataVersionId: string | null;
};

export function toRealTournamentResultDTO(
  result: RealTournamentResultRecord
): RealTournamentResultDTO {
  return {
    id: result.id,
    resultKey: result.resultKey,
    type: result.type,
    group: result.group,
    knockoutPhase: result.knockoutPhase,
    officialMatchId: result.officialMatchId,
    bracketSlotId: result.bracketSlotId,
    payload: result.payload,
    sourceDocumentRef: result.sourceDocumentRef,
    officialDataStatus: result.officialDataStatus,
    officialDataVersionId: result.officialDataVersionId
  };
}
EOF

cat > services/admin/resultAdminService.ts <<'EOF'
import { prisma } from "../../lib/db/prisma.ts";
import {
  OFFICIAL_DATA_STATUS,
  REAL_RESULT_TYPE
} from "../../lib/contracts/enums.ts";
import type { RealTournamentResultDTO } from "../../lib/contracts/admin.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import {
  buildGroupStandingResultKey,
  buildKnockoutMatchResultKey,
  validateRealResultPayload
} from "./resultPayloadUtils.ts";
import { toRealTournamentResultDTO } from "./resultMapper.ts";

export type UpsertRealResultServiceInput = {
  resultKey?: string;
  type: keyof typeof REAL_RESULT_TYPE;
  group?: string;
  knockoutPhase?: string;
  officialMatchId?: string;
  bracketSlotId?: string;
  payload: unknown;
  sourceDocumentRef?: string;
  officialDataVersionId?: string;
};

function resolveResultKey(input: UpsertRealResultServiceInput): string {
  if (input.resultKey?.trim()) {
    return input.resultKey.trim();
  }

  if (input.type === REAL_RESULT_TYPE.GROUP_STANDING && input.group) {
    return buildGroupStandingResultKey(input.group);
  }

  if (input.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && input.bracketSlotId) {
    return buildKnockoutMatchResultKey(input.bracketSlotId);
  }

  throw new AppError({
    code: "VALIDATION_ERROR",
    message: "resultKey é obrigatório quando não puder ser derivado do tipo de resultado.",
    statusCode: 422
  });
}

function assertResultContextIsValid(input: UpsertRealResultServiceInput): void {
  if (input.type === REAL_RESULT_TYPE.GROUP_STANDING && !input.group) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Resultado de classificação de grupo exige grupo.",
      statusCode: 422
    });
  }

  if (input.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && !input.bracketSlotId) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Resultado de mata-mata exige bracketSlotId.",
      statusCode: 422
    });
  }
}

export async function listRealTournamentResults(): Promise<RealTournamentResultDTO[]> {
  const results = await prisma.realTournamentResult.findMany({
    orderBy: [
      {
        type: "asc"
      },
      {
        resultKey: "asc"
      }
    ]
  });

  return results.map(toRealTournamentResultDTO);
}

export async function upsertRealTournamentResult(
  input: UpsertRealResultServiceInput
): Promise<RealTournamentResultDTO> {
  assertResultContextIsValid(input);

  const resultKey = resolveResultKey(input);
  const validatedPayload = validateRealResultPayload(input.type, input.payload);

  const result = await prisma.realTournamentResult.upsert({
    where: {
      resultKey
    },
    update: {
      type: input.type,
      group: input.group ?? null,
      knockoutPhase: input.knockoutPhase ?? null,
      officialMatchId: input.officialMatchId ?? null,
      bracketSlotId: input.bracketSlotId ?? null,
      payload: validatedPayload,
      sourceDocumentRef: input.sourceDocumentRef?.trim() || null,
      officialDataStatus: OFFICIAL_DATA_STATUS.OFFICIAL,
      officialDataVersionId: input.officialDataVersionId ?? null
    },
    create: {
      resultKey,
      type: input.type,
      group: input.group ?? null,
      knockoutPhase: input.knockoutPhase ?? null,
      officialMatchId: input.officialMatchId ?? null,
      bracketSlotId: input.bracketSlotId ?? null,
      payload: validatedPayload,
      sourceDocumentRef: input.sourceDocumentRef?.trim() || null,
      officialDataStatus: OFFICIAL_DATA_STATUS.OFFICIAL,
      officialDataVersionId: input.officialDataVersionId ?? null
    }
  });

  return toRealTournamentResultDTO(result);
}
EOF

cat > services/admin/index.ts <<'EOF'
export * from "./resultPayloadUtils.ts";
export * from "./resultMapper.ts";
export * from "./resultAdminService.ts";
EOF

cat > lib/validations/adminResults.ts <<'EOF'
import { z } from "zod";
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  REAL_RESULT_TYPE_VALUES
} from "../contracts/enums.ts";

export const adminRealResultFormSchema = z.object({
  resultKey: z.string().trim().max(160).optional(),
  type: z.enum(REAL_RESULT_TYPE_VALUES),
  group: z.enum(GROUP_LETTER_VALUES).optional(),
  knockoutPhase: z.enum(KNOCKOUT_PHASE_VALUES).optional(),
  officialMatchId: z.string().trim().optional(),
  bracketSlotId: z.string().trim().optional(),
  sourceDocumentRef: z.string().trim().max(1000).optional(),
  officialDataVersionId: z.string().trim().optional(),
  payloadJson: z.string().trim().min(2, "Payload JSON é obrigatório.")
});

export type AdminRealResultFormInput = z.infer<typeof adminRealResultFormSchema>;
EOF

cat > actions/adminResults.ts <<'EOF'
"use server";

import { randomUUID } from "node:crypto";
import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { RANKING_TYPE } from "../lib/contracts/enums.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import {
  error as actionError,
  success,
  validationError
} from "../lib/errors/actionResponses.ts";
import { requireAdminGlobalUser } from "../lib/auth/currentUser";
import { adminRealResultFormSchema } from "../lib/validations/adminResults.ts";
import { parseJsonPayload } from "../services/admin/resultPayloadUtils.ts";
import { upsertRealTournamentResult } from "../services/admin/resultAdminService.ts";
import { recalculateRanking } from "../services/ranking/rankingService.ts";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  return Object.fromEntries(
    Object.entries(Object.fromEntries(formData.entries())).filter(([, value]) => value !== "")
  );
}

export async function upsertRealTournamentResultAction(
  formData: FormData
): Promise<ActionResult<{ resultId: string }>> {
  await requireAdminGlobalUser();

  const parsedInput = adminRealResultFormSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Resultado real inválido.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const payload = parseJsonPayload(parsedInput.data.payloadJson);

    const result = await upsertRealTournamentResult({
      resultKey: parsedInput.data.resultKey,
      type: parsedInput.data.type,
      group: parsedInput.data.group,
      knockoutPhase: parsedInput.data.knockoutPhase,
      officialMatchId: parsedInput.data.officialMatchId,
      bracketSlotId: parsedInput.data.bracketSlotId,
      sourceDocumentRef: parsedInput.data.sourceDocumentRef,
      officialDataVersionId: parsedInput.data.officialDataVersionId,
      payload
    });

    revalidatePath(APP_ROUTES.ADMIN_RESULTS);
    revalidatePath(APP_ROUTES.RANKING_INDIVIDUAL);
    revalidatePath(APP_ROUTES.RANKING_TEAMS);

    return success({
      resultId: result.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function recalculateAllRankingsAction(): Promise<
  ActionResult<{ individualSnapshotId: string; teamSnapshotId: string }>
> {
  const admin = await requireAdminGlobalUser();

  try {
    const [individualSnapshot, teamSnapshot] = await Promise.all([
      recalculateRanking({
        type: RANKING_TYPE.INDIVIDUAL,
        requestedByUserId: admin.id,
        idempotencyKey: `admin-results:${RANKING_TYPE.INDIVIDUAL}:${randomUUID()}`
      }),
      recalculateRanking({
        type: RANKING_TYPE.TEAM,
        requestedByUserId: admin.id,
        idempotencyKey: `admin-results:${RANKING_TYPE.TEAM}:${randomUUID()}`
      })
    ]);

    revalidatePath(APP_ROUTES.RANKING_INDIVIDUAL);
    revalidatePath(APP_ROUTES.RANKING_TEAMS);
    revalidatePath(APP_ROUTES.ADMIN_RESULTS);

    return success({
      individualSnapshotId: individualSnapshot.id,
      teamSnapshotId: teamSnapshot.id
    });
  } catch (error) {
    return actionError(error);
  }
}
EOF

cat > components/admin/AdminResultForm.tsx <<'EOF'
import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  REAL_RESULT_TYPE_VALUES
} from "../../lib/contracts/enums.ts";
import { upsertRealTournamentResultAction } from "../../actions/adminResults.ts";

export function AdminResultForm() {
  return (
    <form
      action={upsertRealTournamentResultAction}
      className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
    >
      <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
        Novo resultado
      </p>

      <h2 className="mt-2 text-xl font-bold">Cadastrar ou atualizar resultado real</h2>

      <div className="mt-5 grid gap-4 md:grid-cols-2">
        <label className="block">
          <span className="text-sm font-medium">Tipo</span>
          <select
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="type"
            required
          >
            {REAL_RESULT_TYPE_VALUES.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-medium">Result key opcional</span>
          <input
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="resultKey"
            placeholder="group_standing:A"
          />
        </label>

        <label className="block">
          <span className="text-sm font-medium">Grupo</span>
          <select className="mt-1 w-full rounded-xl border border-app-border px-3 py-2" name="group">
            <option value="">Não se aplica</option>
            {GROUP_LETTER_VALUES.map((group) => (
              <option key={group} value={group}>
                {group}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-medium">Fase mata-mata</span>
          <select
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="knockoutPhase"
          >
            <option value="">Não se aplica</option>
            {KNOCKOUT_PHASE_VALUES.map((phase) => (
              <option key={phase} value={phase}>
                {phase}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-medium">Official match ID</span>
          <input className="mt-1 w-full rounded-xl border border-app-border px-3 py-2" name="officialMatchId" />
        </label>

        <label className="block">
          <span className="text-sm font-medium">Bracket slot ID</span>
          <input className="mt-1 w-full rounded-xl border border-app-border px-3 py-2" name="bracketSlotId" />
        </label>

        <label className="block md:col-span-2">
          <span className="text-sm font-medium">Fonte/documento oficial</span>
          <input
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="sourceDocumentRef"
            placeholder="FWC26_regulations_EN.pdf / Article / Annexe"
          />
        </label>

        <label className="block md:col-span-2">
          <span className="text-sm font-medium">Payload JSON</span>
          <textarea
            className="mt-1 min-h-40 w-full rounded-xl border border-app-border px-3 py-2 font-mono text-sm"
            name="payloadJson"
            required
            defaultValue={'{\n  "orderedTeamIds": ["team_1", "team_2", "team_3", "team_4"]\n}'}
          />
        </label>
      </div>

      <button
        className="mt-5 w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white"
        type="submit"
      >
        Salvar resultado real
      </button>
    </form>
  );
}
EOF

cat > components/admin/AdminResultsTable.tsx <<'EOF'
import type { RealTournamentResultDTO } from "../../lib/contracts/admin.ts";

type AdminResultsTableProps = {
  results: RealTournamentResultDTO[];
};

export function AdminResultsTable({ results }: AdminResultsTableProps) {
  if (results.length === 0) {
    return (
      <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
        Nenhum resultado real cadastrado ainda.
      </div>
    );
  }

  return (
    <section className="overflow-hidden rounded-app border border-app-border bg-app-surface shadow-app">
      <div className="border-b border-app-border p-4">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Resultados reais
        </p>
        <h2 className="mt-1 text-lg font-bold">{results.length} registro(s)</h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[760px] text-left text-sm">
          <thead className="bg-app-bg text-xs uppercase tracking-wide text-app-muted">
            <tr>
              <th className="px-4 py-3">Chave</th>
              <th className="px-4 py-3">Tipo</th>
              <th className="px-4 py-3">Grupo</th>
              <th className="px-4 py-3">Slot</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Payload</th>
            </tr>
          </thead>
          <tbody>
            {results.map((result) => (
              <tr className="border-t border-app-border align-top" key={result.id}>
                <td className="px-4 py-3 font-medium">{result.resultKey}</td>
                <td className="px-4 py-3">{result.type}</td>
                <td className="px-4 py-3">{result.group ?? "-"}</td>
                <td className="px-4 py-3">{result.bracketSlotId ?? "-"}</td>
                <td className="px-4 py-3">{result.officialDataStatus}</td>
                <td className="max-w-xs px-4 py-3">
                  <pre className="overflow-x-auto rounded-lg bg-app-bg p-2 text-xs">
                    {JSON.stringify(result.payload, null, 2)}
                  </pre>
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

cat > app/admin/resultados/page.tsx <<'EOF'
import { recalculateAllRankingsAction } from "../../../actions/adminResults.ts";
import { AdminResultForm } from "../../../components/admin/AdminResultForm.tsx";
import { AdminResultsTable } from "../../../components/admin/AdminResultsTable.tsx";
import { requireAdminGlobalUser } from "../../../lib/auth/currentUser";
import { listRealTournamentResults } from "../../../services/admin/resultAdminService.ts";

export default async function AdminResultsPage() {
  await requireAdminGlobalUser();
  const results = await listRealTournamentResults();

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Admin
          </p>

          <h1 className="mt-3 text-2xl font-bold">Resultados reais da Copa</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Cadastre resultados oficiais para alimentar pontuação e rankings. Use somente
            dados confirmados por documento oficial ou resultado real validado.
          </p>

          <form action={recalculateAllRankingsAction} className="mt-5">
            <button
              className="rounded-xl border border-app-border px-4 py-2 font-semibold"
              type="submit"
            >
              Recalcular rankings
            </button>
          </form>
        </div>

        <AdminResultForm />

        <AdminResultsTable results={results} />
      </section>
    </main>
  );
}
EOF

cat > docs/admin-results.md <<'EOF'
# Bloco 12 — Painel administrativo de resultados reais

## Objetivo

Permitir que administradores globais cadastrem resultados reais da Copa para alimentar pontuação e rankings.

## Tipos de payload suportados

### Classificação de grupo

```json
{
  "orderedTeamIds": ["team_1", "team_2", "team_3", "team_4"]
}
```

### Resultado de mata-mata

```json
{
  "winnerTeamId": "team_1"
}
```

## Segurança

- A página exige `ADMIN_GLOBAL`.
- A Server Action chama `requireAdminGlobalUser`.
- O payload é validado no backend.
- Resultados são salvos como `OFFICIAL`.
- O recálculo de ranking usa jobs idempotentes.

## Observação

Esse painel não substitui importador oficial de dados FIFA. Ele é a camada administrativa operacional para resultados reais.
EOF

cat > tests/admin-results.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { REAL_RESULT_TYPE } from "../lib/contracts/enums.ts";
import { AppError } from "../lib/errors/AppError.ts";
import {
  buildGroupStandingResultKey,
  buildKnockoutMatchResultKey,
  parseJsonPayload,
  validateRealResultPayload
} from "../services/admin/resultPayloadUtils.ts";
import { toRealTournamentResultDTO } from "../services/admin/resultMapper.ts";

describe("admin results", () => {
  it("deve parsear JSON válido", () => {
    expect(parseJsonPayload('{ "winnerTeamId": "team_1" }')).toEqual({
      winnerTeamId: "team_1"
    });
  });

  it("deve rejeitar JSON inválido", () => {
    expect(() => parseJsonPayload("{")).toThrow(AppError);
  });

  it("deve validar payload de classificação de grupo", () => {
    expect(
      validateRealResultPayload(REAL_RESULT_TYPE.GROUP_STANDING, {
        orderedTeamIds: ["team_1", "team_2", "team_3", "team_4"]
      })
    ).toEqual({
      orderedTeamIds: ["team_1", "team_2", "team_3", "team_4"]
    });
  });

  it("deve validar payload de mata-mata", () => {
    expect(
      validateRealResultPayload(REAL_RESULT_TYPE.KNOCKOUT_MATCH, {
        winnerTeamId: "team_1"
      })
    ).toEqual({
      winnerTeamId: "team_1"
    });
  });

  it("deve gerar chaves canônicas de resultados", () => {
    expect(buildGroupStandingResultKey("A")).toBe("group_standing:A");
    expect(buildKnockoutMatchResultKey("slot_1")).toBe("knockout_match:slot_1");
  });

  it("deve mapear resultado real para DTO", () => {
    expect(
      toRealTournamentResultDTO({
        id: "result_1",
        resultKey: "group_standing:A",
        type: "GROUP_STANDING",
        group: "A",
        knockoutPhase: null,
        officialMatchId: null,
        bracketSlotId: null,
        payload: {
          orderedTeamIds: ["team_1", "team_2", "team_3", "team_4"]
        },
        sourceDocumentRef: "manual",
        officialDataStatus: "OFFICIAL",
        officialDataVersionId: null
      })
    ).toMatchObject({
      id: "result_1",
      resultKey: "group_standing:A",
      officialDataStatus: "OFFICIAL"
    });
  });
});
EOF

echo "==> Bloco 12 aplicado."
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
echo "  git commit -m \"feat: add admin real results panel\""
echo "  git push"
