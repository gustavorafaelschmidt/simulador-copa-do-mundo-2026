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
