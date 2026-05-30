#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 7 — recriando services/consensus ausentes..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/consensus docs tests

cat > services/consensus/consensusTypes.ts <<'EOF'
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
EOF

cat > services/consensus/consensusCalculator.ts <<'EOF'
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
EOF

cat > services/consensus/consensusService.ts <<'EOF'
import { prisma } from "../../lib/db/prisma.ts";
import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE
} from "../../lib/contracts/enums.ts";
import type {
  CloseVotingSessionInputDTO,
  OpenGroupVotingSessionInputDTO,
  OpenKnockoutVotingSessionInputDTO,
  SubmitGroupVoteInputDTO,
  SubmitKnockoutTiebreakerInputDTO,
  SubmitKnockoutVoteInputDTO
} from "../../lib/contracts/voting.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import { assertGroupSelectionIsComplete } from "../../lib/fifa/groupPrediction.ts";
import { assertApprovedTeamMember, assertTeamCaptain } from "../team/teamService.ts";
import {
  calculateGroupConsensus,
  calculateKnockoutConsensus
} from "./consensusCalculator.ts";
import type { GroupVoteSelection } from "./consensusTypes.ts";

export type ApplyGroupTiebreakerInput = CloseVotingSessionInputDTO &
  GroupVoteSelection & {
    group: string;
  };

async function ensureNoOpenVotingSessionForGroup(teamId: string, group: string) {
  const activeSession = await prisma.votingSession.findFirst({
    where: {
      teamId,
      group,
      type: VOTING_SESSION_TYPE.GROUP_STAGE,
      status: {
        in: [VOTING_SESSION_STATUS.OPEN, VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED]
      }
    },
    select: {
      id: true
    }
  });

  if (activeSession) {
    throw new AppError({
      code: "CONFLICT",
      message: "Já existe uma votação ativa para este grupo.",
      statusCode: 409
    });
  }
}

async function ensureNoOpenVotingSessionForBracketSlot(teamId: string, bracketSlotId: string) {
  const activeSession = await prisma.votingSession.findFirst({
    where: {
      teamId,
      bracketSlotId,
      type: VOTING_SESSION_TYPE.KNOCKOUT,
      status: {
        in: [VOTING_SESSION_STATUS.OPEN, VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED]
      }
    },
    select: {
      id: true
    }
  });

  if (activeSession) {
    throw new AppError({
      code: "CONFLICT",
      message: "Já existe uma votação ativa para este confronto.",
      statusCode: 409
    });
  }
}

async function getVotingSessionOrThrow(votingSessionId: string, teamId: string) {
  const votingSession = await prisma.votingSession.findUnique({
    where: {
      id: votingSessionId
    }
  });

  if (!votingSession || votingSession.teamId !== teamId) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Sessão de votação não encontrada.",
      statusCode: 404
    });
  }

  return votingSession;
}

export async function openGroupVotingSession(
  captainUserId: string,
  input: OpenGroupVotingSessionInputDTO
) {
  await assertTeamCaptain(input.teamId, captainUserId);
  await ensureNoOpenVotingSessionForGroup(input.teamId, input.group);

  return prisma.votingSession.create({
    data: {
      teamId: input.teamId,
      type: VOTING_SESSION_TYPE.GROUP_STAGE,
      status: VOTING_SESSION_STATUS.OPEN,
      group: input.group,
      openedByUserId: captainUserId,
      openedAt: new Date()
    }
  });
}

export async function openKnockoutVotingSession(
  captainUserId: string,
  input: OpenKnockoutVotingSessionInputDTO
) {
  await assertTeamCaptain(input.teamId, captainUserId);
  await ensureNoOpenVotingSessionForBracketSlot(input.teamId, input.bracketSlotId);

  return prisma.votingSession.create({
    data: {
      teamId: input.teamId,
      type: VOTING_SESSION_TYPE.KNOCKOUT,
      status: VOTING_SESSION_STATUS.OPEN,
      bracketSlotId: input.bracketSlotId,
      openedByUserId: captainUserId,
      openedAt: new Date()
    }
  });
}

