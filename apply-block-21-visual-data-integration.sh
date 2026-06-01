#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 21 — integração visual com dados do banco e fallback demo seguro..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p components/world-cup lib/fifa tests docs .backup/block-21-visual-data-integration

for file in \
  app/page.tsx \
  app/dashboard/previsoes/grupos/page.tsx \
  app/dashboard/previsoes/mata-mata/page.tsx \
  lib/fifa/visualOfficialDataAdapter.ts \
  components/world-cup/VisualDataSourceBanner.tsx \
  tests/visual-official-data-adapter.test.ts
do
  if [ -f "$file" ]; then
    cp "$file" ".backup/block-21-visual-data-integration/$(echo "$file" | tr '/' '__').backup"
  fi
done

cat > lib/fifa/visualOfficialDataAdapter.ts <<'EOF'
import { prisma } from "../db/prisma.ts";
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

    groupsByLetter.set(letter, {
      letter,
      name: row.name?.trim() || `Grupo ${letter}`,
      teams: groupsByLetter.get(letter)?.teams ?? []
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

  return groupLetters.map((letter) => groupsByLetter.get(letter)).filter(Boolean) as VisualDemoGroup[];
}

function shouldUseFallback(groups: VisualDemoGroup[]): boolean {
  if (groups.length !== 12) {
    return true;
  }

  return groups.every((group) => group.teams.length === 0);
}

export async function getVisualGroupsForSimulator(): Promise<VisualSimulatorData> {
  try {
    /*
      Integração tolerante:
      - Em desenvolvimento, tentamos ler os dados versionados do banco.
      - Se a estrutura oficial ainda estiver incompleta, retornamos demo fallback.
      - Produção continuará protegida pelas regras de readiness/dados oficiais.
    */
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

cat > components/world-cup/VisualDataSourceBanner.tsx <<'EOF'
import type { VisualSimulatorDataSource } from "../../lib/fifa/visualOfficialDataAdapter.ts";

type VisualDataSourceBannerProps = {
  source: VisualSimulatorDataSource;
  message: string;
};

export function VisualDataSourceBanner({ source, message }: VisualDataSourceBannerProps) {
  const isDatabase = source === "database";

  return (
    <section
      className={`mb-5 rounded-[24px] border px-4 py-3 text-sm shadow-sm ${
        isDatabase
          ? "border-emerald-200 bg-emerald-50 text-emerald-900"
          : "border-amber-200 bg-amber-50 text-amber-900"
      }`}
    >
      <div className="flex flex-col gap-1 md:flex-row md:items-center md:justify-between">
        <strong className="font-black">
          {isDatabase ? "Dados conectados ao banco" : "Modo demo ativo"}
        </strong>
        <span className="font-medium">{message}</span>
      </div>
    </section>
  );
}
EOF

cat > app/page.tsx <<'EOF'
import { VisualDataSourceBanner } from "../components/world-cup/VisualDataSourceBanner.tsx";
import { VisualSimulatorShell } from "../components/world-cup/VisualSimulatorShell.tsx";
import { VisualWorldCupSimulator } from "../components/world-cup/VisualWorldCupSimulator.tsx";
import { getVisualGroupsForSimulator } from "../lib/fifa/visualOfficialDataAdapter.ts";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const simulatorData = await getVisualGroupsForSimulator();

  return (
    <VisualSimulatorShell activeSection="home">
      <VisualDataSourceBanner message={simulatorData.message} source={simulatorData.source} />
      <VisualWorldCupSimulator groups={simulatorData.groups} />
    </VisualSimulatorShell>
  );
}
EOF

mkdir -p app/dashboard/previsoes/grupos app/dashboard/previsoes/mata-mata

cat > app/dashboard/previsoes/grupos/page.tsx <<'EOF'
import { VisualDataSourceBanner } from "../../../../components/world-cup/VisualDataSourceBanner.tsx";
import { VisualSimulatorShell } from "../../../../components/world-cup/VisualSimulatorShell.tsx";
import { VisualWorldCupSimulator } from "../../../../components/world-cup/VisualWorldCupSimulator.tsx";
import { getVisualGroupsForSimulator } from "../../../../lib/fifa/visualOfficialDataAdapter.ts";

export const dynamic = "force-dynamic";

export default async function GroupPredictionsVisualPage() {
  const simulatorData = await getVisualGroupsForSimulator();

  return (
    <VisualSimulatorShell activeSection="groups">
      <VisualDataSourceBanner message={simulatorData.message} source={simulatorData.source} />
      <VisualWorldCupSimulator groups={simulatorData.groups} />
    </VisualSimulatorShell>
  );
}
EOF

cat > app/dashboard/previsoes/mata-mata/page.tsx <<'EOF'
import { VisualDataSourceBanner } from "../../../../components/world-cup/VisualDataSourceBanner.tsx";
import { VisualSimulatorShell } from "../../../../components/world-cup/VisualSimulatorShell.tsx";
import { VisualWorldCupSimulator } from "../../../../components/world-cup/VisualWorldCupSimulator.tsx";
import { getVisualGroupsForSimulator } from "../../../../lib/fifa/visualOfficialDataAdapter.ts";

export const dynamic = "force-dynamic";

export default async function KnockoutPredictionsVisualPage() {
  const simulatorData = await getVisualGroupsForSimulator();

  return (
    <VisualSimulatorShell activeSection="knockout">
      <VisualDataSourceBanner message={simulatorData.message} source={simulatorData.source} />
      <VisualWorldCupSimulator groups={simulatorData.groups} />
    </VisualSimulatorShell>
  );
}
EOF

cat > tests/visual-official-data-adapter.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { normalizeVisualGroupsFromDatabaseRows } from "../lib/fifa/visualOfficialDataAdapter.ts";

describe("visual official data adapter", () => {
  it("deve normalizar linhas do banco para grupos visuais", () => {
    const groups = normalizeVisualGroupsFromDatabaseRows({
      groupRows: [
        {
          id: "group-a",
          letter: "A",
          name: "Grupo A"
        }
      ],
      teamRows: [
        {
          id: "team-a1",
          name: "Brasil",
          short_name: "BRA",
          fifa_code: "BRA",
          flag_emoji: "🇧🇷",
          group_letter: "A",
          seed: 1
        }
      ]
    });

    expect(groups).toHaveLength(12);
    expect(groups[0]?.letter).toBe("A");
    expect(groups[0]?.teams[0]).toMatchObject({
      id: "team-a1",
      name: "Brasil",
      shortName: "BRA",
      flag: "🇧🇷"
    });
  });

  it("deve ignorar seleções sem grupo válido", () => {
    const groups = normalizeVisualGroupsFromDatabaseRows({
      groupRows: [],
      teamRows: [
        {
          id: "invalid",
          name: "Inválida",
          short_name: "INV",
          fifa_code: "INV",
          flag_emoji: null,
          group_letter: "Z",
          seed: 1
        }
      ]
    });

    expect(groups.every((group) => group.teams.length === 0)).toBe(true);
  });
});
EOF

cat > docs/visual-data-integration.md <<'EOF'
# Bloco 21 — Integração visual com dados do banco

## Entrega

- Adapter visual para carregar grupos/seleções do banco.
- Fallback demo seguro quando os dados oficiais ainda estão incompletos.
- Banner informando se a tela usa banco ou demo.
- Rotas visuais marcadas como dinâmicas para evitar snapshot estático de dados incompletos.

## Observação

O adapter usa leitura tolerante para desenvolvimento. Regras oficiais continuam dependentes do pipeline de dados oficiais e readiness.
EOF

echo "==> Bloco 21 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run build"
echo "  npm run dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: connect visual simulator to database fallback\""
echo "  git push"
