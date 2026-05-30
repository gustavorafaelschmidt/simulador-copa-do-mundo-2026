import { prisma } from "../../lib/db/prisma.ts";
import { REAL_RESULT_TYPE } from "../../lib/contracts/enums.ts";
import {
  groupStandingResultPayloadSchema,
  knockoutMatchResultPayloadSchema
} from "./resultPayloads.ts";
import {
  mergeScoreBreakdowns,
  scoreGroupPrediction,
  scoreKnockoutPrediction
} from "./scoringCalculator.ts";
import type { ScoreBreakdown } from "./scoringRules.ts";

export type ParticipantScore = {
  participantKey: string;
  userId: string | null;
  teamId: string | null;
  score: number;
  correctPredictions: number;
  totalPredictions: number;
  metadata: ScoreBreakdown;
};

export async function calculateIndividualScores(): Promise<ParticipantScore[]> {
  const [groupPredictions, knockoutPredictions, realResults] = await Promise.all([
    prisma.individualGroupPrediction.findMany(),
    prisma.individualKnockoutPrediction.findMany(),
    prisma.realTournamentResult.findMany()
  ]);

  const realGroupResultsByGroup = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.GROUP_STANDING && result.group)
      .map((result) => [result.group, groupStandingResultPayloadSchema.safeParse(result.payload)])
  );

  const realKnockoutResultsBySlot = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && result.bracketSlotId)
      .map((result) => [
        result.bracketSlotId,
        knockoutMatchResultPayloadSchema.safeParse(result.payload)
      ])
  );

  const breakdownsByUserId = new Map<string, ScoreBreakdown[]>();

  for (const prediction of groupPredictions) {
    const realResult = realGroupResultsByGroup.get(prediction.group);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreGroupPrediction(prediction, realResult.data.orderedTeamIds);
    const existingBreakdowns = breakdownsByUserId.get(prediction.userId) ?? [];

    breakdownsByUserId.set(prediction.userId, [...existingBreakdowns, breakdown]);
  }

  for (const prediction of knockoutPredictions) {
    const realResult = realKnockoutResultsBySlot.get(prediction.bracketSlotId);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreKnockoutPrediction(prediction, realResult.data.winnerTeamId);
    const existingBreakdowns = breakdownsByUserId.get(prediction.userId) ?? [];

    breakdownsByUserId.set(prediction.userId, [...existingBreakdowns, breakdown]);
  }

  return [...breakdownsByUserId.entries()].map(([userId, breakdowns]) => {
    const metadata = mergeScoreBreakdowns(breakdowns);

    return {
      participantKey: `user:${userId}`,
      userId,
      teamId: null,
      score: metadata.totalScore,
      correctPredictions: metadata.correctPredictions,
      totalPredictions: metadata.totalPredictions,
      metadata
    };
  });
}

export async function calculateTeamScores(): Promise<ParticipantScore[]> {
  const [groupConsensuses, knockoutConsensuses, realResults] = await Promise.all([
    prisma.teamGroupConsensus.findMany(),
    prisma.teamKnockoutConsensus.findMany(),
    prisma.realTournamentResult.findMany()
  ]);

  const realGroupResultsByGroup = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.GROUP_STANDING && result.group)
      .map((result) => [result.group, groupStandingResultPayloadSchema.safeParse(result.payload)])
  );

  const realKnockoutResultsBySlot = new Map(
    realResults
      .filter((result) => result.type === REAL_RESULT_TYPE.KNOCKOUT_MATCH && result.bracketSlotId)
      .map((result) => [
        result.bracketSlotId,
        knockoutMatchResultPayloadSchema.safeParse(result.payload)
      ])
  );

  const breakdownsByTeamId = new Map<string, ScoreBreakdown[]>();

  for (const consensus of groupConsensuses) {
    const realResult = realGroupResultsByGroup.get(consensus.group);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreGroupPrediction(consensus, realResult.data.orderedTeamIds);
    const existingBreakdowns = breakdownsByTeamId.get(consensus.teamId) ?? [];

    breakdownsByTeamId.set(consensus.teamId, [...existingBreakdowns, breakdown]);
  }

  for (const consensus of knockoutConsensuses) {
    const realResult = realKnockoutResultsBySlot.get(consensus.bracketSlotId);

    if (!realResult?.success) {
      continue;
    }

    const breakdown = scoreKnockoutPrediction(consensus, realResult.data.winnerTeamId);
    const existingBreakdowns = breakdownsByTeamId.get(consensus.teamId) ?? [];

    breakdownsByTeamId.set(consensus.teamId, [...existingBreakdowns, breakdown]);
  }

  return [...breakdownsByTeamId.entries()].map(([teamId, breakdowns]) => {
    const metadata = mergeScoreBreakdowns(breakdowns);

    return {
      participantKey: `team:${teamId}`,
      userId: null,
      teamId,
      score: metadata.totalScore,
      correctPredictions: metadata.correctPredictions,
      totalPredictions: metadata.totalPredictions,
      metadata
    };
  });
}
