export const BADGE_RULE_CODES = {
  FIRST_GROUP_PREDICTION: "FIRST_GROUP_PREDICTION",
  ALL_GROUPS_PREDICTED: "ALL_GROUPS_PREDICTED",
  FIRST_TEAM_CREATED: "FIRST_TEAM_CREATED",
  FIRST_TEAM_JOINED: "FIRST_TEAM_JOINED",
  FIRST_TEAM_CONSENSUS: "FIRST_TEAM_CONSENSUS",
  FIRST_RANKING_POINTS: "FIRST_RANKING_POINTS"
} as const;

export type BadgeRuleCode = (typeof BADGE_RULE_CODES)[keyof typeof BADGE_RULE_CODES];

export type BadgeEvaluationContext = {
  groupPredictionsCount: number;
  teamsOwnedCount: number;
  approvedTeamMembershipsCount: number;
  teamConsensusCount: number;
  rankingScore: number;
};

export type BadgeAwardCandidate = {
  badgeCode: BadgeRuleCode;
  reason: string;
};

export function evaluateUserBadgeCandidates(
  context: BadgeEvaluationContext
): BadgeAwardCandidate[] {
  const candidates: BadgeAwardCandidate[] = [];

  if (context.groupPredictionsCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_GROUP_PREDICTION,
      reason: "Usuário salvou a primeira previsão de grupo."
    });
  }

  if (context.groupPredictionsCount >= 12) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.ALL_GROUPS_PREDICTED,
      reason: "Usuário salvou previsões para todos os 12 grupos."
    });
  }

  if (context.teamsOwnedCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_TEAM_CREATED,
      reason: "Usuário criou sua primeira equipe."
    });
  }

  if (context.approvedTeamMembershipsCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_TEAM_JOINED,
      reason: "Usuário entrou em uma equipe aprovada."
    });
  }

  if (context.teamConsensusCount >= 1) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_TEAM_CONSENSUS,
      reason: "Usuário participa de equipe com primeiro consenso definido."
    });
  }

  if (context.rankingScore > 0) {
    candidates.push({
      badgeCode: BADGE_RULE_CODES.FIRST_RANKING_POINTS,
      reason: "Usuário somou seus primeiros pontos no ranking."
    });
  }

  return candidates;
}
