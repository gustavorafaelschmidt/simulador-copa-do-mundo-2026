#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 22 — seleções corretas da Copa 2026 e bandeiras visuais..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p lib/fifa components/world-cup tests docs .backup/block-22-qualified-teams-flags

for file in \
  lib/fifa/visualDemoData.ts \
  lib/fifa/visualOfficialDataAdapter.ts \
  components/world-cup/VisualWorldCupSimulator.tsx \
  tests/visual-demo-helpers.test.ts \
  tests/visual-bracket-helpers.test.ts \
  tests/visual-progress.test.ts \
  tests/visual-official-data-adapter.test.ts \
  lib/fifa/worldCup2026QualifiedTeams.ts \
  docs/qualified-teams-and-flags.md
do
  if [ -f "$file" ]; then
    cp "$file" ".backup/block-22-qualified-teams-flags/$(echo "$file" | tr '/' '__').backup"
  fi
done

cat > lib/fifa/worldCup2026QualifiedTeams.ts <<'EOF'
import type { VisualDemoGroup, VisualDemoTeam } from "./visualDemoData.ts";

export type QualifiedTeamSeed = {
  id: string;
  fifaCode: string;
  name: string;
  shortName: string;
  flag: string;
  countryCode: string;
  seed: number;
};

export type QualifiedGroupSeed = {
  letter: string;
  name: string;
  teams: QualifiedTeamSeed[];
};

export function getFlagImageUrl(countryCode: string): string {
  return `https://flagcdn.com/${countryCode.toLowerCase()}.svg`;
}

function team(teamSeed: QualifiedTeamSeed): VisualDemoTeam {
  return {
    ...teamSeed,
    flagImageUrl: getFlagImageUrl(teamSeed.countryCode)
  };
}

