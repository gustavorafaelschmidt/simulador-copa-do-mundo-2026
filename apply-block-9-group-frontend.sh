#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 9 — frontend mobile first da fase de grupos..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p components/world-cup
mkdir -p components/forms
mkdir -p docs
mkdir -p tests

cat > components/world-cup/StatusPill.tsx <<'EOF'
type StatusPillProps = {
  label: string;
  tone?: "neutral" | "success" | "warning" | "danger";
};

const toneClasses = {
  neutral: "border-app-border bg-app-surface text-app-muted",
  success: "border-green-200 bg-green-100 text-green-800",
  warning: "border-yellow-200 bg-yellow-100 text-yellow-800",
  danger: "border-red-200 bg-red-100 text-red-800"
} as const;

export function StatusPill({ label, tone = "neutral" }: StatusPillProps) {
  return (
    <span
      className={`inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold ${toneClasses[tone]}`}
    >
      {label}
    </span>
  );
}
EOF

cat > components/world-cup/NationalTeamOptionLabel.tsx <<'EOF'
import type { NationalTeamDTO } from "../../lib/contracts/officialData.ts";

type NationalTeamOptionLabelProps = {
  team: NationalTeamDTO;
};

export function buildNationalTeamOptionLabel(team: NationalTeamDTO): string {
  const groupPrefix = team.groupLetter ? `Grupo ${team.groupLetter} · ` : "";
  const positionPrefix = team.groupPosition ? `${team.groupPosition}. ` : "";

  return `${groupPrefix}${positionPrefix}${team.shortName}`;
}

export function NationalTeamOptionLabel({ team }: NationalTeamOptionLabelProps) {
  return (
    <span>
      {team.groupPosition ? `${team.groupPosition}. ` : ""}
      {team.shortName}
    </span>
  );
}
EOF

cat > components/world-cup/PredictionProgress.tsx <<'EOF'
import { StatusPill } from "./StatusPill.tsx";

type PredictionProgressProps = {
  total: number;
  completed: number;
  label: string;
};

export function calculatePredictionProgressPercentage(total: number, completed: number): number {
  if (total <= 0) {
    return 0;
  }

  return Math.round((completed / total) * 100);
}

export function PredictionProgress({ total, completed, label }: PredictionProgressProps) {
  const percentage = calculatePredictionProgressPercentage(total, completed);

  return (
    <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Progresso
          </p>
          <h2 className="mt-2 text-xl font-bold">{label}</h2>
          <p className="mt-1 text-sm text-app-muted">
            {completed} de {total} previsões salvas.
          </p>
        </div>

        <StatusPill
          label={`${percentage}%`}
          tone={percentage === 100 ? "success" : percentage > 0 ? "warning" : "neutral"}
        />
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-app-border">
        <div
          aria-label={`${percentage}% concluído`}
          className="h-full rounded-full bg-app-primary"
          style={{ width: `${percentage}%` }}
        />
      </div>
    </section>
  );
}
EOF

cat > components/forms/SelectField.tsx <<'EOF'
import type { ReactNode } from "react";

type SelectFieldProps = {
  label: string;
  name: string;
  defaultValue?: string;
  required?: boolean;
  children: ReactNode;
};

export function SelectField({
  label,
  name,
  defaultValue = "",
  required = false,
  children
}: SelectFieldProps) {
  return (
    <label className="block">
      <span className="text-sm font-medium">{label}</span>
      <select
        className="mt-1 w-full rounded-xl border border-app-border bg-white px-3 py-2 text-sm outline-none transition focus:border-app-primary focus:ring-2 focus:ring-app-primary/20"
        defaultValue={defaultValue}
        name={name}
        required={required}
      >
        {children}
      </select>
    </label>
  );
}
EOF

cat > components/world-cup/GroupPredictionCard.tsx <<'EOF'
import { saveIndividualGroupPredictionAction } from "../../actions/prediction.ts";
import type { GroupPredictionBoardItem } from "../../services/prediction/predictionService.ts";
import { SelectField } from "../forms/SelectField.tsx";
import { StatusPill } from "./StatusPill.tsx";

type GroupPredictionCardProps = {
  group: GroupPredictionBoardItem;
};

function getDataStatusTone(status: string) {
  if (status === "OFFICIAL") {
    return "success" as const;
  }

  if (status === "PLACEHOLDER") {
    return "warning" as const;
  }

  if (status === "DEPRECATED") {
    return "danger" as const;
  }

  return "neutral" as const;
}

