#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 7 — carregamento de .env no servidor Socket.io..."

if [ ! -f "package.json" ] || [ ! -f "server/socket.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-7-env-loader
cp server/socket.ts .backup/block-7-env-loader/socket.ts.backup

node <<'NODE'
const fs = require("node:fs");

const socketPath = "server/socket.ts";
let source = fs.readFileSync(socketPath, "utf8");

source = source.replace('import { loadEnvConfig } from "@next/env";\n', 'import "dotenv/config";\n');
source = source.replace(/\nloadEnvConfig\(process\.cwd\(\)\);\n/, "\n");

fs.writeFileSync(socketPath, source);
NODE

echo "==> Correção aplicada."
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
