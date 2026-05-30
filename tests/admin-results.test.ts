import { describe, expect, it } from "vitest";
import { REAL_RESULT_TYPE } from "../lib/contracts/enums.ts";
import { AppError } from "../lib/errors/AppError.ts";
import {
  buildGroupStandingResultKey,
  buildKnockoutMatchResultKey,
  parseJsonPayload,
  validateRealResultPayload
} from "../services/admin/resultPayloadUtils.ts";
import { toRealTournamentResultDTO } from "../services/admin/resultMapper.ts";

describe("admin results", () => {
  it("deve parsear JSON válido", () => {
    expect(parseJsonPayload('{ "winnerTeamId": "team_1" }')).toEqual({
      winnerTeamId: "team_1"
    });
  });

  it("deve rejeitar JSON inválido", () => {
    expect(() => parseJsonPayload("{")).toThrow(AppError);
  });

  it("deve validar payload de classificação de grupo", () => {
    expect(
      validateRealResultPayload(REAL_RESULT_TYPE.GROUP_STANDING, {
        orderedTeamIds: ["team_1", "team_2", "team_3", "team_4"]
      })
    ).toEqual({
      orderedTeamIds: ["team_1", "team_2", "team_3", "team_4"]
    });
  });

  it("deve validar payload de mata-mata", () => {
    expect(
      validateRealResultPayload(REAL_RESULT_TYPE.KNOCKOUT_MATCH, {
        winnerTeamId: "team_1"
      })
    ).toEqual({
      winnerTeamId: "team_1"
    });
  });

  it("deve gerar chaves canônicas de resultados", () => {
    expect(buildGroupStandingResultKey("A")).toBe("group_standing:A");
    expect(buildKnockoutMatchResultKey("slot_1")).toBe("knockout_match:slot_1");
  });

  it("deve mapear resultado real para DTO", () => {
    expect(
      toRealTournamentResultDTO({
        id: "result_1",
        resultKey: "group_standing:A",
        type: "GROUP_STANDING",
        group: "A",
        knockoutPhase: null,
        officialMatchId: null,
        bracketSlotId: null,
        payload: {
          orderedTeamIds: ["team_1", "team_2", "team_3", "team_4"]
        },
        sourceDocumentRef: "manual",
        officialDataStatus: "OFFICIAL",
        officialDataVersionId: null
      })
    ).toMatchObject({
      id: "result_1",
      resultKey: "group_standing:A",
      officialDataStatus: "OFFICIAL"
    });
  });
});