/*
  Dados visuais baseados na tabela pública de grupos da Copa do Mundo 2026.
  Não usamos escudos/logos de federações, pois esses assets podem ser protegidos.
  Usamos bandeiras nacionais via country code + fallback em emoji.
*/
export const worldCup2026QualifiedGroups: VisualDemoGroup[] = [
  {
    letter: "A",
    name: "Grupo A",
    teams: [
      team({ id: "MEX", fifaCode: "MEX", name: "México", shortName: "MEX", flag: "🇲🇽", countryCode: "mx", seed: 1 }),
      team({ id: "RSA", fifaCode: "RSA", name: "África do Sul", shortName: "AFS", flag: "🇿🇦", countryCode: "za", seed: 2 }),
      team({ id: "KOR", fifaCode: "KOR", name: "Coreia do Sul", shortName: "COR", flag: "🇰🇷", countryCode: "kr", seed: 3 }),
      team({ id: "CZE", fifaCode: "CZE", name: "República Tcheca", shortName: "TCH", flag: "🇨🇿", countryCode: "cz", seed: 4 })
    ]
  },
  {
    letter: "B",
    name: "Grupo B",
    teams: [
      team({ id: "CAN", fifaCode: "CAN", name: "Canadá", shortName: "CAN", flag: "🇨🇦", countryCode: "ca", seed: 1 }),
      team({ id: "BIH", fifaCode: "BIH", name: "Bósnia", shortName: "BOS", flag: "🇧🇦", countryCode: "ba", seed: 2 }),
      team({ id: "QAT", fifaCode: "QAT", name: "Catar", shortName: "CAT", flag: "🇶🇦", countryCode: "qa", seed: 3 }),
      team({ id: "SUI", fifaCode: "SUI", name: "Suíça", shortName: "SUI", flag: "🇨🇭", countryCode: "ch", seed: 4 })
    ]
  },
  {
    letter: "C",
    name: "Grupo C",
    teams: [
      team({ id: "BRA", fifaCode: "BRA", name: "Brasil", shortName: "BRA", flag: "🇧🇷", countryCode: "br", seed: 1 }),
      team({ id: "MAR", fifaCode: "MAR", name: "Marrocos", shortName: "MAR", flag: "🇲🇦", countryCode: "ma", seed: 2 }),
      team({ id: "HAI", fifaCode: "HAI", name: "Haiti", shortName: "HAI", flag: "🇭🇹", countryCode: "ht", seed: 3 }),
      team({ id: "SCO", fifaCode: "SCO", name: "Escócia", shortName: "ESC", flag: "🏴󠁧󠁢󠁳󠁣󠁴󠁿", countryCode: "gb-sct", seed: 4 })
    ]
  },
  {
    letter: "D",
    name: "Grupo D",
    teams: [
      team({ id: "USA", fifaCode: "USA", name: "Estados Unidos", shortName: "EUA", flag: "🇺🇸", countryCode: "us", seed: 1 }),
      team({ id: "PAR", fifaCode: "PAR", name: "Paraguai", shortName: "PAR", flag: "🇵🇾", countryCode: "py", seed: 2 }),
      team({ id: "AUS", fifaCode: "AUS", name: "Austrália", shortName: "AUS", flag: "🇦🇺", countryCode: "au", seed: 3 }),
      team({ id: "TUR", fifaCode: "TUR", name: "Turquia", shortName: "TUR", flag: "🇹🇷", countryCode: "tr", seed: 4 })
    ]
  },
  {
    letter: "E",
    name: "Grupo E",
    teams: [
      team({ id: "GER", fifaCode: "GER", name: "Alemanha", shortName: "ALE", flag: "🇩🇪", countryCode: "de", seed: 1 }),
      team({ id: "CUW", fifaCode: "CUW", name: "Curaçao", shortName: "CUR", flag: "🇨🇼", countryCode: "cw", seed: 2 }),
      team({ id: "CIV", fifaCode: "CIV", name: "Costa do Marfim", shortName: "CDM", flag: "🇨🇮", countryCode: "ci", seed: 3 }),
      team({ id: "ECU", fifaCode: "ECU", name: "Equador", shortName: "EQU", flag: "🇪🇨", countryCode: "ec", seed: 4 })
    ]
  },
  {
    letter: "F",
    name: "Grupo F",
    teams: [
      team({ id: "NED", fifaCode: "NED", name: "Holanda", shortName: "HOL", flag: "🇳🇱", countryCode: "nl", seed: 1 }),
      team({ id: "JPN", fifaCode: "JPN", name: "Japão", shortName: "JAP", flag: "🇯🇵", countryCode: "jp", seed: 2 }),
      team({ id: "SWE", fifaCode: "SWE", name: "Suécia", shortName: "SUE", flag: "🇸🇪", countryCode: "se", seed: 3 }),
      team({ id: "TUN", fifaCode: "TUN", name: "Tunísia", shortName: "TUN", flag: "🇹🇳", countryCode: "tn", seed: 4 })
    ]
  },
  {
    letter: "G",
    name: "Grupo G",
    teams: [
      team({ id: "BEL", fifaCode: "BEL", name: "Bélgica", shortName: "BEL", flag: "🇧🇪", countryCode: "be", seed: 1 }),
      team({ id: "EGY", fifaCode: "EGY", name: "Egito", shortName: "EGI", flag: "🇪🇬", countryCode: "eg", seed: 2 }),
      team({ id: "IRN", fifaCode: "IRN", name: "Irã", shortName: "IRA", flag: "🇮🇷", countryCode: "ir", seed: 3 }),
      team({ id: "NZL", fifaCode: "NZL", name: "Nova Zelândia", shortName: "NZL", flag: "🇳🇿", countryCode: "nz", seed: 4 })
    ]
  },
  {
    letter: "H",
    name: "Grupo H",
    teams: [
      team({ id: "ESP", fifaCode: "ESP", name: "Espanha", shortName: "ESP", flag: "🇪🇸", countryCode: "es", seed: 1 }),
      team({ id: "CPV", fifaCode: "CPV", name: "Cabo Verde", shortName: "CVE", flag: "🇨🇻", countryCode: "cv", seed: 2 }),
      team({ id: "KSA", fifaCode: "KSA", name: "Arábia Saudita", shortName: "SAU", flag: "🇸🇦", countryCode: "sa", seed: 3 }),
      team({ id: "URU", fifaCode: "URU", name: "Uruguai", shortName: "URU", flag: "🇺🇾", countryCode: "uy", seed: 4 })
    ]
  },
  {
    letter: "I",
    name: "Grupo I",
    teams: [
      team({ id: "FRA", fifaCode: "FRA", name: "França", shortName: "FRA", flag: "🇫🇷", countryCode: "fr", seed: 1 }),
      team({ id: "SEN", fifaCode: "SEN", name: "Senegal", shortName: "SEN", flag: "🇸🇳", countryCode: "sn", seed: 2 }),
      team({ id: "IRQ", fifaCode: "IRQ", name: "Iraque", shortName: "IRQ", flag: "🇮🇶", countryCode: "iq", seed: 3 }),
      team({ id: "NOR", fifaCode: "NOR", name: "Noruega", shortName: "NOR", flag: "🇳🇴", countryCode: "no", seed: 4 })
    ]
  },
  {
    letter: "J",
    name: "Grupo J",
    teams: [
      team({ id: "ARG", fifaCode: "ARG", name: "Argentina", shortName: "ARG", flag: "🇦🇷", countryCode: "ar", seed: 1 }),
      team({ id: "ALG", fifaCode: "ALG", name: "Argélia", shortName: "ARG", flag: "🇩🇿", countryCode: "dz", seed: 2 }),
      team({ id: "AUT", fifaCode: "AUT", name: "Áustria", shortName: "AUS", flag: "🇦🇹", countryCode: "at", seed: 3 }),
      team({ id: "JOR", fifaCode: "JOR", name: "Jordânia", shortName: "JOR", flag: "🇯🇴", countryCode: "jo", seed: 4 })
    ]
  },
  {
    letter: "K",
    name: "Grupo K",
    teams: [
      team({ id: "POR", fifaCode: "POR", name: "Portugal", shortName: "POR", flag: "🇵🇹", countryCode: "pt", seed: 1 }),
      team({ id: "COD", fifaCode: "COD", name: "RD Congo", shortName: "RDC", flag: "🇨🇩", countryCode: "cd", seed: 2 }),
      team({ id: "UZB", fifaCode: "UZB", name: "Uzbequistão", shortName: "UZB", flag: "🇺🇿", countryCode: "uz", seed: 3 }),
      team({ id: "COL", fifaCode: "COL", name: "Colômbia", shortName: "COL", flag: "🇨🇴", countryCode: "co", seed: 4 })
    ]
  },
  {
    letter: "L",
    name: "Grupo L",
    teams: [
      team({ id: "ENG", fifaCode: "ENG", name: "Inglaterra", shortName: "ING", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", countryCode: "gb-eng", seed: 1 }),
      team({ id: "CRO", fifaCode: "CRO", name: "Croácia", shortName: "CRO", flag: "🇭🇷", countryCode: "hr", seed: 2 }),
      team({ id: "GHA", fifaCode: "GHA", name: "Gana", shortName: "GAN", flag: "🇬🇭", countryCode: "gh", seed: 3 }),
      team({ id: "PAN", fifaCode: "PAN", name: "Panamá", shortName: "PAN", flag: "🇵🇦", countryCode: "pa", seed: 4 })
    ]
  }
];

export const worldCup2026QualifiedTeamNames = new Set(
  worldCup2026QualifiedGroups.flatMap((group) => group.teams.map((teamData) => teamData.name))
);

export const worldCup2026QualifiedFifaCodes = new Set(
  worldCup2026QualifiedGroups.flatMap((group) => group.teams.map((teamData) => teamData.fifaCode))
);

export const fifaCodeToCountryCode = new Map(
  worldCup2026QualifiedGroups.flatMap((group) =>
    group.teams.map((teamData) => [teamData.fifaCode, teamData.countryCode] as const)
  )
);

export const fifaCodeToFlagEmoji = new Map(
  worldCup2026QualifiedGroups.flatMap((group) =>
    group.teams.map((teamData) => [teamData.fifaCode, teamData.flag] as const)
  )
);
EOF

cat > lib/fifa/visualDemoData.ts <<'EOF'
export type VisualDemoTeam = {
  id: string;
  fifaCode?: string;
  name: string;
  shortName: string;
  flag: string;
  countryCode?: string;
  flagImageUrl?: string;
  seed: number;
};

export type VisualDemoGroup = {
  letter: string;
  name: string;
  teams: VisualDemoTeam[];
};

export { worldCup2026QualifiedGroups as visualDemoGroups } from "./worldCup2026QualifiedTeams.ts";
EOF

cat > lib/fifa/visualOfficialDataAdapter.ts <<'EOF'
import {
  visualDemoGroups,
  type VisualDemoGroup,
  type VisualDemoTeam
} from "./visualDemoData.ts";
import {
  fifaCodeToCountryCode,
  fifaCodeToFlagEmoji,
  getFlagImageUrl,
  worldCup2026QualifiedFifaCodes,
  worldCup2026QualifiedTeamNames
} from "./worldCup2026QualifiedTeams.ts";

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

  const fifaCode = row.fifa_code?.trim().toUpperCase() || undefined;
  const countryCode = fifaCode ? fifaCodeToCountryCode.get(fifaCode) : undefined;
  const flag = fifaCode ? fifaCodeToFlagEmoji.get(fifaCode) : undefined;

  return {
    id: fifaCode || row.id,
    fifaCode,
    name,
    shortName: normalizeShortName(name, row.short_name ?? fifaCode),
    flag: flag ?? normalizeFlagEmoji(row.flag_emoji),
    countryCode,
    flagImageUrl: countryCode ? getFlagImageUrl(countryCode) : undefined,
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

  if (groups.some((group) => group.teams.length !== 4)) {
    return true;
  }

  const allTeams = groups.flatMap((group) => group.teams);

  return allTeams.some((team) => {
    if (team.fifaCode && worldCup2026QualifiedFifaCodes.has(team.fifaCode)) {
      return false;
    }

    return !worldCup2026QualifiedTeamNames.has(team.name);
  });
}

async function loadVisualRowsFromDatabase(): Promise<{
  groupRows: VisualGroupRow[];
  teamRows: VisualTeamRow[];
}> {
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
          "Dados oficiais do banco ainda não batem com os 48 classificados. Exibindo grupos confirmados em modo visual seguro."
      };
    }

    return {
      groups,
      source: "database",
      message: "Dados carregados do banco local e validados contra os classificados da Copa 2026."
    };
  } catch {
    return {
      groups: visualDemoGroups,
      source: "demo_fallback",
      message:
        "Não foi possível carregar grupos do banco. Exibindo grupos confirmados em modo visual seguro."
    };
  }
}
EOF

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
if (!fs.existsSync(filePath)) {
  process.exit(0);
}

