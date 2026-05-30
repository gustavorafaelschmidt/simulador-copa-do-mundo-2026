import { describe, expect, it } from "vitest";
import { VOTING_SESSION_STATUS, VOTING_SESSION_TYPE } from "@/lib/contracts/enums";
import { ackError, ackSuccess } from "@/lib/socket/socketAck";
import { getTeamRoomName, getVotingSessionRoomName } from "@/lib/socket/rooms";
import { toVotingSessionDTO } from "@/lib/socket/votingSessionMapper";
import { joinTeamSocketSchema } from "@/lib/validations/socket";
import { submitAnyTiebreakerSchema } from "@/lib/validations/voting";

describe("socket foundation", () => {
  it("deve gerar nomes de rooms canônicos", () => {
    expect(getTeamRoomName("team_1")).toBe("team:team_1");
    expect(getVotingSessionRoomName("vote_1")).toBe("voting_session:vote_1");
  });

  it("deve validar payload de join team", () => {
    expect(
      joinTeamSocketSchema.safeParse({
        teamId: "team_1"
      }).success
    ).toBe(true);
  });

  it("deve validar voto de minerva de grupo", () => {
    expect(
      submitAnyTiebreakerSchema.safeParse({
        teamId: "team_1",
        votingSessionId: "session_1",
        group: "A",
        firstPlaceTeamId: "BRA",
        secondPlaceTeamId: "ARG",
        thirdPlaceTeamId: "URU",
        fourthPlaceTeamId: "CHI"
      }).success
    ).toBe(true);
  });

  it("deve validar voto de minerva de mata-mata", () => {
    expect(
      submitAnyTiebreakerSchema.safeParse({
        teamId: "team_1",
        votingSessionId: "session_1",
        selectedTeamId: "BRA"
      }).success
    ).toBe(true);
  });

  it("deve montar ack de sucesso", () => {
    expect(ackSuccess({ ok: true })).toEqual({
      ok: true,
      data: {
        ok: true
      }
    });
  });

  it("deve montar ack de erro", () => {
    expect(ackError(new Error("Falha"))).toMatchObject({
      ok: false,
      error: {
        code: "INTERNAL_SERVER_ERROR",
        message: "Falha",
        statusCode: 500
      }
    });
  });

  it("deve serializar sessão de votação para DTO", () => {
    const now = new Date("2026-01-01T00:00:00.000Z");

    expect(
      toVotingSessionDTO({
        id: "session_1",
        teamId: "team_1",
        type: VOTING_SESSION_TYPE.GROUP_STAGE,
        status: VOTING_SESSION_STATUS.OPEN,
        group: "A",
        bracketSlotId: null,
        openedByUserId: "user_1",
        closedByUserId: null,
        openedAt: now,
        closedAt: null,
        tiebreakerPayload: null,
        createdAt: now,
        updatedAt: now
      })
    ).toEqual({
      id: "session_1",
      teamId: "team_1",
      type: "GROUP_STAGE",
      status: "OPEN",
      group: "A",
      bracketSlotId: null,
      openedByUserId: "user_1",
      closedByUserId: null,
      openedAt: "2026-01-01T00:00:00.000Z",
      closedAt: null,
      tiebreakerPayload: null,
      createdAt: "2026-01-01T00:00:00.000Z",
      updatedAt: "2026-01-01T00:00:00.000Z"
    });
  });
});
