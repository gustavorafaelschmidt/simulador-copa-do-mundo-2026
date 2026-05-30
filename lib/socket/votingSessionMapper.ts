import type { VotingSessionDTO } from "../contracts/voting.ts";

type VotingSessionLike = {
  id: string;
  teamId: string;
  type: VotingSessionDTO["type"];
  status: VotingSessionDTO["status"];
  group: VotingSessionDTO["group"];
  bracketSlotId: string | null;
  openedByUserId: string | null;
  closedByUserId: string | null;
  openedAt: Date | null;
  closedAt: Date | null;
  tiebreakerPayload: unknown | null;
  createdAt: Date;
  updatedAt: Date;
};

export function toVotingSessionDTO(votingSession: VotingSessionLike): VotingSessionDTO {
  return {
    id: votingSession.id,
    teamId: votingSession.teamId,
    type: votingSession.type,
    status: votingSession.status,
    group: votingSession.group,
    bracketSlotId: votingSession.bracketSlotId,
    openedByUserId: votingSession.openedByUserId,
    closedByUserId: votingSession.closedByUserId,
    openedAt: votingSession.openedAt?.toISOString() ?? null,
    closedAt: votingSession.closedAt?.toISOString() ?? null,
    tiebreakerPayload: votingSession.tiebreakerPayload,
    createdAt: votingSession.createdAt.toISOString(),
    updatedAt: votingSession.updatedAt.toISOString()
  };
}
