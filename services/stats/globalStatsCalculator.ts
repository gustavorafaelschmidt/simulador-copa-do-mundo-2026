export type GlobalStatsInput = {
  usersCount: number;
  teamsCount: number;
  individualPredictionsCount: number;
  teamConsensusCount: number;
  realResultsCount: number;
  rankingSnapshotsCount: number;
};

export type GlobalStatsPayload = GlobalStatsInput & {
  engagementRate: number;
};

export function calculateEngagementRate(input: GlobalStatsInput): number {
  if (input.usersCount <= 0) {
    return 0;
  }

  return Number(((input.individualPredictionsCount / input.usersCount) * 100).toFixed(2));
}

export function buildGlobalStatsPayload(input: GlobalStatsInput): GlobalStatsPayload {
  return {
    ...input,
    engagementRate: calculateEngagementRate(input)
  };
}
