#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 4 — versão sem dependência de python..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/team tests

cat > services/team/teamUtils.ts <<'EOF'
import { randomBytes } from "node:crypto";

export function buildTeamSlug(name: string): string {
  const slug = name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return slug || "equipe";
}

export function createInviteCode(): string {
  return randomBytes(8)
    .toString("base64url")
    .replace(/[^a-zA-Z0-9]/g, "")
    .slice(0, 10)
    .toUpperCase();
}
EOF

node <<'NODE'
const fs = require("node:fs");

const path = "services/team/teamService.ts";
let text = fs.readFileSync(path, "utf8");

text = text.replace('import { randomBytes } from "node:crypto";\n', "");

const helperImport = 'import { buildTeamSlug, createInviteCode } from "@/services/team/teamUtils";';
const appErrorImport = 'import { AppError } from "@/lib/errors/AppError";';

if (!text.includes(helperImport)) {
  text = text.replace(appErrorImport, `${appErrorImport}\n${helperImport}`);
}

text = text.replace(
  /export function buildTeamSlug\(name: string\): string \{[\s\S]*?\n\}\n\nexport function createInviteCode\(\): string \{[\s\S]*?\n\}\n\nasync function generateUniqueTeamSlug/,
  "async function generateUniqueTeamSlug"
);

fs.writeFileSync(path, text);
NODE

cat > tests/team.test.ts <<'EOF'
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
EOF

echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo ""
echo "Se passar, commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add team management foundation\""
echo "  git push"
