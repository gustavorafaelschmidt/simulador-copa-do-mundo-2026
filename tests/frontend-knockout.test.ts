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
