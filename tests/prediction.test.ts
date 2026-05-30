import { describe, expect, it } from "vitest";
import { AppError } from "../lib/errors/AppError.ts";
import {
  assertDistinctTeamIds,
  deriveFourthPlaceTeamId
} from "../services/prediction/predictionUtils.ts";
import {
  toIndividualGroupPredictionDTO,
  toIndividualKnockoutPredictionDTO
} from "../services/prediction/predictionMapper.ts";
import { saveIndividualGroupTopThreePredictionSchema } from "../lib/validations/individualPrediction.ts";

describe("individual predictions", () => {
  it("deve validar top 3 distintos", () => {
    const result = saveIndividualGroupTopThreePredictionSchema.safeParse({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_2",
      thirdPlaceTeamId: "team_3"
    });

    expect(result.success).toBe(true);
  });

  it("deve rejeitar top 3 duplicado", () => {
    const result = saveIndividualGroupTopThreePredictionSchema.safeParse({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_1",
      thirdPlaceTeamId: "team_3"
    });

    expect(result.success).toBe(false);
  });

  it("deve calcular automaticamente o quarto colocado", () => {
    expect(
      deriveFourthPlaceTeamId(["team_1", "team_2", "team_3", "team_4"], [
        "team_1",
        "team_3",
        "team_2"
      ])
    ).toBe("team_4");
  });

  it("deve rejeitar grupo com quantidade inválida de seleções", () => {
    expect(() =>
      deriveFourthPlaceTeamId(["team_1", "team_2", "team_3"], [
        "team_1",
        "team_2",
        "team_3"
      ])
    ).toThrow(AppError);
  });

  it("deve rejeitar ids duplicados", () => {
    expect(() => assertDistinctTeamIds(["team_1", "team_1"])).toThrow(AppError);
  });

  it("deve serializar previsão de grupo", () => {
    const now = new Date("2026-01-01T00:00:00.000Z");

    expect(
      toIndividualGroupPredictionDTO({
        id: "prediction_1",
        userId: "user_1",
        group: "A",
        firstPlaceTeamId: "team_1",
        secondPlaceTeamId: "team_2",
        thirdPlaceTeamId: "team_3",
        fourthPlaceTeamId: "team_4",
        lockedAt: null,
        submittedAt: now,
        createdAt: now,
        updatedAt: now
      })
    ).toMatchObject({
      id: "prediction_1",
      submittedAt: "2026-01-01T00:00:00.000Z"
    });
  });

  it("deve serializar previsão de mata-mata", () => {
    const now = new Date("2026-01-01T00:00:00.000Z");

    expect(
      toIndividualKnockoutPredictionDTO({
        id: "prediction_2",
        userId: "user_1",
        bracketSlotId: "slot_1",
        winnerTeamId: "team_1",
        lockedAt: null,
        submittedAt: now,
        createdAt: now,
        updatedAt: now
      })
    ).toMatchObject({
      id: "prediction_2",
      winnerTeamId: "team_1"
    });
  });
});
