#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 10 — frontend mobile first do mata-mata..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p components/world-cup
mkdir -p docs
mkdir -p tests

cat > components/world-cup/KnockoutPhaseLabel.tsx <<'EOF'
import type { KnockoutPhase } from "../../lib/contracts/enums.ts";

const knockoutPhaseLabels: Record<KnockoutPhase, string> = {
  ROUND_OF_32: "16-avos de final",
  ROUND_OF_16: "Oitavas de final",
  QUARTER_FINAL: "Quartas de final",
  SEMI_FINAL: "Semifinais",
  THIRD_PLACE: "Disputa de 3º lugar",
  FINAL: "Final"
};

const knockoutPhaseOrder: Record<KnockoutPhase, number> = {
  ROUND_OF_32: 1,
  ROUND_OF_16: 2,
  QUARTER_FINAL: 3,
  SEMI_FINAL: 4,
  THIRD_PLACE: 5,
  FINAL: 6
};

export function getKnockoutPhaseLabel(phase: KnockoutPhase): string {
  return knockoutPhaseLabels[phase];
}

export function getKnockoutPhaseOrder(phase: KnockoutPhase): number {
  return knockoutPhaseOrder[phase];
}

export function KnockoutPhaseLabel({ phase }: { phase: KnockoutPhase }) {
  return <span>{getKnockoutPhaseLabel(phase)}</span>;
}
EOF

cat > components/world-cup/KnockoutSlotCard.tsx <<'EOF'
import { saveIndividualKnockoutPredictionAction } from "../../actions/prediction.ts";
import type { NationalTeamDTO } from "../../lib/contracts/officialData.ts";
import type { KnockoutPredictionBoardItem } from "../../services/prediction/predictionService.ts";
import { SelectField } from "../forms/SelectField.tsx";
import { getKnockoutPhaseLabel } from "./KnockoutPhaseLabel.tsx";
import { StatusPill } from "./StatusPill.tsx";

type KnockoutSlotCardProps = {
  slot: KnockoutPredictionBoardItem;
  teams: NationalTeamDTO[];
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

export function KnockoutSlotCard({ slot, teams }: KnockoutSlotCardProps) {
  const predictedWinner = teams.find((team) => team.id === slot.prediction?.winnerTeamId);

  return (
    <article className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            {getKnockoutPhaseLabel(slot.phase)}
          </p>

          <h3 className="mt-2 text-lg font-bold">{slot.slotCode}</h3>

          <p className="mt-1 text-sm text-app-muted">
            Ordem: {slot.sortOrder}
            {slot.sourceSlotCodeA || slot.sourceSlotCodeB
              ? ` · Origem: ${slot.sourceSlotCodeA ?? "TBD"} x ${
                  slot.sourceSlotCodeB ?? "TBD"
                }`
              : ""}
          </p>
        </div>

        <div className="flex shrink-0 flex-col items-end gap-2">
          <StatusPill label={slot.officialDataStatus} tone={getDataStatusTone(slot.officialDataStatus)} />
          {slot.prediction ? <StatusPill label="Salvo" tone="success" /> : null}
        </div>
      </div>

      {slot.winnerGoesToSlotCode ? (
        <p className="mt-4 rounded-xl bg-app-bg px-3 py-2 text-sm text-app-muted">
          Vencedor avança para: <strong>{slot.winnerGoesToSlotCode}</strong>
        </p>
      ) : null}

      {predictedWinner ? (
        <p className="mt-4 rounded-xl bg-green-50 px-3 py-2 text-sm text-green-800">
          Palpite atual: <strong>{predictedWinner.shortName}</strong>
        </p>
      ) : null}

      <form action={saveIndividualKnockoutPredictionAction} className="mt-5 space-y-4">
        <input name="bracketSlotId" type="hidden" value={slot.id} />

        <SelectField
          defaultValue={slot.prediction?.winnerTeamId ?? ""}
          label="Vencedor previsto"
          name="winnerTeamId"
          required
        >
          <option value="">Selecione</option>
          {teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupLetter ? `Grupo ${team.groupLetter} · ` : ""}
              {team.shortName}
            </option>
          ))}
        </SelectField>

        <button
          className="w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white transition hover:opacity-90"
          type="submit"
        >
          Salvar previsão
        </button>
      </form>
    </article>
  );
}
EOF

cat > components/world-cup/KnockoutPhaseSection.tsx <<'EOF'
import type { KnockoutPhase } from "../../lib/contracts/enums.ts";
import type { NationalTeamDTO } from "../../lib/contracts/officialData.ts";
import type { KnockoutPredictionBoardItem } from "../../services/prediction/predictionService.ts";
import { getKnockoutPhaseLabel } from "./KnockoutPhaseLabel.tsx";
import { KnockoutSlotCard } from "./KnockoutSlotCard.tsx";

type KnockoutPhaseSectionProps = {
  phase: KnockoutPhase;
  slots: KnockoutPredictionBoardItem[];
  teams: NationalTeamDTO[];
};

export function KnockoutPhaseSection({ phase, slots, teams }: KnockoutPhaseSectionProps) {
  if (slots.length === 0) {
    return null;
  }

  return (
    <section className="space-y-4">
      <div className="sticky top-0 z-10 rounded-xl border border-app-border bg-app-surface/95 p-4 shadow-sm backdrop-blur">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Mata-mata
        </p>
        <h2 className="mt-1 text-xl font-bold">{getKnockoutPhaseLabel(phase)}</h2>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {slots.map((slot) => (
          <KnockoutSlotCard key={slot.id} slot={slot} teams={teams} />
        ))}
      </div>
    </section>
  );
}
EOF

