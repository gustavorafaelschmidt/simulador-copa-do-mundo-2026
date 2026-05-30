import { AppError } from "../errors/AppError.ts";
import type {
  FifaGroupMatchResult,
  FifaTeamStanding,
  FifaTeamStandingInput,
  QualifiedTeamsResult
} from "./standingsTypes.ts";

function createInitialStanding(team: FifaTeamStandingInput): FifaTeamStanding {
  return {
    ...team,
    played: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    goalsFor: 0,
    goalsAgainst: 0,
    goalDifference: 0,
    points: 0,
    rank: 0
  };
}

function applyMatchToStanding(
  standing: FifaTeamStanding,
  goalsFor: number,
  goalsAgainst: number
): FifaTeamStanding {
  const isWin = goalsFor > goalsAgainst;
  const isDraw = goalsFor === goalsAgainst;

  const wins = standing.wins + (isWin ? 1 : 0);
  const draws = standing.draws + (isDraw ? 1 : 0);
  const losses = standing.losses + (!isWin && !isDraw ? 1 : 0);
  const totalGoalsFor = standing.goalsFor + goalsFor;
  const totalGoalsAgainst = standing.goalsAgainst + goalsAgainst;

  return {
    ...standing,
    played: standing.played + 1,
    wins,
    draws,
    losses,
    goalsFor: totalGoalsFor,
    goalsAgainst: totalGoalsAgainst,
    goalDifference: totalGoalsFor - totalGoalsAgainst,
    points: standing.points + (isWin ? 3 : isDraw ? 1 : 0)
  };
}

function comparePreviousRankings(
  teamA: FifaTeamStanding,
  teamB: FifaTeamStanding
): number {
  const maxLength = Math.max(
    teamA.previousFifaRankingPositions?.length ?? 0,
    teamB.previousFifaRankingPositions?.length ?? 0
  );

  for (let index = 0; index < maxLength; index += 1) {
    const rankingA = teamA.previousFifaRankingPositions?.[index] ?? Number.POSITIVE_INFINITY;
    const rankingB = teamB.previousFifaRankingPositions?.[index] ?? Number.POSITIVE_INFINITY;

    if (rankingA !== rankingB) {
      return rankingA - rankingB;
    }
  }

  return teamA.teamId.localeCompare(teamB.teamId);
}

function buildHeadToHeadStanding(
  team: FifaTeamStanding,
  tiedTeamIds: Set<string>,
  matches: FifaGroupMatchResult[]
): FifaTeamStanding {
  const base = createInitialStanding(team);

  return matches
    .filter(
      (match) => tiedTeamIds.has(match.homeTeamId) && tiedTeamIds.has(match.awayTeamId)
    )
    .reduce((standing, match) => {
      if (match.homeTeamId === team.teamId) {
        return applyMatchToStanding(standing, match.homeGoals, match.awayGoals);
      }

      if (match.awayTeamId === team.teamId) {
        return applyMatchToStanding(standing, match.awayGoals, match.homeGoals);
      }

      return standing;
    }, base);
}

function compareHeadToHead(
  teamA: FifaTeamStanding,
  teamB: FifaTeamStanding,
  allTeams: FifaTeamStanding[],
  matches: FifaGroupMatchResult[]
): number {
  const tiedTeamIds = new Set(
    allTeams
      .filter(
        (team) =>
          team.points === teamA.points &&
          team.goalDifference === teamA.goalDifference &&
          team.goalsFor === teamA.goalsFor
      )
      .map((team) => team.teamId)
  );

  if (tiedTeamIds.size < 2) {
    return 0;
  }

  const headToHeadA = buildHeadToHeadStanding(teamA, tiedTeamIds, matches);
  const headToHeadB = buildHeadToHeadStanding(teamB, tiedTeamIds, matches);

  return (
    headToHeadB.points - headToHeadA.points ||
    headToHeadB.goalDifference - headToHeadA.goalDifference ||
    headToHeadB.goalsFor - headToHeadA.goalsFor
  );
}

