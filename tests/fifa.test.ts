import { describe, expect, it } from "vitest";
import { OFFICIAL_DATA_STATUS } from "@/lib/contracts/enums";
import { AppError } from "@/lib/errors/AppError";
import {
  assertGroupSelectionIsComplete,
  assertOfficialDataCanBeUsedInProduction,
  buildOfficialDataReadinessReport,
  extractThirdPlacedCandidates,
  toQualifiedGroupTeams
} from "@/lib/fifa";

const validSelection = {
  group: "A" as const,
  firstPlaceTeamId: "team_1",
  secondPlaceTeamId: "team_2",
  thirdPlaceTeamId: "team_3",
  fourthPlaceTeamId: "team_4"
};

describe("fifa engine foundation", () => {
  it("deve validar seleção completa e sem duplicidade", () => {
    expect(() => assertGroupSelectionIsComplete(validSelection)).not.toThrow();
  });

  it("deve rejeitar seleção de grupo com times duplicados", () => {
    expect(() =>
      assertGroupSelectionIsComplete({
        ...validSelection,
        fourthPlaceTeamId: "team_3"
      })
    ).toThrow(AppError);
  });

  it("deve extrair classificados de grupo sem montar chaveamento oficial", () => {
    expect(toQualifiedGroupTeams(validSelection)).toEqual({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_2",
      thirdPlaceTeamId: "team_3"
    });
  });

  it("deve extrair candidatos a terceiros colocados", () => {
    expect(extractThirdPlacedCandidates([validSelection])).toEqual([
      {
        group: "A",
        teamId: "team_3"
      }
    ]);
  });

  it("deve reportar dados oficiais incompletos", () => {
    const report = buildOfficialDataReadinessReport([
      {
        id: "x",
        officialDataStatus: OFFICIAL_DATA_STATUS.PLACEHOLDER,
        officialDataVersionId: null
      }
    ]);

    expect(report.canUseOfficialRules).toBe(false);
    expect(report.blockingReasons.length).toBeGreaterThan(0);
  });

  it("deve bloquear placeholders em produção", () => {
    expect(() =>
      assertOfficialDataCanBeUsedInProduction(
        [
          {
            id: "x",
            officialDataStatus: OFFICIAL_DATA_STATUS.PLACEHOLDER,
            officialDataVersionId: null
          }
        ],
        {
          nodeEnv: "production",
          allowOfficialDataPlaceholders: false
        }
      )
    ).toThrow(AppError);
  });
});
