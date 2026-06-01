#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção — removendo prop side não utilizada no BracketMatchCard..."

if [ ! -f "package.json" ] || [ ! -f "components/world-cup/VisualWorldCupSimulator.tsx" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-23-unused-side-fix
cp components/world-cup/VisualWorldCupSimulator.tsx .backup/block-23-unused-side-fix/VisualWorldCupSimulator.tsx.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
let source = fs.readFileSync(filePath, "utf8");

/*
  O lint está correto: depois que o mata-mata virou flag-only,
  BracketMatchCard não usa mais a prop side.
  Mantemos side em RoundColumn, porque ela ainda controla alinhamento da coluna.
*/

// Remove side da desestruturação da função BracketMatchCard.
source = source.replace(
`function BracketMatchCard({
  match,
  side,
  pickedTeamId,
  onPick
}: {`,
`function BracketMatchCard({
  match,
  pickedTeamId,
  onPick
}: {`
);

// Remove side do tipo das props de BracketMatchCard.
source = source.replace(
`  match: VisualBracketMatch;
  side: "left" | "right";
  pickedTeamId?: string;`,
`  match: VisualBracketMatch;
  pickedTeamId?: string;`
);

// Remove side={side} apenas das chamadas de BracketMatchCard.
source = source.replace(
  /(\n\s+side=\{side\})(\n\s+\/>)/g,
  "$2"
);

// Normaliza caso o patch rode mais de uma vez.
source = source.replace(
`function BracketMatchCard({
  match,
  pickedTeamId,
  onPick
}: {
  match: VisualBracketMatch;
  pickedTeamId?: string;
  onPick: (matchId: string, teamId: string) => void;
})`,
`function BracketMatchCard({
  match,
  pickedTeamId,
  onPick
}: {
  match: VisualBracketMatch;
  pickedTeamId?: string;
  onPick: (matchId: string, teamId: string) => void;
})`
);

// Validação simples: BracketMatchCard não deve declarar side.
const bracketMatchStart = source.indexOf("function BracketMatchCard");
const roundColumnStart = source.indexOf("function RoundColumn");

if (bracketMatchStart === -1 || roundColumnStart === -1) {
  throw new Error("Não foi possível localizar BracketMatchCard/RoundColumn.");
}

const bracketMatchBlock = source.slice(bracketMatchStart, roundColumnStart);

if (bracketMatchBlock.includes("side")) {
  throw new Error("Ainda existe referência a side dentro de BracketMatchCard.");
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
