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
