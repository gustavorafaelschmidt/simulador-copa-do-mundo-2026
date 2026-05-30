import type { GroupLetter } from "../../lib/contracts/enums.ts";
import type { NationalTeamId } from "../../lib/contracts/officialData.ts";

export type GroupVoteSelection = {
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
};

export type GroupVoteForConsensus = GroupVoteSelection & {
  userId: string;
};

export type KnockoutVoteForConsensus = {
  userId: string;
  winnerTeamId: NationalTeamId;
};

export type VoteCount = Record<NationalTeamId, number>;

export type PositionVoteSummary = {
  counts: VoteCount;
  leaderTeamId: NationalTeamId | null;
  tiedTeamIds: NationalTeamId[];
};

export type GroupConsensusVoteSummary = {
  group: GroupLetter;
  totalVotes: number;
  positions: {
    firstPlace: PositionVoteSummary;
    secondPlace: PositionVoteSummary;
    thirdPlace: PositionVoteSummary;
    fourthPlace: PositionVoteSummary;
  };
  blockingReason: string | null;
};

export type KnockoutConsensusVoteSummary = {
  totalVotes: number;
  counts: VoteCount;
  leaderTeamId: NationalTeamId | null;
  tiedTeamIds: NationalTeamId[];
  blockingReason: string | null;
};

export type GroupConsensusCalculation =
  | {
      status: "CONSENSUS";
      selection: GroupVoteSelection;
      voteSummary: GroupConsensusVoteSummary;
    }
  | {
      status: "TIEBREAKER_REQUIRED";
      voteSummary: GroupConsensusVoteSummary;
    };

export type KnockoutConsensusCalculation =
  | {
      status: "CONSENSUS";
      winnerTeamId: NationalTeamId;
      voteSummary: KnockoutConsensusVoteSummary;
    }
  | {
      status: "TIEBREAKER_REQUIRED";
      voteSummary: KnockoutConsensusVoteSummary;
    };