export async function submitGroupVote(userId: string, input: SubmitGroupVoteInputDTO) {
  await assertApprovedTeamMember(input.teamId, userId);

  const votingSession = await getVotingSessionOrThrow(input.votingSessionId, input.teamId);

  if (
    votingSession.type !== VOTING_SESSION_TYPE.GROUP_STAGE ||
    votingSession.status !== VOTING_SESSION_STATUS.OPEN ||
    votingSession.group !== input.group
  ) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "A sessão de votação de grupo não está aberta para este grupo.",
      statusCode: 422
    });
  }

  assertGroupSelectionIsComplete({
    group: input.group,
    firstPlaceTeamId: input.firstPlaceTeamId,
    secondPlaceTeamId: input.secondPlaceTeamId,
    thirdPlaceTeamId: input.thirdPlaceTeamId,
    fourthPlaceTeamId: input.fourthPlaceTeamId
  });

  return prisma.teamGroupVote.upsert({
    where: {
      userId_votingSessionId_teamId_group: {
        userId,
        votingSessionId: input.votingSessionId,
        teamId: input.teamId,
        group: input.group
      }
    },
    update: {
      firstPlaceTeamId: input.firstPlaceTeamId,
      secondPlaceTeamId: input.secondPlaceTeamId,
      thirdPlaceTeamId: input.thirdPlaceTeamId,
      fourthPlaceTeamId: input.fourthPlaceTeamId
    },
    create: {
      userId,
      votingSessionId: input.votingSessionId,
      teamId: input.teamId,
      group: input.group,
      firstPlaceTeamId: input.firstPlaceTeamId,
      secondPlaceTeamId: input.secondPlaceTeamId,
      thirdPlaceTeamId: input.thirdPlaceTeamId,
      fourthPlaceTeamId: input.fourthPlaceTeamId
    }
  });
}

export async function submitKnockoutVote(userId: string, input: SubmitKnockoutVoteInputDTO) {
  await assertApprovedTeamMember(input.teamId, userId);

  const votingSession = await getVotingSessionOrThrow(input.votingSessionId, input.teamId);

  if (
    votingSession.type !== VOTING_SESSION_TYPE.KNOCKOUT ||
    votingSession.status !== VOTING_SESSION_STATUS.OPEN ||
    votingSession.bracketSlotId !== input.bracketSlotId
  ) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "A sessão de votação de mata-mata não está aberta para este confronto.",
      statusCode: 422
    });
  }

  return prisma.teamKnockoutVote.upsert({
    where: {
      userId_votingSessionId_teamId_bracketSlotId: {
        userId,
        votingSessionId: input.votingSessionId,
        teamId: input.teamId,
        bracketSlotId: input.bracketSlotId
      }
    },
    update: {
      winnerTeamId: input.winnerTeamId
    },
    create: {
      userId,
      votingSessionId: input.votingSessionId,
      teamId: input.teamId,
      bracketSlotId: input.bracketSlotId,
      winnerTeamId: input.winnerTeamId
    }
  });
}

