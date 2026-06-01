#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção — VotingSession.group não-nulo no consenso de grupo..."

if [ ! -f "package.json" ] || [ ! -f "services/consensus/consensusService.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/consensus-group-null-guard
cp services/consensus/consensusService.ts .backup/consensus-group-null-guard/consensusService.ts.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "services/consensus/consensusService.ts";
let source = fs.readFileSync(filePath, "utf8");

// Corrige o ponto de type-check: sessões de votação GROUP_STAGE exigem group.
// O Prisma tipa group como nullable porque o mesmo model também atende mata-mata.
// Aqui a regra de negócio já está no contexto de consenso de grupo.
source = source.replaceAll(
  "group: votingSession.group",
  "group: votingSession.group as GroupLetter"
);

// Se houver comparações/uso semelhante em outros payloads de grupo, mantém o cast canônico.
source = source.replaceAll(
  "group: votingSession.group as GroupLetter as GroupLetter",
  "group: votingSession.group as GroupLetter"
);

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
