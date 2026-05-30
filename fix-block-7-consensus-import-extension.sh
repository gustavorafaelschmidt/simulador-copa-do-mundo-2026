#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção pontual do Bloco 7 — extensão .ts no import do consensusService..."

if [ ! -f "package.json" ] || [ ! -f "server/socket.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

node <<'NODE'
const fs = require("node:fs");

const socketPath = "server/socket.ts";
let source = fs.readFileSync(socketPath, "utf8");

source = source.replaceAll(
  'from "../services/consensus/consensusService";',
  'from "../services/consensus/consensusService.ts";'
);

source = source.replaceAll(
  "from '../services/consensus/consensusService';",
  "from '../services/consensus/consensusService.ts';"
);

fs.writeFileSync(socketPath, source);
NODE

echo ""
echo "==> Conferindo se ainda existe import extensionless do consensusService..."
if grep -R 'from "../services/consensus/consensusService";\|from '\''../services/consensus/consensusService'\'';' server/socket.ts; then
  echo "ERRO: import ainda está sem extensão."
  exit 1
fi

echo "OK: import do consensusService corrigido."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run socket:dev"
echo ""
echo "Se passar, commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add socket realtime handlers\""
echo "  git push"