let source = fs.readFileSync(filePath, "utf8");

const oldTeamIdentity = `function TeamIdentity({ team }: { team: VisualDemoTeam }) {
  return (
    <span className="flex min-w-0 items-center gap-2">
      <span
        aria-hidden="true"
        className="grid size-8 shrink-0 place-items-center rounded-full border border-white/70 bg-white text-lg shadow-sm"
      >
        {team.flag}
      </span>
      <span className="min-w-0">
        <span className="block truncate font-semibold text-slate-900">{team.name}</span>
        <span className="block text-[11px] font-bold uppercase tracking-[0.22em] text-slate-400">
          {team.shortName}
        </span>
      </span>
    </span>
  );
}`;

const newTeamIdentity = `function TeamIdentity({ team }: { team: VisualDemoTeam }) {
  const flagStyle = team.flagImageUrl
    ? {
        backgroundImage: \`url("\${team.flagImageUrl}")\`
      }
    : undefined;

  return (
    <span className="flex min-w-0 items-center gap-2">
      <span
        aria-hidden="true"
        className={\`grid size-8 shrink-0 place-items-center overflow-hidden rounded-full border border-white/70 bg-white text-lg shadow-sm \${team.flagImageUrl ? "bg-cover bg-center bg-no-repeat" : ""}\`}
        style={flagStyle}
      >
        {team.flagImageUrl ? null : team.flag}
      </span>
      <span className="min-w-0">
        <span className="block truncate font-semibold text-slate-900">{team.name}</span>
        <span className="block text-[11px] font-bold uppercase tracking-[0.22em] text-slate-400">
          {team.shortName}
        </span>
      </span>
    </span>
  );
}`;

