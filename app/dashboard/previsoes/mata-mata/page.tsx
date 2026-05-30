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
