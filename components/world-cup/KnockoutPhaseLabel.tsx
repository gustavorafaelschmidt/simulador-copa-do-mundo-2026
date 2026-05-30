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