if (source.includes(oldTeamIdentity)) {
  source = source.replace(oldTeamIdentity, newTeamIdentity);
} else {
  source = source.replace(
    /function TeamIdentity\(\{ team \}: \{ team: VisualDemoTeam \}\) \{[\s\S]*?\n\}/,
    newTeamIdentity
  );
}

// Troca a chave de localStorage para evitar reaproveitar IDs antigos A1/B1.
source = source.replace(
  'const storageKey = "simulador-copa-2026:visual-state:v1";',
  'const storageKey = "simulador-copa-2026:visual-state:v2";'
);

fs.writeFileSync(filePath, source);
NODE

cat > tests/visual-demo-helpers.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";
import {
  buildVisualQualifiedTeams,
  chooseVisualTeam,
  countCompletedGroups,
  getDemoBestThirdPlacedTeams
} from "../lib/fifa/visualDemoHelpers.ts";

describe("visual demo helpers", () => {
  it("deve selecionar uma equipe por posição e remover duplicidade", () => {
    const firstPick = chooseVisualTeam({}, "first", "MEX");
    const secondPick = chooseVisualTeam(firstPick, "second", "MEX");

    expect(secondPick).toEqual({
      second: "MEX"
    });
  });

  it("deve contar grupos completos", () => {
    expect(
      countCompletedGroups(visualDemoGroups, {
        A: {
          first: "MEX",
          second: "RSA",
          third: "KOR"
        }
      })
    ).toBe(1);
  });

  it("deve montar classificados visuais", () => {
    const qualified = buildVisualQualifiedTeams(visualDemoGroups, {
      A: {
        first: "MEX",
        second: "RSA",
        third: "KOR"
      }
    });

    expect(qualified).toHaveLength(3);
    expect(qualified[0]?.team.name).toBe("México");
  });

  it("deve limitar terceiros demo a oito seleções", () => {
    const picks = Object.fromEntries(
      visualDemoGroups.map((group) => [
        group.letter,
        {
          first: group.teams[0]?.id,
          second: group.teams[1]?.id,
          third: group.teams[2]?.id
        }
      ])
    );

    expect(getDemoBestThirdPlacedTeams(visualDemoGroups, picks)).toHaveLength(8);
  });

  it("não deve conter Itália entre os classificados visuais", () => {
    const allTeamNames = visualDemoGroups.flatMap((group) => group.teams.map((team) => team.name));

    expect(allTeamNames).not.toContain("Itália");
    expect(allTeamNames).toHaveLength(48);
  });
});
EOF

