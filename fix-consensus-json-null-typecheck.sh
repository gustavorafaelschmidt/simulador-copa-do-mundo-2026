#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção — removendo null inválido em JSON do Prisma no consensusService..."

if [ ! -f "package.json" ] || [ ! -f "services/consensus/consensusService.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/consensus-json-null-typecheck
cp services/consensus/consensusService.ts .backup/consensus-json-null-typecheck/consensusService.ts.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "services/consensus/consensusService.ts";
let source = fs.readFileSync(filePath, "utf8");

/*
  Prisma 7 tipa campos Json nullable com sentinelas próprias.
  Neste fluxo, quando a votação é fechada sem voto de minerva, não precisamos
  escrever null explicitamente; basta omitir o campo no update.
*/
source = source.replaceAll(/,\n\s*tiebreakerPayload: null/g, "");
source = source.replaceAll(/\n\s*tiebreakerPayload: null,?/g, "");

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