export function buildGroupStandings(
  teams: FifaTeamStandingInput[],
  matches: FifaGroupMatchResult[]
): FifaTeamStanding[] {
  if (teams.length !== 4) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Cada grupo FIFA precisa ter exatamente quatro seleções.",
      statusCode: 422
    });
  }

  const group = teams[0]?.group;

  if (!group || teams.some((team) => team.group !== group)) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as seleções devem pertencer ao mesmo grupo.",
      statusCode: 422
    });
  }

  const teamIds = new Set(teams.map((team) => team.teamId));

  for (const match of matches) {
    if (match.group !== group) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Todas as partidas devem pertencer ao mesmo grupo.",
        statusCode: 422
      });
    }

    if (!teamIds.has(match.homeTeamId) || !teamIds.has(match.awayTeamId)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Partida possui seleção fora do grupo.",
        statusCode: 422
      });
    }
  }

  const standingsByTeamId = new Map(
    teams.map((team) => [team.teamId, createInitialStanding(team)])
  );

  for (const match of matches) {
    const homeStanding = standingsByTeamId.get(match.homeTeamId);
    const awayStanding = standingsByTeamId.get(match.awayTeamId);

    if (!homeStanding || !awayStanding) {
      continue;
    }

    standingsByTeamId.set(
      match.homeTeamId,
      applyMatchToStanding(homeStanding, match.homeGoals, match.awayGoals)
    );
    standingsByTeamId.set(
      match.awayTeamId,
      applyMatchToStanding(awayStanding, match.awayGoals, match.homeGoals)
    );
  }

  return [...standingsByTeamId.values()];
}

export function rankGroupStandings(
  standings: FifaTeamStanding[],
  matches: FifaGroupMatchResult[]
): FifaTeamStanding[] {
  const ranked = [...standings].sort(
    (teamA, teamB) =>
      teamB.points - teamA.points ||
      teamB.goalDifference - teamA.goalDifference ||
      teamB.goalsFor - teamA.goalsFor ||
      compareHeadToHead(teamA, teamB, standings, matches) ||
      teamB.teamConductScore - teamA.teamConductScore ||
      teamA.fifaRankingPosition - teamB.fifaRankingPosition ||
      comparePreviousRankings(teamA, teamB)
  );

  return ranked.map((team, index) => ({
    ...team,
    rank: index + 1
  }));
}

export function rankThirdPlacedTeams(thirdPlacedTeams: FifaTeamStanding[]): FifaTeamStanding[] {
  return [...thirdPlacedTeams].sort(
    (teamA, teamB) =>
      teamB.points - teamA.points ||
      teamB.goalDifference - teamA.goalDifference ||
      teamB.goalsFor - teamA.goalsFor ||
      teamB.teamConductScore - teamA.teamConductScore ||
      teamA.fifaRankingPosition - teamB.fifaRankingPosition ||
      comparePreviousRankings(teamA, teamB)
  );
}

export function selectQualifiedTeamsFromRankedGroups(
  rankedGroups: FifaTeamStanding[][]
): QualifiedTeamsResult {
  if (rankedGroups.length !== 12) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "A fase de grupos da Copa 2026 precisa conter 12 grupos.",
      statusCode: 422
    });
  }

  const groupWinners = rankedGroups.map((group) => group[0]).filter(Boolean);
  const groupRunnersUp = rankedGroups.map((group) => group[1]).filter(Boolean);
  const thirdPlacedTeams = rankedGroups.map((group) => group[2]).filter(Boolean);
  const bestThirdPlacedTeams = rankThirdPlacedTeams(thirdPlacedTeams).slice(0, 8);
  const qualifiedTeams = [...groupWinners, ...groupRunnersUp, ...bestThirdPlacedTeams];

  return {
    groupWinners,
    groupRunnersUp,
    thirdPlacedTeams,
    bestThirdPlacedTeams,
    qualifiedTeams
  };
}