export async function closeVotingSession(
  captainUserId: string,
  input: CloseVotingSessionInputDTO
) {
  await assertTeamCaptain(input.teamId, captainUserId);

  const votingSession = await getVotingSessionOrThrow(input.votingSessionId, input.teamId);

  if (votingSession.status !== VOTING_SESSION_STATUS.OPEN) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "A sessão de votação não está aberta.",
      statusCode: 422
    });
  }

  if (votingSession.type === VOTING_SESSION_TYPE.GROUP_STAGE) {
    if (!votingSession.group) {
      throw new AppError({
        code: "BUSINESS_RULE_VIOLATION",
        message: "Sessão de grupo sem grupo definido.",
        statusCode: 422
      });
    }

    const votes = await prisma.teamGroupVote.findMany({
      where: {
        teamId: input.teamId,
        votingSessionId: input.votingSessionId,
        group: votingSession.group
      },
      select: {
        userId: true,
        firstPlaceTeamId: true,
        secondPlaceTeamId: true,
        thirdPlaceTeamId: true,
        fourthPlaceTeamId: true
      }
    });

    const calculation = calculateGroupConsensus(votingSession.group, votes);

    if (calculation.status === "TIEBREAKER_REQUIRED") {
      return prisma.votingSession.update({
        where: {
          id: input.votingSessionId
        },
        data: {
          status: VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED,
          closedByUserId: captainUserId,
          closedAt: new Date(),
          tiebreakerPayload: calculation.voteSummary
        }
      });
    }

    return prisma.$transaction(async (tx) => {
      await tx.teamGroupConsensus.upsert({
        where: {
          teamId_votingSessionId_group: {
            teamId: input.teamId,
            votingSessionId: input.votingSessionId,
            group: votingSession.group
          }
        },
        update: {
          ...calculation.selection,
          decisionType: CONSENSUS_DECISION_TYPE.MAJORITY,
          decidedByUserId: null,
          voteSummary: calculation.voteSummary
        },
        create: {
          teamId: input.teamId,
          votingSessionId: input.votingSessionId,
          group: votingSession.group,
          ...calculation.selection,
          decisionType: CONSENSUS_DECISION_TYPE.MAJORITY,
          decidedByUserId: null,
          voteSummary: calculation.voteSummary
        }
      });

      return tx.votingSession.update({
        where: {
          id: input.votingSessionId
        },
        data: {
          status: VOTING_SESSION_STATUS.CLOSED,
          closedByUserId: captainUserId,
          closedAt: new Date(),
          tiebreakerPayload: null
        }
      });
    });
  }

  if (!votingSession.bracketSlotId) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "Sessão de mata-mata sem confronto definido.",
      statusCode: 422
    });
  }

  const votes = await prisma.teamKnockoutVote.findMany({
    where: {
      teamId: input.teamId,
      votingSessionId: input.votingSessionId,
      bracketSlotId: votingSession.bracketSlotId
    },
    select: {
      userId: true,
      winnerTeamId: true
    }
  });

  const calculation = calculateKnockoutConsensus(votes);

  if (calculation.status === "TIEBREAKER_REQUIRED") {
    return prisma.votingSession.update({
      where: {
        id: input.votingSessionId
      },
      data: {
        status: VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED,
        closedByUserId: captainUserId,
        closedAt: new Date(),
        tiebreakerPayload: calculation.voteSummary
      }
    });
  }

  return prisma.$transaction(async (tx) => {
    await tx.teamKnockoutConsensus.upsert({
      where: {
        teamId_votingSessionId_bracketSlotId: {
          teamId: input.teamId,
          votingSessionId: input.votingSessionId,
          bracketSlotId: votingSession.bracketSlotId
        }
      },
      update: {
        winnerTeamId: calculation.winnerTeamId,
        decisionType: CONSENSUS_DECISION_TYPE.MAJORITY,
        decidedByUserId: null,
        voteSummary: calculation.voteSummary
      },
      create: {
        teamId: input.teamId,
        votingSessionId: input.votingSessionId,
        bracketSlotId: votingSession.bracketSlotId,
        winnerTeamId: calculation.winnerTeamId,
        decisionType: CONSENSUS_DECISION_TYPE.MAJORITY,
        decidedByUserId: null,
        voteSummary: calculation.voteSummary
      }
    });

    return tx.votingSession.update({
      where: {
        id: input.votingSessionId
      },
      data: {
        status: VOTING_SESSION_STATUS.CLOSED,
        closedByUserId: captainUserId,
        closedAt: new Date(),
        tiebreakerPayload: null
      }
    });
  });
}

