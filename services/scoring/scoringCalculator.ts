import { SCORING_RULES, type ScoreBreakdown } from "./scoringRules.ts";

export type GroupPredictionForScoring = {
  firstPlaceTeamId: string;
  secondPlaceTeamId: string;
  thirdPlaceTeamId: string;
  fourthPlaceTeamId: string;
};

export type KnockoutPredictionForScoring = {
  winnerTeamId: string;
};

export function scoreGroupPrediction(
  prediction: GroupPredictionForScoring,
  realOrderedTeamIds: string[]
): ScoreBreakdown {
  const [realFirst, realSecond, realThird, realFourth] = realOrderedTeamIds;
  const items: ScoreBreakdown["items"] = [];
  let correctPredictions = 0;

  if (prediction.firstPlaceTeamId === realFirst) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_FIRST_PLACE",
      points: SCORING_RULES.GROUP_EXACT_FIRST_PLACE,
      description: "Acertou o 1º colocado do grupo."
    });
  }

  if (prediction.secondPlaceTeamId === realSecond) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_SECOND_PLACE",
      points: SCORING_RULES.GROUP_EXACT_SECOND_PLACE,
      description: "Acertou o 2º colocado do grupo."
    });
  }

  if (prediction.thirdPlaceTeamId === realThird) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_THIRD_PLACE",
      points: SCORING_RULES.GROUP_EXACT_THIRD_PLACE,
      description: "Acertou o 3º colocado do grupo."
    });
  }

  if (prediction.fourthPlaceTeamId === realFourth) {
    correctPredictions += 1;
    items.push({
      code: "GROUP_EXACT_FOURTH_PLACE",
      points: SCORING_RULES.GROUP_EXACT_FOURTH_PLACE,
      description: "Acertou o 4º colocado do grupo."
    });
  }

  const realQualifiedTeamIds = new Set(realOrderedTeamIds.slice(0, 3));
  const predictedQualifiedTeamIds = [
    prediction.firstPlaceTeamId,
    prediction.secondPlaceTeamId,
    prediction.thirdPlaceTeamId
  ];

  for (const predictedTeamId of predictedQualifiedTeamIds) {
    if (
      realQualifiedTeamIds.has(predictedTeamId) &&
      predictedTeamId !== realFirst &&
      predictedTeamId !== realSecond &&
      predictedTeamId !== realThird
    ) {
      items.push({
        code: "GROUP_QUALIFIED_TEAM_ANY_POSITION",
        points: SCORING_RULES.GROUP_QUALIFIED_TEAM_ANY_POSITION,
        description: "Acertou seleção classificada em posição diferente."
      });
    }
  }

  const totalScore = items.reduce((sum, item) => sum + item.points, 0);

  return {
    totalScore,
    correctPredictions,
    totalPredictions: 4,
    items
  };
}

export function scoreKnockoutPrediction(
  prediction: KnockoutPredictionForScoring,
  realWinnerTeamId: string
): ScoreBreakdown {
  if (prediction.winnerTeamId !== realWinnerTeamId) {
    return {
      totalScore: 0,
      correctPredictions: 0,
      totalPredictions: 1,
      items: []
    };
  }

  return {
    totalScore: SCORING_RULES.KNOCKOUT_EXACT_WINNER,
    correctPredictions: 1,
    totalPredictions: 1,
    items: [
      {
        code: "KNOCKOUT_EXACT_WINNER",
        points: SCORING_RULES.KNOCKOUT_EXACT_WINNER,
        description: "Acertou o vencedor do confronto."
      }
    ]
  };
}

export function mergeScoreBreakdowns(breakdowns: ScoreBreakdown[]): ScoreBreakdown {
  return breakdowns.reduce<ScoreBreakdown>(
    (accumulator, breakdown) => ({
      totalScore: accumulator.totalScore + breakdown.totalScore,
      correctPredictions: accumulator.correctPredictions + breakdown.correctPredictions,
      totalPredictions: accumulator.totalPredictions + breakdown.totalPredictions,
      items: [...accumulator.items, ...breakdown.items]
    }),
    {
      totalScore: 0,
      correctPredictions: 0,
      totalPredictions: 0,
      items: []
    }
  );
}
