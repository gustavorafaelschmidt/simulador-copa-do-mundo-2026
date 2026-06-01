#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção ampla — análise do teamService inteiro para type-check..."

if [ ! -f "package.json" ] || [ ! -f "services/team/teamService.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/team-service-wide-typecheck
cp services/team/teamService.ts .backup/team-service-wide-typecheck/teamService.ts.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "services/team/teamService.ts";
let source = fs.readFileSync(filePath, "utf8");

/**
 * Este patch olha o teamService inteiro.
 *
 * Motivo do erro:
 * O input de alteração de papel já deve limitar role a ADMIN | MEMBER.
 * Por isso o TypeScript acusa que comparar input.role com CAPTAIN é impossível.
 * A regra de negócio correta continua existindo:
 * - membro CAPTAIN não pode ser alterado por esta ação;
 * - input CAPTAIN nem deveria chegar aqui por schema/DTO.
 */

// 1) Remove comparação impossível: input.role === CAPTAIN.
source = source.replaceAll(
  "member.role === TEAM_MEMBER_ROLE.CAPTAIN || input.role === TEAM_MEMBER_ROLE.CAPTAIN",
  "member.role === TEAM_MEMBER_ROLE.CAPTAIN"
);

source = source.replaceAll(
  "input.role === TEAM_MEMBER_ROLE.CAPTAIN || member.role === TEAM_MEMBER_ROLE.CAPTAIN",
  "member.role === TEAM_MEMBER_ROLE.CAPTAIN"
);

source = source.replaceAll(
  " || input.role === TEAM_MEMBER_ROLE.CAPTAIN",
  ""
);

source = source.replaceAll(
  "input.role === TEAM_MEMBER_ROLE.CAPTAIN || ",
  ""
);

// 2) Normaliza possíveis duplicações de patches anteriores.
source = source.replaceAll(
  "member.role === TEAM_MEMBER_ROLE.CAPTAIN || member.role === TEAM_MEMBER_ROLE.CAPTAIN",
  "member.role === TEAM_MEMBER_ROLE.CAPTAIN"
);

// 3) Se existir função de alteração de role com comentário ausente, documenta a regra crítica.
const criticalRule = `  /*
    Regra crítica:
    CAPTAIN representa o criador/dono da equipe e não pode ser atribuído ou removido
    por esta ação comum. Promoções/rebaixamentos aqui são limitados a ADMIN/MEMBER.
  */
`;

if (
  source.includes("O papel CAPTAIN não pode ser alterado por esta ação.") &&
  !source.includes("CAPTAIN representa o criador/dono da equipe")
) {
  source = source.replace(
    "  if (member.role === TEAM_MEMBER_ROLE.CAPTAIN) {",
    `${criticalRule}  if (member.role === TEAM_MEMBER_ROLE.CAPTAIN) {`
  );
}

fs.writeFileSync(filePath, source);
NODE

echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run build"
echo ""
echo "Se passar, pode rodar:"
echo "  npm run dev"
echo "  npm run socket:dev"
