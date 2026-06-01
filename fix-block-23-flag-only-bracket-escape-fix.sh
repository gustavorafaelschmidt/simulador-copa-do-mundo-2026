#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção — removendo escapes inválidos do TSX no mata-mata..."

if [ ! -f "package.json" ] || [ ! -f "components/world-cup/VisualWorldCupSimulator.tsx" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-23-flag-only-bracket-escape-fix
cp components/world-cup/VisualWorldCupSimulator.tsx .backup/block-23-flag-only-bracket-escape-fix/VisualWorldCupSimulator.tsx.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
let source = fs.readFileSync(filePath, "utf8");

/*
  O script anterior escreveu trechos TSX com escapes literais:
    \`
    \${...}

  Isso é inválido dentro do arquivo .tsx final. Aqui removemos esses escapes
  do componente inteiro, porque o erro pode aparecer em várias linhas da mesma
  estrutura de template string.
*/
source = source.replace(/\\`/g, "`");
source = source.replace(/\\\$\{/g, "${");

if (source.includes("\\`")) {
  throw new Error("Ainda existe escape inválido de crase: \\`");
}

if (source.includes("\\${")) {
  throw new Error("Ainda existe escape inválido de interpolação: \\${");
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
echo "  npm run dev"
echo ""
echo "Se passar:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"style: simplify knockout bracket with flag-only buttons\""
echo "  git push"
