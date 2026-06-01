#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção ampla — VisualWorldCupSimulator lint + type-check..."

if [ ! -f "package.json" ] || [ ! -f "components/world-cup/VisualWorldCupSimulator.tsx" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-19-visual-simulator-wide-fix
cp components/world-cup/VisualWorldCupSimulator.tsx .backup/block-19-visual-simulator-wide-fix/VisualWorldCupSimulator.tsx.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
let source = fs.readFileSync(filePath, "utf8");

/**
 * Correção ampla do arquivo inteiro:
 *
 * 1) Lint react-hooks/set-state-in-effect:
 *    O componente chamava setHasMounted(true) diretamente dentro de useEffect.
 *    Isso é bloqueado pelo ESLint atual do React.
 *
 *    Solução:
 *    - Remover hasMounted como state.
 *    - Usar useRef para controlar hidratação sem causar render em cascata.
 *    - Carregar localStorage via queueMicrotask, evitando setState síncrono no corpo do effect.
 *
 * 2) Type-check:
 *    BracketMatchCard não recebe prop bracketPicks, mas o componente pai estava passando.
 *    A prop correta já é pickedTeamId.
 */

// Importa useRef.
source = source.replace(
  'import { useEffect, useMemo, useState } from "react";',
  'import { useEffect, useMemo, useRef, useState } from "react";'
);

// Caso o arquivo já tenha sido parcialmente corrigido.
source = source.replace(
  'import { useEffect, useMemo, useRef, useRef, useState } from "react";',
  'import { useEffect, useMemo, useRef, useState } from "react";'
);

// Remove state de hasMounted.
source = source.replace(
  '  const [hasMounted, setHasMounted] = useState(false);\n',
  ''
);

// Adiciona ref de hidratação após shareFeedback.
if (!source.includes("const hasHydratedRef = useRef(false);")) {
  source = source.replace(
    '  const [shareFeedback, setShareFeedback] = useState<string | null>(null);\n',
    '  const [shareFeedback, setShareFeedback] = useState<string | null>(null);\n  const hasHydratedRef = useRef(false);\n'
  );
}

// Substitui o effect de hidratação inteiro.
const oldHydrationEffect = `  useEffect(() => {
    setHasMounted(true);

    try {
      const rawState = window.localStorage.getItem(storageKey);

      if (!rawState) {
        return;
      }

      const parsedState = JSON.parse(rawState) as Partial<PersistedVisualState>;

      setGroupPicks(parsedState.groupPicks ?? {});
      setBracketPicks(parsedState.bracketPicks ?? {});
    } catch {
      window.localStorage.removeItem(storageKey);
    }
  }, []);`;

const newHydrationEffect = `  useEffect(() => {
    queueMicrotask(() => {
      try {
        const rawState = window.localStorage.getItem(storageKey);

        if (!rawState) {
          hasHydratedRef.current = true;
          return;
        }

        const parsedState = JSON.parse(rawState) as Partial<PersistedVisualState>;

        setGroupPicks(parsedState.groupPicks ?? {});
        setBracketPicks(parsedState.bracketPicks ?? {});
        hasHydratedRef.current = true;
      } catch {
        window.localStorage.removeItem(storageKey);
        hasHydratedRef.current = true;
      }
    });
  }, []);`;

source = source.replace(oldHydrationEffect, newHydrationEffect);

// Caso o effect já esteja alterado parcialmente, aplica correções pontuais.
source = source.replaceAll("setHasMounted(true);", "hasHydratedRef.current = true;");
source = source.replaceAll("if (!hasMounted) {", "if (!hasHydratedRef.current) {");

// Corrige dependências do effect de persistência.
source = source.replaceAll(
  "  }, [bracketPicks, groupPicks, hasMounted, rounds]);",
  "  }, [bracketPicks, groupPicks, rounds]);"
);

// Remove prop inexistente bracketPicks do BracketMatchCard.
source = source.replaceAll(/\n\s+bracketPicks=\{bracketPicks\}/g, "");

// Normaliza duplicações.
source = source.replaceAll("hasHydratedRef.current = true;\n        hasHydratedRef.current = true;", "hasHydratedRef.current = true;");

// Verificações preventivas.
if (source.includes("setHasMounted")) {
  throw new Error("Ainda existe setHasMounted no VisualWorldCupSimulator.tsx.");
}

if (source.includes("[hasMounted")) {
  throw new Error("Ainda existe hasMounted em dependency array.");
}

if (source.includes("bracketPicks={bracketPicks}")) {
  throw new Error("Ainda existe prop bracketPicks sendo passada para BracketMatchCard.");
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
