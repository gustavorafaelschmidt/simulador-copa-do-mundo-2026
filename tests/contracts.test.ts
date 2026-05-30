import { describe, expect, it } from "vitest";
import { GLOBAL_ROLE, TEAM_MEMBER_ROLE, VOTING_SESSION_STATUS } from "@/lib/contracts/enums";
import { SOCKET_EVENTS } from "@/lib/contracts/socketEvents";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { createTeamSchema } from "@/lib/validations/team";
import { saveIndividualGroupPredictionSchema } from "@/lib/validations/prediction";
import { submitGroupVoteSchema } from "@/lib/validations/voting";

describe("contracts", () => {
  it("deve manter enums canônicos estáveis", () => {
    expect(GLOBAL_ROLE.ADMIN_GLOBAL).toBe("ADMIN_GLOBAL");
    expect(TEAM_MEMBER_ROLE.CAPTAIN).toBe("CAPTAIN");
    expect(VOTING_SESSION_STATUS.TIEBREAKER_REQUIRED).toBe("TIEBREAKER_REQUIRED");
  });

  it("deve manter eventos Socket.io em snake_case", () => {
    expect(SOCKET_EVENTS.SUBMIT_GROUP_VOTE).toBe("submit_group_vote");
    expect(SOCKET_EVENTS.SUBMIT_TIEBREAKER).toBe("submit_tiebreaker");
    expect(SOCKET_EVENTS.CONSENSUS_DEFINED).toBe("consensus_defined");
  });

  it("deve manter rotas principais canônicas", () => {
    expect(APP_ROUTES.DASHBOARD).toBe("/dashboard");
    expect(APP_ROUTES.RANKING_INDIVIDUAL).toBe("/ranking/individual");
    expect(APP_ROUTES.ADMIN_RESULTS).toBe("/admin/resultados");
  });

  it("deve validar criação básica de equipe", () => {
    const result = createTeamSchema.safeParse({
      name: "Minha Equipe",
      slug: "minha-equipe",
      maxMembers: 20
    });

    expect(result.success).toBe(true);
  });

  it("deve rejeitar previsão de grupo com seleções duplicadas", () => {
    const result = saveIndividualGroupPredictionSchema.safeParse({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_1",
      thirdPlaceTeamId: "team_3",
      fourthPlaceTeamId: "team_4"
    });

    expect(result.success).toBe(false);
  });

  it("deve validar payload de voto de grupo", () => {
    const result = submitGroupVoteSchema.safeParse({
      teamId: "team_1",
      votingSessionId: "session_1",
      group: "B",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_2",
      thirdPlaceTeamId: "team_3",
      fourthPlaceTeamId: "team_4"
    });

    expect(result.success).toBe(true);
  });
});