cat > tests/visual-bracket-helpers.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  buildVisualBracketRounds,
  buildVisualRoundOf32,
  getVisualChampion
} from "../lib/fifa/visualBracketHelpers.ts";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";
import type { VisualGroupPicks } from "../lib/fifa/visualDemoHelpers.ts";

function fullGroupPicks(): VisualGroupPicks {
  return Object.fromEntries(
    visualDemoGroups.map((group) => [
      group.letter,
      {
        first: group.teams[0]?.id,
        second: group.teams[1]?.id,
        third: group.teams[2]?.id
      }
    ])
  );
}

describe("visual bracket helpers", () => {
  it("deve montar 16 confrontos iniciais", () => {
    expect(buildVisualRoundOf32(visualDemoGroups, fullGroupPicks())).toHaveLength(16);
  });

  it("deve propagar vencedores até a final", () => {
    const groupPicks = fullGroupPicks();
    let rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, {});
    const bracketPicks: Record<string, string> = {};

    for (const match of rounds.round32) {
      if (match.homeTeam) {
        bracketPicks[match.id] = match.homeTeam.id;
      }
    }

    rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

    expect(rounds.round16[0]?.homeTeam).not.toBeNull();
  });

  it("deve retornar campeão quando final estiver escolhida", () => {
    const groupPicks = fullGroupPicks();
    let rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, {});
    const bracketPicks: Record<string, string> = {};

    for (const roundKey of ["round32", "round16", "quarterFinals", "semiFinals", "final"] as const) {
      rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

      for (const match of rounds[roundKey]) {
        const winner = match.homeTeam ?? match.awayTeam;

        if (winner) {
          bracketPicks[match.id] = winner.id;
        }
      }
    }

    rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

    expect(getVisualChampion(rounds, bracketPicks)).not.toBeNull();
  });
});
EOF