cat > components/world-cup/KnockoutLegend.tsx <<'EOF'
import { StatusPill } from "./StatusPill.tsx";

export function KnockoutLegend() {
  return (
    <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
        Importante
      </p>

      <h2 className="mt-2 text-lg font-bold">Dados oficiais e placeholders</h2>

      <p className="mt-3 text-sm leading-6 text-app-muted">
        Os slots de mata-mata podem estar como placeholders durante o desenvolvimento.
        Em produção, o backend bloqueia chaveamento não oficial ou incompleto.
      </p>

      <div className="mt-4 flex flex-wrap gap-2">
        <StatusPill label="OFFICIAL" tone="success" />
        <StatusPill label="PLACEHOLDER" tone="warning" />
        <StatusPill label="DEPRECATED" tone="danger" />
      </div>
    </section>
  );
}
EOF

cat > app/dashboard/previsoes/mata-mata/page.tsx <<'EOF'
import Link from "next/link";
import { KnockoutLegend } from "../../../../components/world-cup/KnockoutLegend.tsx";
import { getKnockoutPhaseOrder } from "../../../../components/world-cup/KnockoutPhaseLabel.tsx";
import { KnockoutPhaseSection } from "../../../../components/world-cup/KnockoutPhaseSection.tsx";
import { PredictionProgress } from "../../../../components/world-cup/PredictionProgress.tsx";
import type { KnockoutPhase } from "../../../../lib/contracts/enums.ts";
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

  const completedSlots = slots.filter((slot) => slot.prediction).length;

  const phases = [...new Set(slots.map((slot) => slot.phase))].sort(
    (phaseA, phaseB) => getKnockoutPhaseOrder(phaseA) - getKnockoutPhaseOrder(phaseB)
  );

  const slotsByPhase = phases.map((phase) => ({
    phase,
    slots: slots
      .filter((slot) => slot.phase === phase)
      .sort((slotA, slotB) => slotA.sortOrder - slotB.sortOrder)
  }));

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.PREDICTIONS}>
          ← Voltar para previsões
        </Link>

        <div className="mt-4 grid gap-4 lg:grid-cols-[1fr_360px]">
          <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
            <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
              Mata-mata
            </p>

            <h1 className="mt-3 text-2xl font-bold">Previsões do mata-mata</h1>

            <p className="mt-3 text-sm leading-6 text-app-muted">
              Escolha o vencedor previsto em cada slot. A estrutura está preparada dos
              16-avos até a final, respeitando o status dos dados oficiais.
            </p>
          </section>

          <PredictionProgress completed={completedSlots} label="Slots previstos" total={slots.length} />
        </div>

        <div className="mt-6">
          <KnockoutLegend />
        </div>

        <div className="mt-6 space-y-8">
          {slotsByPhase.map(({ phase, slots: phaseSlots }) => (
            <KnockoutPhaseSection
              key={phase}
              phase={phase as KnockoutPhase}
              slots={phaseSlots}
              teams={teams}
            />
          ))}
        </div>
      </section>
    </main>
  );
}
EOF

cat > docs/frontend-knockout.md <<'EOF'
# Bloco 10 — Frontend do mata-mata

## Objetivo

Criar uma experiência mobile first para previsões individuais do mata-mata.

## Componentes criados

- `KnockoutPhaseLabel`
- `KnockoutSlotCard`
- `KnockoutPhaseSection`
- `KnockoutLegend`

## Regras preservadas

- Nenhuma regra oficial de chaveamento é inventada no frontend.
- Slots exibem status de dados oficiais.
- Backend continua bloqueando placeholders em produção.
- Palpites são salvos por Server Action já validada no backend.

## Observações

O layout organiza slots por fase:

- 16-avos;
- oitavas;
- quartas;
- semifinais;
- disputa de 3º lugar;
- final.
EOF

cat > tests/frontend-knockout.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { getKnockoutPhaseLabel, getKnockoutPhaseOrder } from "../components/world-cup/KnockoutPhaseLabel.tsx";

describe("frontend knockout helpers", () => {
  it("deve retornar label em português para fases do mata-mata", () => {
    expect(getKnockoutPhaseLabel("ROUND_OF_32")).toBe("16-avos de final");
    expect(getKnockoutPhaseLabel("ROUND_OF_16")).toBe("Oitavas de final");
    expect(getKnockoutPhaseLabel("FINAL")).toBe("Final");
  });

  it("deve ordenar fases do mata-mata corretamente", () => {
    const phases = ["FINAL", "ROUND_OF_32", "SEMI_FINAL", "ROUND_OF_16"] as const;

    expect([...phases].sort((a, b) => getKnockoutPhaseOrder(a) - getKnockoutPhaseOrder(b))).toEqual([
      "ROUND_OF_32",
      "ROUND_OF_16",
      "SEMI_FINAL",
      "FINAL"
    ]);
  });
});
EOF

echo "==> Bloco 10 aplicado."
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
echo "  git commit -m \"feat: add knockout prediction frontend\""
echo "  git push"
