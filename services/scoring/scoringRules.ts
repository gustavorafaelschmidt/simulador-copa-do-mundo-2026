export const SCORING_RULES = {
  GROUP_EXACT_FIRST_PLACE: 10,
  GROUP_EXACT_SECOND_PLACE: 10,
  GROUP_EXACT_THIRD_PLACE: 8,
  GROUP_EXACT_FOURTH_PLACE: 5,
  GROUP_QUALIFIED_TEAM_ANY_POSITION: 3,
  KNOCKOUT_EXACT_WINNER: 15
} as const;

export type ScoreBreakdownItem = {
  code: keyof typeof SCORING_RULES;
  points: number;
  description: string;
};

export type ScoreBreakdown = {
  totalScore: number;
  correctPredictions: number;
  totalPredictions: number;
  items: ScoreBreakdownItem[];
};