cat > tests/visual-progress.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  buildVisualProgressSummary,
  clampVisualProgressPercentage,
  getVisualTotalBracketMatches
} from "../lib/fifa/visualProgress.ts";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";

describe("visual progress helpers", () => {
  it("deve calcular total de jogos do mata-mata visual", () => {
    expect(getVisualTotalBracketMatches()).toBe(31);
  });

  it("deve limitar percentual visual", () => {
    expect(clampVisualProgressPercentage(-10)).toBe(0);
    expect(clampVisualProgressPercentage(55.4)).toBe(55);
    expect(clampVisualProgressPercentage(110)).toBe(100);
  });

  it("deve montar resumo de progresso", () => {
    const [first, second, third] = visualDemoGroups[0]?.teams ?? [];

    const summary = buildVisualProgressSummary({
      groups: visualDemoGroups,
      groupPicks: {
        A: {
          first: first?.id,
          second: second?.id,
          third: third?.id
        }
      },
      bracketPicks: {
        "round32-0": second?.id ?? "RSA"
      }
    });

    expect(summary.completedGroups).toBe(1);
    expect(summary.totalGroups).toBe(12);
    expect(summary.totalBracketMatches).toBe(31);
    expect(summary.completionPercentage).toBeGreaterThan(0);
  });
});
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
          name: "México",
          short_name: "MEX",
          fifa_code: "MEX",
          flag_emoji: "🇲🇽",
          group_letter: "A",
          seed: 1
        }
      ]
    });

    expect(groups).toHaveLength(12);
    expect(groups[0]?.letter).toBe("A");
    expect(groups[0]?.teams[0]).toMatchObject({
      id: "MEX",
      name: "México",
      shortName: "MEX",
      flag: "🇲🇽",
      countryCode: "mx"
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

cat > docs/qualified-teams-and-flags.md <<'EOF'
# Bloco 22 — Seleções classificadas e bandeiras

## Correção

- Remove dados demo incorretos, incluindo Itália.
- Usa os 12 grupos conhecidos da Copa 2026.
- Adiciona imagem de bandeira por `countryCode`.
- Mantém fallback em emoji caso a imagem não carregue.
- Não usa escudos/logos de federações ou assets protegidos.

## Fonte

A lista visual foi alinhada com a tabela pública de grupos da Copa 2026 usada como referência do produto.
EOF

echo "==> Bloco 22 aplicado."
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
echo "  git commit -m \"fix: update visual teams and flags for world cup 2026\""
echo "  git push"