export async function applyCaptainGroupTiebreaker(
  captainUserId: string,
  input: ApplyGroupTiebreakerInput
) {
  await assertTeamCaptain(input.teamId, captainUserId);

  const votingSession = await getVotingSessionOrThrow(input.votingSessionId, input.teamId);

  if (
    votingSession.type !== VOTING_SESSION_TYPE.GROUP_STAGE ||
    votingSession.status !== VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED ||
    votingSession.group !== input.group
  ) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "A sessão de grupo não está aguardando voto de minerva.",
      statusCode: 422
    });
  }

  assertGroupSelectionIsComplete({
    group: input.group,
    firstPlaceTeamId: input.firstPlaceTeamId,
    secondPlaceTeamId: input.secondPlaceTeamId,
    thirdPlaceTeamId: input.thirdPlaceTeamId,
    fourthPlaceTeamId: input.fourthPlaceTeamId
  });

  return prisma.$transaction(async (tx) => {
    await tx.teamGroupConsensus.upsert({
      where: {
        teamId_votingSessionId_group: {
          teamId: input.teamId,
          votingSessionId: input.votingSessionId,
          group: input.group
        }
      },
      update: {
        firstPlaceTeamId: input.firstPlaceTeamId,
        secondPlaceTeamId: input.secondPlaceTeamId,
        thirdPlaceTeamId: input.thirdPlaceTeamId,
        fourthPlaceTeamId: input.fourthPlaceTeamId,
        decisionType: CONSENSUS_DECISION_TYPE.CAPTAIN_TIEBREAK,
        decidedByUserId: captainUserId
      },
      create: {
        teamId: input.teamId,
        votingSessionId: input.votingSessionId,
        group: input.group,
        firstPlaceTeamId: input.firstPlaceTeamId,
        secondPlaceTeamId: input.secondPlaceTeamId,
        thirdPlaceTeamId: input.thirdPlaceTeamId,
        fourthPlaceTeamId: input.fourthPlaceTeamId,
        decisionType: CONSENSUS_DECISION_TYPE.CAPTAIN_TIEBREAK,
        decidedByUserId: captainUserId,
        voteSummary: votingSession.tiebreakerPayload
      }
    });

    return tx.votingSession.update({
      where: {
        id: input.votingSessionId
      },
      data: {
        status: VOTING_SESSION_STATUS.CLOSED,
        tiebreakerPayload: null
      }
    });
  });
}

export async function applyCaptainKnockoutTiebreaker(
  captainUserId: string,
  input: SubmitKnockoutTiebreakerInputDTO
) {
  await assertTeamCaptain(input.teamId, captainUserId);

  const votingSession = await getVotingSessionOrThrow(input.votingSessionId, input.teamId);

  if (
    votingSession.type !== VOTING_SESSION_TYPE.KNOCKOUT ||
    votingSession.status !== VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED ||
    !votingSession.bracketSlotId
  ) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "A sessão de mata-mata não está aguardando voto de minerva.",
      statusCode: 422
    });
  }

  return prisma.$transaction(async (tx) => {
    await tx.teamKnockoutConsensus.upsert({
      where: {
        teamId_votingSessionId_bracketSlotId: {
          teamId: input.teamId,
          votingSessionId: input.votingSessionId,
          bracketSlotId: votingSession.bracketSlotId
        }
      },
      update: {
        winnerTeamId: input.selectedTeamId,
        decisionType: CONSENSUS_DECISION_TYPE.CAPTAIN_TIEBREAK,
        decidedByUserId: captainUserId
      },
      create: {
        teamId: input.teamId,
        votingSessionId: input.votingSessionId,
        bracketSlotId: votingSession.bracketSlotId,
        winnerTeamId: input.selectedTeamId,
        decisionType: CONSENSUS_DECISION_TYPE.CAPTAIN_TIEBREAK,
        decidedByUserId: captainUserId,
        voteSummary: votingSession.tiebreakerPayload
      }
    });

    return tx.votingSession.update({
      where: {
        id: input.votingSessionId
      },
      data: {
        status: VOTING_SESSION_STATUS.CLOSED,
        tiebreakerPayload: null
      }
    });
  });
}
EOF

cat > services/consensus/index.ts <<'EOF'
export * from "./consensusTypes.ts";
export * from "./consensusCalculator.ts";
export * from "./consensusService.ts";
EOF

