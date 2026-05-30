import type { GroupLetter } from "../../lib/contracts/enums.ts";
import type {
  GroupConsensusCalculation,
  GroupConsensusVoteSummary,
  GroupVoteForConsensus,
  GroupVoteSelection,
  KnockoutConsensusCalculation,
  KnockoutConsensusVoteSummary,
  KnockoutVoteForConsensus,
  PositionVoteSummary,
  VoteCount
} from "./consensusTypes.ts";

function incrementCount(counts: VoteCount, teamId: string): VoteCount {
  return {
    ...counts,
    [teamId]: (counts[teamId] ?? 0) + 1
  };
}

export function countVotes(teamIds: string[]): VoteCount {
  return teamIds.reduce<VoteCount>((counts, teamId) => incrementCount(counts, teamId), {});
}

export function summarizePositionVotes(teamIds: string[]): PositionVoteSummary {
  const counts = countVotes(teamIds);
  const entries = Object.entries(counts);

  if (entries.length === 0) {
    return {
      counts,
      leaderTeamId: null,
      tiedTeamIds: []
    };
  }

  const highestVoteCount = Math.max(...entries.map(([, count]) => count));
  const leaders = entries
    .filter(([, count]) => count === highestVoteCount)
    .map(([teamId]) => teamId);

  return {
    counts,
    leaderTeamId: leaders.length === 1 ? leaders[0] ?? null : null,
    tiedTeamIds: leaders.length > 1 ? leaders : []
  };
}

export function calculateGroupConsensus(
  group: GroupLetter,
  votes: GroupVoteForConsensus[]
): GroupConsensusCalculation {
  const firstPlace = summarizePositionVotes(votes.map((vote) => vote.firstPlaceTeamId));
  const secondPlace = summarizePositionVotes(votes.map((vote) => vote.secondPlaceTeamId));
  const thirdPlace = summarizePositionVotes(votes.map((vote) => vote.thirdPlaceTeamId));
  const fourthPlace = summarizePositionVotes(votes.map((vote) => vote.fourthPlaceTeamId));

  const summary: GroupConsensusVoteSummary = {
    group,
    totalVotes: votes.length,
    positions: {
      firstPlace,
      secondPlace,
      thirdPlace,
      fourthPlace
    },
    blockingReason: null
  };

  if (votes.length === 0) {
    return {
      status: "TIEBREAKER_REQUIRED",
      voteSummary: {
        ...summary,
        blockingReason: "Nenhum voto registrado."
      }
    };
  }

  const hasPositionTie =
    firstPlace.tiedTeamIds.length > 0 ||
    secondPlace.tiedTeamIds.length > 0 ||
    thirdPlace.tiedTeamIds.length > 0 ||
    fourthPlace.tiedTeamIds.length > 0;

  if (
    hasPositionTie ||
    !firstPlace.leaderTeamId ||
    !secondPlace.leaderTeamId ||
    !thirdPlace.leaderTeamId ||
    !fourthPlace.leaderTeamId
  ) {
    return {
      status: "TIEBREAKER_REQUIRED",
      voteSummary: {
        ...summary,
        blockingReason: "Empate no topo de uma ou mais posições."
      }
    };
  }

  const selection: GroupVoteSelection = {
    firstPlaceTeamId: firstPlace.leaderTeamId,
    secondPlaceTeamId: secondPlace.leaderTeamId,
    thirdPlaceTeamId: thirdPlace.leaderTeamId,
    fourthPlaceTeamId: fourthPlace.leaderTeamId
  };

  const selectedTeamIds = Object.values(selection);

  if (new Set(selectedTeamIds).size !== selectedTeamIds.length) {
    return {
      status: "TIEBREAKER_REQUIRED",
      voteSummary: {
        ...summary,
        blockingReason:
          "A maioria por posição gerou uma seleção inconsistente com equipe duplicada."
      }
    };
  }

  return {
    status: "CONSENSUS",
    selection,
    voteSummary: summary
  };
}

export function calculateKnockoutConsensus(
  votes: KnockoutVoteForConsensus[]
): KnockoutConsensusCalculation {
  const positionSummary = summarizePositionVotes(votes.map((vote) => vote.winnerTeamId));

  const summary: KnockoutConsensusVoteSummary = {
    totalVotes: votes.length,
    counts: positionSummary.counts,
    leaderTeamId: positionSummary.leaderTeamId,
    tiedTeamIds: positionSummary.tiedTeamIds,
    blockingReason: null
  };

  if (votes.length === 0) {
    return {
      status: "TIEBREAKER_REQUIRED",
      voteSummary: {
        ...summary,
        blockingReason: "Nenhum voto registrado."
      }
    };
  }

  if (!positionSummary.leaderTeamId || positionSummary.tiedTeamIds.length > 0) {
    return {
      status: "TIEBREAKER_REQUIRED",
      voteSummary: {
        ...summary,
        blockingReason: "Empate no topo do confronto."
      }
    };
  }

  return {
    status: "CONSENSUS",
    winnerTeamId: positionSummary.leaderTeamId,
    voteSummary: summary
  };
}
