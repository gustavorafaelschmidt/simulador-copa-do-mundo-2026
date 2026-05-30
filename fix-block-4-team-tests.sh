#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 4 — helpers puros de equipe sem Prisma nos testes..."

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

python - <<'PY'
from pathlib import Path

path = Path("services/team/teamService.ts")
text = path.read_text()

text = text.replace('import { randomBytes } from "node:crypto";\n', "")

needle = 'import { AppError } from "@/lib/errors/AppError";'
replacement = 'import { AppError } from "@/lib/errors/AppError";\nimport { buildTeamSlug, createInviteCode } from "@/services/team/teamUtils";'

if 'from "@/services/team/teamUtils"' not in text:
    text = text.replace(needle, replacement)

old = '''export function buildTeamSlug(name: string): string {
  const slug = name
    .normalize("NFD")
    .replace(/[\\u0300-\\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return slug || "equipe";
}

export function createInviteCode(): string {
  return randomBytes(8).toString("base64url").replace(/[^a-zA-Z0-9]/g, "").slice(0, 10).toUpperCase();
}

'''

if old in text:
    text = text.replace(old, "")
else:
    print("Aviso: bloco antigo de helpers não encontrado em teamService.ts. Pode já estar corrigido.")

path.write_text(text)
PY

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