export function GroupPredictionCard({ group }: GroupPredictionCardProps) {
  return (
    <article className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Grupo {group.letter}
          </p>
          <h2 className="mt-2 text-xl font-bold">{group.name}</h2>
          <p className="mt-1 text-sm text-app-muted">
            Escolha os três primeiros. O 4º colocado será calculado automaticamente.
          </p>
        </div>

        <div className="flex shrink-0 flex-col items-end gap-2">
          <StatusPill
            label={group.officialDataStatus}
            tone={getDataStatusTone(group.officialDataStatus)}
          />
          {group.prediction ? <StatusPill label="Salvo" tone="success" /> : null}
        </div>
      </div>

      <div className="mt-5 rounded-xl border border-app-border p-3">
        <p className="text-xs font-semibold uppercase tracking-wide text-app-muted">
          Seleções do grupo
        </p>

        <ol className="mt-3 grid gap-2 text-sm">
          {group.teams.map((team) => (
            <li className="flex items-center justify-between gap-3" key={team.id}>
              <span>
                {team.groupPosition}. {team.shortName}
              </span>
              <span className="text-xs text-app-muted">{team.fifaCode}</span>
            </li>
          ))}
        </ol>
      </div>

      <form action={saveIndividualGroupPredictionAction} className="mt-5 space-y-4">
        <input name="group" type="hidden" value={group.letter} />

        <SelectField
          defaultValue={group.prediction?.firstPlaceTeamId ?? ""}
          label="1º colocado"
          name="firstPlaceTeamId"
          required
        >
          <option value="">Selecione</option>
          {group.teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupPosition}. {team.shortName}
            </option>
          ))}
        </SelectField>

        <SelectField
          defaultValue={group.prediction?.secondPlaceTeamId ?? ""}
          label="2º colocado"
          name="secondPlaceTeamId"
          required
        >
          <option value="">Selecione</option>
          {group.teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupPosition}. {team.shortName}
            </option>
          ))}
        </SelectField>

        <SelectField
          defaultValue={group.prediction?.thirdPlaceTeamId ?? ""}
          label="3º colocado"
          name="thirdPlaceTeamId"
          required
        >
          <option value="">Selecione</option>
          {group.teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupPosition}. {team.shortName}
            </option>
          ))}
        </SelectField>

        {group.prediction ? (
          <p className="rounded-xl bg-app-bg px-3 py-2 text-sm text-app-muted">
            4º calculado:{" "}
            <strong>
              {group.teams.find((team) => team.id === group.prediction?.fourthPlaceTeamId)
                ?.shortName ?? "não identificado"}
            </strong>
          </p>
        ) : null}

        <button
          className="w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white transition hover:opacity-90"
          type="submit"
        >
          Salvar previsão do grupo {group.letter}
        </button>
      </form>
    </article>
  );
}
EOF

cat > app/dashboard/previsoes/grupos/page.tsx <<'EOF'
import Link from "next/link";
import { GroupPredictionCard } from "../../../../components/world-cup/GroupPredictionCard.tsx";
import { PredictionProgress } from "../../../../components/world-cup/PredictionProgress.tsx";
import { APP_ROUTES } from "../../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../../lib/auth/currentUser";
import { listGroupPredictionBoard } from "../../../../services/prediction/predictionService.ts";

export default async function GroupPredictionsPage() {
  const user = await requireCurrentUser();
  const groups = await listGroupPredictionBoard(user.id);
  const completedGroups = groups.filter((group) => group.prediction).length;

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.PREDICTIONS}>
          ← Voltar para previsões
        </Link>

        <div className="mt-4 grid gap-4 lg:grid-cols-[1fr_360px]">
          <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
            <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
              Fase de grupos
            </p>

            <h1 className="mt-3 text-2xl font-bold">Previsões dos grupos</h1>

            <p className="mt-3 text-sm leading-6 text-app-muted">
              Selecione 1º, 2º e 3º colocados de cada grupo. O backend calcula e
              persiste automaticamente o 4º colocado para manter consistência.
            </p>
          </section>

          <PredictionProgress completed={completedGroups} label="Grupos previstos" total={groups.length} />
        </div>

        <div className="mt-6 grid gap-4 lg:grid-cols-2">
          {groups.map((group) => (
            <GroupPredictionCard group={group} key={group.id} />
          ))}
        </div>
      </section>
    </main>
  );
}
EOF

cat > docs/frontend-group-stage.md <<'EOF'
# Bloco 9 — Frontend da fase de grupos

## Objetivo

Melhorar a experiência mobile first para previsões individuais de fase de grupos.

## Componentes criados

- `StatusPill`
- `PredictionProgress`
- `SelectField`
- `GroupPredictionCard`
- `NationalTeamOptionLabel`

## Regras preservadas

- Usuário escolhe 1º, 2º e 3º.
- Backend calcula o 4º colocado.
- Dados oficiais ainda exibem status para evitar confusão entre placeholder e oficial.
- Nenhuma regra crítica é validada apenas no frontend.

## Decisão visual

A UI usa cards, bordas arredondadas, espaçamento amplo e hierarquia clara para mobile.
A experiência é inspirada em simuladores esportivos, mas sem copiar marca, assets ou código de terceiros.
EOF

cat > tests/frontend-group-stage.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { calculatePredictionProgressPercentage } from "../components/world-cup/PredictionProgress.tsx";
import { buildNationalTeamOptionLabel } from "../components/world-cup/NationalTeamOptionLabel.tsx";

describe("frontend group stage helpers", () => {
  it("deve calcular percentual de progresso", () => {
    expect(calculatePredictionProgressPercentage(12, 6)).toBe(50);
    expect(calculatePredictionProgressPercentage(12, 12)).toBe(100);
  });

  it("deve retornar zero quando total for inválido", () => {
    expect(calculatePredictionProgressPercentage(0, 4)).toBe(0);
  });

  it("deve montar label de seleção com grupo e posição", () => {
    expect(
      buildNationalTeamOptionLabel({
        id: "team_1",
        fifaCode: "BRA",
        name: "Brasil",
        shortName: "Brasil",
        flagUrl: null,
        groupId: "group_a",
        groupLetter: "A",
        groupPosition: 1,
        officialDataStatus: "PLACEHOLDER",
        officialDataVersionId: "version_1"
      })
    ).toBe("Grupo A · 1. Brasil");
  });
});
EOF

echo "==> Bloco 9 aplicado."
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
echo "  git commit -m \"feat: add group prediction frontend\""
echo "  git push"
