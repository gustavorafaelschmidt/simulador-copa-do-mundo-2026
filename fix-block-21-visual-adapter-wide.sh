#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção ampla — visualOfficialDataAdapter sem Prisma no topo do módulo..."

if [ ! -f "package.json" ] || [ ! -f "lib/fifa/visualOfficialDataAdapter.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-21-visual-adapter-wide-fix
cp lib/fifa/visualOfficialDataAdapter.ts .backup/block-21-visual-adapter-wide-fix/visualOfficialDataAdapter.ts.backup

cat > lib/fifa/visualOfficialDataAdapter.ts <<'EOF'
import {
  visualDemoGroups,
  type VisualDemoGroup,
  type VisualDemoTeam
} from "./visualDemoData.ts";

export type VisualSimulatorDataSource = "database" | "demo_fallback";

export type VisualSimulatorData = {
  groups: VisualDemoGroup[];
  source: VisualSimulatorDataSource;
  message: string;
};

export type VisualGroupRow = {
  id: string;
  letter: string | null;
  name: string | null;
};

export type VisualTeamRow = {
  id: string;
  name: string | null;
  short_name: string | null;
  fifa_code: string | null;
  flag_emoji: string | null;
  group_letter: string | null;
  seed: number | null;
};

const groupLetters = Array.from({ length: 12 }, (_, index) => String.fromCharCode(65 + index));

function isKnownGroupLetter(value: string | null | undefined): value is string {
  return Boolean(value && groupLetters.includes(value));
}

function normalizeShortName(name: string, fallback?: string | null): string {
  const normalizedFallback = fallback?.trim();

  if (normalizedFallback) {
    return normalizedFallback.slice(0, 3).toUpperCase();
  }

  return name.slice(0, 3).toUpperCase();
}

function normalizeFlagEmoji(value?: string | null): string {
  const normalized = value?.trim();

  return normalized || "🏳️";
}

function makeDemoLikeTeam(row: VisualTeamRow, index: number): VisualDemoTeam | null {
  const groupLetter = row.group_letter?.trim().toUpperCase();

  if (!isKnownGroupLetter(groupLetter)) {
    return null;
  }

  const name = row.name?.trim();

  if (!name) {
    return null;
  }

  return {
    id: row.id,
    name,
    shortName: normalizeShortName(name, row.short_name ?? row.fifa_code),
    flag: normalizeFlagEmoji(row.flag_emoji),
    seed: row.seed ?? index + 1
  };
}

export function normalizeVisualGroupsFromDatabaseRows({
  groupRows,
  teamRows
}: {
  groupRows: VisualGroupRow[];
  teamRows: VisualTeamRow[];
}): VisualDemoGroup[] {
  const groupsByLetter = new Map<string, VisualDemoGroup>();

  for (const letter of groupLetters) {
    groupsByLetter.set(letter, {
      letter,
      name: `Grupo ${letter}`,
      teams: []
    });
  }

  for (const row of groupRows) {
    const letter = row.letter?.trim().toUpperCase();

    if (!isKnownGroupLetter(letter)) {
      continue;
    }

    const currentGroup = groupsByLetter.get(letter);

    groupsByLetter.set(letter, {
      letter,
      name: row.name?.trim() || `Grupo ${letter}`,
      teams: currentGroup?.teams ?? []
    });
  }

  const teamRowsByGroup = new Map<string, VisualTeamRow[]>();

  for (const row of teamRows) {
    const letter = row.group_letter?.trim().toUpperCase();

    if (!isKnownGroupLetter(letter)) {
      continue;
    }

    teamRowsByGroup.set(letter, [...(teamRowsByGroup.get(letter) ?? []), row]);
  }

  for (const letter of groupLetters) {
    const rows = teamRowsByGroup.get(letter) ?? [];
    const group = groupsByLetter.get(letter);

    if (!group) {
      continue;
    }

    group.teams = rows
      .sort((a, b) => (a.seed ?? 999) - (b.seed ?? 999))
      .map((row, index) => makeDemoLikeTeam(row, index))
      .filter((team): team is VisualDemoTeam => Boolean(team));
  }

  return groupLetters
    .map((letter) => groupsByLetter.get(letter))
    .filter((group): group is VisualDemoGroup => Boolean(group));
}

function shouldUseFallback(groups: VisualDemoGroup[]): boolean {
  if (groups.length !== 12) {
    return true;
  }

  return groups.every((group) => group.teams.length === 0);
}

async function loadVisualRowsFromDatabase(): Promise<{
  groupRows: VisualGroupRow[];
  teamRows: VisualTeamRow[];
}> {
  /*
    Import dinâmico intencional:
    este módulo também exporta funções puras usadas em testes unitários.
    Importar Prisma no topo do arquivo força DATABASE_URL durante testes puros.
    Mantemos Prisma restrito ao fluxo server-side que realmente acessa o banco.
  */
  const { prisma } = await import("../db/prisma.ts");

  const groupRows = await prisma.$queryRaw<VisualGroupRow[]>`
    SELECT
      id::text,
      letter::text,
      name::text
    FROM tournament_groups
    ORDER BY letter ASC
  `;

  const teamRows = await prisma.$queryRaw<VisualTeamRow[]>`
    SELECT
      id::text,
      name::text,
      COALESCE(short_name, fifa_code)::text AS short_name,
      fifa_code::text,
      flag_emoji::text,
      group_letter::text,
      seed::int
    FROM national_teams
    ORDER BY group_letter ASC, seed ASC, name ASC
  `;

  return {
    groupRows,
    teamRows
  };
}

export async function getVisualGroupsForSimulator(): Promise<VisualSimulatorData> {
  try {
    /*
      Integração tolerante:
      - Em desenvolvimento, tentamos ler os dados versionados do banco.
      - Se a estrutura oficial ainda estiver incompleta, retornamos demo fallback.
      - Produção continuará protegida pelas regras de readiness/dados oficiais.
    */
    const { groupRows, teamRows } = await loadVisualRowsFromDatabase();

    const groups = normalizeVisualGroupsFromDatabaseRows({
      groupRows,
      teamRows
    });

    if (shouldUseFallback(groups)) {
      return {
        groups: visualDemoGroups,
        source: "demo_fallback",
        message:
          "Dados oficiais ainda incompletos. Exibindo modo demo seguro para desenvolvimento."
      };
    }

    return {
      groups,
      source: "database",
      message: "Dados carregados do banco local."
    };
  } catch {
    return {
      groups: visualDemoGroups,
      source: "demo_fallback",
      message:
        "Não foi possível carregar grupos do banco. Exibindo modo demo seguro para desenvolvimento."
    };
  }
}
EOF

echo "==> Conferindo imports diretos de Prisma em arquivos visuais puros..."
if grep -R 'import { prisma }' lib/fifa/visualOfficialDataAdapter.ts tests/visual-official-data-adapter.test.ts >/dev/null 2>&1; then
  echo "ERRO: ainda existe import direto de Prisma em adapter/teste visual."
  exit 1
fi

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
echo "  git commit -m \"feat: connect visual simulator to database fallback\""
echo "  git push"
