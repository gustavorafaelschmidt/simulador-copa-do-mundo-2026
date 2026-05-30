import { describe, expect, it } from "vitest";
import {
  mergeScoreBreakdowns,
  scoreGroupPrediction,
  scoreKnockoutPrediction
} from "../services/scoring/scoringCalculator.ts";

describe("scoring and ranking foundation", () => {
  it("deve pontuar previsão exata de grupo", () => {
    const result = scoreGroupPrediction(
      {
        firstPlaceTeamId: "team_1",
        secondPlaceTeamId: "team_2",
        thirdPlaceTeamId: "team_3",
        fourthPlaceTeamId: "team_4"
      },
      ["team_1", "team_2", "team_3", "team_4"]
    );

    expect(result.totalScore).toBe(33);
    expect(result.correctPredictions).toBe(4);
  });

  it("deve pontuar vencedor de mata-mata", () => {
    expect(
      scoreKnockoutPrediction(
        {
          winnerTeamId: "team_1"
        },
        "team_1"
      )
    ).toMatchObject({
      totalScore: 15,
      correctPredictions: 1
    });
  });

  it("não deve pontuar vencedor errado de mata-mata", () => {
    expect(
      scoreKnockoutPrediction(
        {
          winnerTeamId: "team_2"
        },
        "team_1"
      )
    ).toMatchObject({
      totalScore: 0,
      correctPredictions: 0
    });
  });

  it("deve mesclar breakdowns de pontuação", () => {
    const group = scoreGroupPrediction(
      {
        firstPlaceTeamId: "team_1",
        secondPlaceTeamId: "team_2",
        thirdPlaceTeamId: "team_3",
        fourthPlaceTeamId: "team_4"
      },
      ["team_1", "team_2", "team_3", "team_4"]
    );

    const knockout = scoreKnockoutPrediction(
      {
        winnerTeamId: "team_1"
      },
      "team_1"
    );

    expect(mergeScoreBreakdowns([group, knockout])).toMatchObject({
      totalScore: 48,
      correctPredictions: 5,
      totalPredictions: 5
    });
  });
});
