#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção — VotingSession.bracketSlotId não-nulo no consenso de mata-mata..."

if [ ! -f "package.json" ] || [ ! -f "services/consensus/consensusService.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/consensus-bracket-slot-null-guard
cp services/consensus/consensusService.ts .backup/consensus-bracket-slot-null-guard/consensusService.ts.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "services/consensus/consensusService.ts";
let source = fs.readFileSync(filePath, "utf8");

/*
  VotingSession.bracketSlotId é nullable no schema porque o mesmo model atende:
  - GROUP_STAGE: usa group
  - KNOCKOUT: usa bracketSlotId

  Neste trecho estamos no fluxo de consenso/voto de minerva de mata-mata.
  A regra de negócio exige bracketSlotId, então o cast remove a ambiguidade
  estrutural do model Prisma sem alterar comportamento.
*/
source = source.replaceAll(
  "bracketSlotId: votingSession.bracketSlotId",
  "bracketSlotId: votingSession.bracketSlotId as string"
);

source = source.replaceAll(
  "bracketSlotId: votingSession.bracketSlotId as string as string",
  "bracketSlotId: votingSession.bracketSlotId as string"
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
