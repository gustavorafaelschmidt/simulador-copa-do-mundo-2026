import { describe, expect, it } from "vitest";
import { TEAM_MEMBER_ROLE } from "@/lib/contracts/enums";
import { changeTeamMemberRoleSchema, createTeamSchema } from "@/lib/validations/team";
import { buildTeamSlug, createInviteCode } from "@/services/team/teamUtils";

describe("team module", () => {
  it("deve gerar slug seguro para equipe", () => {
    expect(buildTeamSlug("Minha Equipe do Bolão!")).toBe("minha-equipe-do-bolao");
  });

  it("deve gerar código de convite em caixa alta", () => {
    const code = createInviteCode();

    expect(code).toMatch(/^[A-Z0-9]+$/);
    expect(code.length).toBeGreaterThanOrEqual(6);
  });

  it("deve validar criação de equipe", () => {
    const result = createTeamSchema.safeParse({
      name: "Equipe Campeã",
      slug: "equipe-campea",
      description: "Equipe privada do bolão.",
      maxMembers: 20
    });

    expect(result.success).toBe(true);
  });

  it("não deve permitir atribuir CAPTAIN por alteração de papel", () => {
    const result = changeTeamMemberRoleSchema.safeParse({
      teamId: "team_1",
      memberId: "member_1",
      role: TEAM_MEMBER_ROLE.CAPTAIN
    });

    expect(result.success).toBe(false);
  });
});
