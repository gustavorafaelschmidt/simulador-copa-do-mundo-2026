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
