#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 7 — imports relativos no servidor Socket.io..."

if [ ! -f "package.json" ] || [ ! -f "server/socket.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

cp server/socket.ts server/socket.ts.backup-before-relative-imports

node <<'NODE'
const fs = require("node:fs");

const socketPath = "server/socket.ts";
let socketSource = fs.readFileSync(socketPath, "utf8");

// O server/socket.ts roda fora do runtime do Next.js. Para evitar conflito de
// resolução de aliases ESM no tsx, os imports do servidor standalone ficam relativos.
socketSource = socketSource.replaceAll('from "@/lib/', 'from "../lib/');
socketSource = socketSource.replaceAll('from "@/services/', 'from "../services/');
socketSource = socketSource.replaceAll('from "@/actions/', 'from "../actions/');
socketSource = socketSource.replaceAll('from "@/types/', 'from "../types/');
socketSource = socketSource.replaceAll('from "@/contracts/', 'from "../lib/contracts/');
socketSource = socketSource.replaceAll('from "@/auth"', 'from "../auth"');

fs.writeFileSync(socketPath, socketSource);

const packageJsonPath = "package.json";
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));

packageJson.scripts = packageJson.scripts ?? {};
packageJson.scripts["socket:dev"] = "tsx watch server/socket.ts";

fs.writeFileSync(packageJsonPath, `${JSON.stringify(packageJson, null, 2)}\n`);
NODE

echo ""
echo "==> Conferindo aliases restantes dentro de server/..."
if grep -R "@/services\|@/lib\|@/actions\|@/types\|@/contracts" server --include="*.ts"; then
  echo ""
  echo "ERRO: ainda existem aliases @/ dentro de server/. Corrija antes de rodar socket:dev."
  exit 1
else
  echo "OK: nenhum alias @/ restante em server/."
fi

echo ""
echo "==> Removendo backups temporários para evitar commit acidental..."
rm -f tsconfig.json.backup-before-block-7-alias-fix
rm -f fix-block-7-tsx-aliases.sh
rm -f fix-block-7-tsconfig-v2.sh
rm -f fix-block-7-tsconfig-paths-register.sh

echo ""
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
