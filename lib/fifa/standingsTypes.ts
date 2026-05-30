import type { GroupLetter } from "../contracts/enums.ts";

export type FifaTeamStandingInput = {
  teamId: string;
  group: GroupLetter;
  fifaRankingPosition: number;
  previousFifaRankingPositions?: number[];
  teamConductScore: number;
};

export type FifaGroupMatchResult = {
  group: GroupLetter;
  homeTeamId: string;
  awayTeamId: string;
  homeGoals: number;
  awayGoals: number;
};

export type FifaTeamStanding = FifaTeamStandingInput & {
  played: number;
  wins: number;
  draws: number;
  losses: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
  points: number;
  rank: number;
};

export type QualifiedTeamsResult = {
  groupWinners: FifaTeamStanding[];
  groupRunnersUp: FifaTeamStanding[];
  thirdPlacedTeams: FifaTeamStanding[];
  bestThirdPlacedTeams: FifaTeamStanding[];
  qualifiedTeams: FifaTeamStanding[];
};
