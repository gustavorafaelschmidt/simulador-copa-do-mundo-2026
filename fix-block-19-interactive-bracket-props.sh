#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção ampla — props do InteractiveBracket e proteção contra undefined..."

if [ ! -f "package.json" ] || [ ! -f "components/world-cup/VisualWorldCupSimulator.tsx" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-19-interactive-bracket-props
cp components/world-cup/VisualWorldCupSimulator.tsx .backup/block-19-interactive-bracket-props/VisualWorldCupSimulator.tsx.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
let source = fs.readFileSync(filePath, "utf8");

/**
 * Correção ampla do arquivo:
 *
 * O patch anterior removeu toda ocorrência de bracketPicks={bracketPicks}.
 * Isso era correto dentro de <BracketMatchCard>, porque esse componente não
 * recebe essa prop, mas foi incorreto dentro de <InteractiveBracket>, que precisa
 * receber bracketPicks para marcar vencedores escolhidos.
 *
 * Este patch:
 * 1. Remove bracketPicks apenas de <BracketMatchCard>, se ainda existir.
 * 2. Torna bracketPicks opcional com default {} dentro de InteractiveBracket.
 * 3. Garante que <InteractiveBracket> receba bracketPicks={bracketPicks}.
 */

// 1) Remover prop indevida somente de blocos BracketMatchCard.
source = source.replace(
  /<BracketMatchCard([\s\S]*?)\/>/g,
  (match) => match.replace(/\n\s+bracketPicks=\{bracketPicks\}/g, "")
);

// 2) Tornar bracketPicks defensivo dentro de InteractiveBracket.
source = source.replace(
`function InteractiveBracket({
  rounds,
  bracketPicks,
  champion,
  onPick
}: {`,
`function InteractiveBracket({
  rounds,
  bracketPicks = {},
  champion,
  onPick
}: {`
);

// Evita duplicação se executado mais de uma vez.
source = source.replace(
`function InteractiveBracket({
  rounds,
  bracketPicks = {} = {},
  champion,
  onPick
}: {`,
`function InteractiveBracket({
  rounds,
  bracketPicks = {},
  champion,
  onPick
}: {`
);

source = source.replace(
  "  bracketPicks: VisualBracketPicks;",
  "  bracketPicks?: VisualBracketPicks;"
);

// 3) Garantir que a chamada de InteractiveBracket passe bracketPicks.
source = source.replace(
  /<InteractiveBracket\n(?!\s+bracketPicks=\{bracketPicks\})/,
  "<InteractiveBracket\n        bracketPicks={bracketPicks}\n"
);

// Normaliza possível indentação duplicada em execuções repetidas.
source = source.replace(
  /<InteractiveBracket\n\s+bracketPicks=\{bracketPicks\}\n\s+bracketPicks=\{bracketPicks\}\n/g,
  "<InteractiveBracket\n        bracketPicks={bracketPicks}\n"
);

// Validações preventivas.
const interactiveCallMatch = source.match(/<InteractiveBracket[\s\S]*?\/>/);
if (!interactiveCallMatch || !interactiveCallMatch[0].includes("bracketPicks={bracketPicks}")) {
  throw new Error("A chamada de InteractiveBracket ainda não passa bracketPicks.");
}

const bracketMatchBlocks = source.match(/<BracketMatchCard[\s\S]*?\/>/g) ?? [];
for (const block of bracketMatchBlocks) {
  if (block.includes("bracketPicks={bracketPicks}")) {
    throw new Error("BracketMatchCard ainda recebeu prop bracketPicks indevida.");
  }
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
echo "  git commit -m \"feat: add interactive visual bracket\""
echo "  git push"