cat > tests/consensus.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  calculateGroupConsensus,
  calculateKnockoutConsensus,
  countVotes,
  summarizePositionVotes
} from "../services/consensus/consensusCalculator.ts";

describe("consensus calculator", () => {
  it("deve contar votos por seleção", () => {
    expect(countVotes(["BRA", "ARG", "BRA"])).toEqual({
      BRA: 2,
      ARG: 1
    });
  });

  it("deve detectar líder único", () => {
    expect(summarizePositionVotes(["BRA", "ARG", "BRA"])).toEqual({
      counts: {
        BRA: 2,
        ARG: 1
      },
      leaderTeamId: "BRA",
      tiedTeamIds: []
    });
  });

  it("deve detectar empate no topo", () => {
    expect(summarizePositionVotes(["BRA", "ARG"])).toEqual({
      counts: {
        BRA: 1,
        ARG: 1
      },
      leaderTeamId: null,
      tiedTeamIds: ["BRA", "ARG"]
    });
  });

  it("deve calcular consenso de grupo quando todas as posições têm líder único", () => {
    const result = calculateGroupConsensus("A", [
      {
        userId: "u1",
        firstPlaceTeamId: "BRA",
        secondPlaceTeamId: "ARG",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      },
      {
        userId: "u2",
        firstPlaceTeamId: "BRA",
        secondPlaceTeamId: "ARG",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      },
      {
        userId: "u3",
        firstPlaceTeamId: "ARG",
        secondPlaceTeamId: "BRA",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      }
    ]);

    expect(result.status).toBe("CONSENSUS");

    if (result.status === "CONSENSUS") {
      expect(result.selection).toEqual({
        firstPlaceTeamId: "BRA",
        secondPlaceTeamId: "ARG",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      });
    }
  });

  it("deve exigir voto de minerva quando houver empate no grupo", () => {
    const result = calculateGroupConsensus("A", [
      {
        userId: "u1",
        firstPlaceTeamId: "BRA",
        secondPlaceTeamId: "ARG",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      },
      {
        userId: "u2",
        firstPlaceTeamId: "ARG",
        secondPlaceTeamId: "BRA",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      }
    ]);

    expect(result.status).toBe("TIEBREAKER_REQUIRED");
  });

  it("deve calcular consenso de mata-mata com líder único", () => {
    const result = calculateKnockoutConsensus([
      {
        userId: "u1",
        winnerTeamId: "BRA"
      },
      {
        userId: "u2",
        winnerTeamId: "BRA"
      },
      {
        userId: "u3",
        winnerTeamId: "ARG"
      }
    ]);

    expect(result).toMatchObject({
      status: "CONSENSUS",
      winnerTeamId: "BRA"
    });
  });

  it("deve exigir voto de minerva em empate de mata-mata", () => {
    const result = calculateKnockoutConsensus([
      {
        userId: "u1",
        winnerTeamId: "BRA"
      },
      {
        userId: "u2",
        winnerTeamId: "ARG"
      }
    ]);

    expect(result.status).toBe("TIEBREAKER_REQUIRED");
  });
});
EOF

cat > docs/consensus.md <<'EOF'
# Bloco 6 — Consenso de equipe

## Objetivo

Centralizar a regra de consenso de equipe antes da integração Socket.io.

## Regras

- `CAPTAIN` abre votação.
- `CAPTAIN` fecha votação.
- `CAPTAIN` aplica voto de minerva.
- Membro só vota se estiver aprovado.
- Voto usa `upsert`.
- Socket.io não replica regra de negócio; apenas chama estes services.

## Consenso

- Maioria simples por posição.
- Empate no topo exige `TIEBREAKER_REQUIRED`.
- Seleção inconsistente com equipe duplicada também exige voto de minerva.
EOF

echo ""
echo "==> Conferindo se consensusService.ts existe..."
ls -la services/consensus/consensusService.ts

echo ""
echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run socket:dev"
echo ""
echo "Se passar, commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add socket realtime handlers\""
echo "  git push"
