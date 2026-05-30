#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 5 — fundação do Motor FIFA, dados oficiais e guards de produção..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p lib/fifa
mkdir -p services/officialData
mkdir -p docs
mkdir -p tests

cat > lib/fifa/types.ts <<'EOF'
import type {
  GroupLetter,
  KnockoutPhase,
  OfficialDataStatus
} from "@/lib/contracts/enums";
import type {
  NationalTeamId,
  OfficialBracketSlotId,
  OfficialDataVersionId
} from "@/lib/contracts/officialData";

export type OfficialDataEntity = {
  id: string;
  officialDataStatus: OfficialDataStatus;
  officialDataVersionId: OfficialDataVersionId | null;
};

export type OfficialDataReadinessReport = {
  canUseOfficialRules: boolean;
  blockingReasons: string[];
  checkedAt: string;
};

export type GroupStandingPosition = 1 | 2 | 3 | 4;

export type GroupSelection = {
  group: GroupLetter;
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
  fourthPlaceTeamId: NationalTeamId;
};

export type QualifiedGroupTeams = {
  group: GroupLetter;
  firstPlaceTeamId: NationalTeamId;
  secondPlaceTeamId: NationalTeamId;
  thirdPlaceTeamId: NationalTeamId;
};

export type ThirdPlacedCandidate = {
  group: GroupLetter;
  teamId: NationalTeamId;
};

/*
  Representa apenas slots versionados. Não contém regra oficial de chaveamento.
  O relacionamento real entre grupos, terceiros e 16-avos deve vir dos documentos oficiais.
*/
export type BracketSlotDescriptor = {
  id: OfficialBracketSlotId;
  slotCode: string;
  phase: KnockoutPhase;
  sortOrder: number;
  sourceSlotCodeA: string | null;
  sourceSlotCodeB: string | null;
};
EOF

cat > lib/fifa/officialDataGuards.ts <<'EOF'
import { OFFICIAL_DATA_STATUS } from "@/lib/contracts/enums";
import { AppError } from "@/lib/errors/AppError";
import type { OfficialDataEntity, OfficialDataReadinessReport } from "@/lib/fifa/types";

type OfficialDataGuardOptions = {
  nodeEnv?: string;
  allowOfficialDataPlaceholders?: boolean;
};

function isProductionLike(options?: OfficialDataGuardOptions) {
  return (options?.nodeEnv ?? process.env.NODE_ENV) === "production";
}

function allowsPlaceholders(options?: OfficialDataGuardOptions) {
  return (
    options?.allowOfficialDataPlaceholders ??
    process.env.ALLOW_OFFICIAL_DATA_PLACEHOLDERS === "true"
  );
}

export function hasOnlyOfficialData(entities: OfficialDataEntity[]): boolean {
  return entities.every((entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.OFFICIAL);
}

export function buildOfficialDataReadinessReport(
  entities: OfficialDataEntity[]
): OfficialDataReadinessReport {
  const blockingReasons: string[] = [];

  const missingVersionCount = entities.filter((entity) => !entity.officialDataVersionId).length;
  const placeholderCount = entities.filter(
    (entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.PLACEHOLDER
  ).length;
  const partialCount = entities.filter(
    (entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.PARTIAL
  ).length;
  const deprecatedCount = entities.filter(
    (entity) => entity.officialDataStatus === OFFICIAL_DATA_STATUS.DEPRECATED
  ).length;

  if (entities.length === 0) {
    blockingReasons.push("Nenhum dado oficial foi encontrado.");
  }

  if (missingVersionCount > 0) {
    blockingReasons.push(`${missingVersionCount} registro(s) sem versão oficial vinculada.`);
  }

  if (placeholderCount > 0) {
    blockingReasons.push(`${placeholderCount} registro(s) ainda estão como PLACEHOLDER.`);
  }

  if (partialCount > 0) {
    blockingReasons.push(`${partialCount} registro(s) ainda estão como PARTIAL.`);
  }

  if (deprecatedCount > 0) {
    blockingReasons.push(`${deprecatedCount} registro(s) estão como DEPRECATED.`);
  }

  return {
    canUseOfficialRules: blockingReasons.length === 0,
    blockingReasons,
    checkedAt: new Date().toISOString()
  };
}

export function assertOfficialDataCanBeUsedInProduction(
  entities: OfficialDataEntity[],
  options?: OfficialDataGuardOptions
): OfficialDataReadinessReport {
  const report = buildOfficialDataReadinessReport(entities);

  if (!isProductionLike(options)) {
    return report;
  }

  if (allowsPlaceholders(options)) {
    return report;
  }

  if (!report.canUseOfficialRules) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message:
        "Dados oficiais incompletos. Placeholders, dados parciais ou versões ausentes não podem ser usados em produção.",
      statusCode: 500,
      details: report
    });
  }

  return report;
}
EOF

cat > lib/fifa/groupPrediction.ts <<'EOF'
import type {
  GroupSelection,
  QualifiedGroupTeams,
  ThirdPlacedCandidate
} from "@/lib/fifa/types";
import { AppError } from "@/lib/errors/AppError";

export function getGroupSelectionTeamIds(selection: GroupSelection): string[] {
  return [
    selection.firstPlaceTeamId,
    selection.secondPlaceTeamId,
    selection.thirdPlaceTeamId,
    selection.fourthPlaceTeamId
  ];
}

export function assertGroupSelectionIsComplete(selection: GroupSelection): void {
  const ids = getGroupSelectionTeamIds(selection);

  if (ids.some((id) => !id || id.trim().length === 0)) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Todas as quatro posições do grupo devem ser preenchidas.",
      statusCode: 422
    });
  }

  if (new Set(ids).size !== ids.length) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Uma seleção não pode ocupar mais de uma posição no mesmo grupo.",
      statusCode: 422
    });
  }
}

export function toQualifiedGroupTeams(selection: GroupSelection): QualifiedGroupTeams {
  assertGroupSelectionIsComplete(selection);

  return {
    group: selection.group,
    firstPlaceTeamId: selection.firstPlaceTeamId,
    secondPlaceTeamId: selection.secondPlaceTeamId,
    thirdPlaceTeamId: selection.thirdPlaceTeamId
  };
}

export function toThirdPlacedCandidate(selection: GroupSelection): ThirdPlacedCandidate {
  assertGroupSelectionIsComplete(selection);

  return {
    group: selection.group,
    teamId: selection.thirdPlaceTeamId
  };
}

/*
  Não escolhe os 8 melhores terceiros.
  A seleção dos melhores terceiros depende de critérios oficiais e dados reais/completos.
  Este helper apenas extrai candidatos a partir das escolhas do usuário/equipe.
*/
export function extractThirdPlacedCandidates(
  selections: GroupSelection[]
): ThirdPlacedCandidate[] {
  return selections.map(toThirdPlacedCandidate);
}
EOF

cat > lib/fifa/bracketGuards.ts <<'EOF'
import { OFFICIAL_DATA_STATUS } from "@/lib/contracts/enums";
import { AppError } from "@/lib/errors/AppError";
import type { BracketSlotDescriptor } from "@/lib/fifa/types";

type ThirdPlaceMatrixRuleLike = {
  combinationKey: string;
  officialDataStatus: string;
  officialDataVersionId: string | null;
};

export function assertBracketSlotsAreOfficial(slots: Array<BracketSlotDescriptor & {
  officialDataStatus?: string;
  officialDataVersionId?: string | null;
}>): void {
  const invalidSlots = slots.filter(
    (slot) =>
      slot.officialDataStatus !== undefined &&
      slot.officialDataStatus !== OFFICIAL_DATA_STATUS.OFFICIAL
  );

  if (invalidSlots.length > 0) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Slots de mata-mata oficiais ainda não estão disponíveis.",
      statusCode: 500,
      details: {
        invalidSlotCodes: invalidSlots.map((slot) => slot.slotCode)
      }
    });
  }
}

export function assertThirdPlaceMatrixIsOfficial(
  rules: ThirdPlaceMatrixRuleLike[]
): void {
  if (rules.length === 0) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Matriz oficial dos terceiros colocados não foi carregada.",
      statusCode: 500
    });
  }

  const invalidRules = rules.filter(
    (rule) =>
      rule.officialDataStatus !== OFFICIAL_DATA_STATUS.OFFICIAL ||
      !rule.officialDataVersionId
  );

  if (invalidRules.length > 0) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Matriz dos terceiros colocados possui regras não oficiais ou sem versão.",
      statusCode: 500,
      details: {
        invalidCombinationKeys: invalidRules.map((rule) => rule.combinationKey)
      }
    });
  }
}
EOF

cat > lib/fifa/index.ts <<'EOF'
export * from "@/lib/fifa/types";
export * from "@/lib/fifa/officialDataGuards";
export * from "@/lib/fifa/groupPrediction";
export * from "@/lib/fifa/bracketGuards";
EOF

cat > services/officialData/officialDataService.ts <<'EOF'
import { prisma } from "@/lib/db/prisma";
import { assertOfficialDataCanBeUsedInProduction } from "@/lib/fifa/officialDataGuards";

export async function getActiveOfficialDataVersion() {
  return prisma.officialDataVersion.findFirst({
    where: {
      isActive: true
    },
    orderBy: {
      createdAt: "desc"
    }
  });
}

export async function getOfficialDataReadinessReport() {
  const [groups, nationalTeams, bracketSlots, thirdPlaceRules] = await Promise.all([
    prisma.tournamentGroup.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    }),
    prisma.nationalTeam.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    }),
    prisma.officialBracketSlot.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    }),
    prisma.officialThirdPlaceMatrixRule.findMany({
      select: {
        id: true,
        officialDataStatus: true,
        officialDataVersionId: true
      }
    })
  ]);

  return assertOfficialDataCanBeUsedInProduction([
    ...groups,
    ...nationalTeams,
    ...bracketSlots,
    ...thirdPlaceRules
  ]);
}

export async function listGroupsWithTeams() {
  return prisma.tournamentGroup.findMany({
    include: {
      nationalTeams: {
        orderBy: {
          groupPosition: "asc"
        }
      }
    },
    orderBy: {
      letter: "asc"
    }
  });
}
EOF

cat > docs/fifa-engine.md <<'EOF'
# Bloco 5 — Fundação do Motor FIFA

## Objetivo

Criar a base do motor FIFA sem inventar regras oficiais da Copa do Mundo 2026.

## O que este bloco faz

- Cria tipos puros em `lib/fifa/types.ts`.
- Cria guards para impedir uso incorreto de dados oficiais incompletos.
- Cria helpers para validar escolhas completas de grupo.
- Cria helpers para extrair classificados e terceiros colocados a partir de previsões.
- Cria guards para slots oficiais e matriz dos terceiros colocados.
- Cria service inicial para consultar readiness dos dados oficiais.

## O que este bloco não faz

- Não escolhe os 8 melhores terceiros.
- Não resolve a matriz oficial dos terceiros colocados.
- Não monta chaveamento oficial de 16-avos.
- Não calcula critérios reais de desempate da FIFA.
- Não usa placeholders como regra oficial.

## Regra crítica

Qualquer função que dependa de chaveamento oficial deve exigir dados com:

```txt
OfficialDataStatus.OFFICIAL
officialDataVersionId preenchido
```

Em produção, placeholders não podem operar como dados oficiais.

## Próximos passos

Quando documentos oficiais forem fornecidos, os dados serão importados para:

- `OfficialDataVersion`;
- `TournamentGroup`;
- `NationalTeam`;
- `OfficialMatch`;
- `OfficialBracketSlot`;
- `OfficialThirdPlaceMatrixRule`.
EOF

cat > tests/fifa.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { OFFICIAL_DATA_STATUS } from "@/lib/contracts/enums";
import { AppError } from "@/lib/errors/AppError";
import {
  assertGroupSelectionIsComplete,
  assertOfficialDataCanBeUsedInProduction,
  buildOfficialDataReadinessReport,
  extractThirdPlacedCandidates,
  toQualifiedGroupTeams
} from "@/lib/fifa";

const validSelection = {
  group: "A" as const,
  firstPlaceTeamId: "team_1",
  secondPlaceTeamId: "team_2",
  thirdPlaceTeamId: "team_3",
  fourthPlaceTeamId: "team_4"
};

describe("fifa engine foundation", () => {
  it("deve validar seleção completa e sem duplicidade", () => {
    expect(() => assertGroupSelectionIsComplete(validSelection)).not.toThrow();
  });

  it("deve rejeitar seleção de grupo com times duplicados", () => {
    expect(() =>
      assertGroupSelectionIsComplete({
        ...validSelection,
        fourthPlaceTeamId: "team_3"
      })
    ).toThrow(AppError);
  });

  it("deve extrair classificados de grupo sem montar chaveamento oficial", () => {
    expect(toQualifiedGroupTeams(validSelection)).toEqual({
      group: "A",
      firstPlaceTeamId: "team_1",
      secondPlaceTeamId: "team_2",
      thirdPlaceTeamId: "team_3"
    });
  });

  it("deve extrair candidatos a terceiros colocados", () => {
    expect(extractThirdPlacedCandidates([validSelection])).toEqual([
      {
        group: "A",
        teamId: "team_3"
      }
    ]);
  });

  it("deve reportar dados oficiais incompletos", () => {
    const report = buildOfficialDataReadinessReport([
      {
        id: "x",
        officialDataStatus: OFFICIAL_DATA_STATUS.PLACEHOLDER,
        officialDataVersionId: null
      }
    ]);

    expect(report.canUseOfficialRules).toBe(false);
    expect(report.blockingReasons.length).toBeGreaterThan(0);
  });

  it("deve bloquear placeholders em produção", () => {
    expect(() =>
      assertOfficialDataCanBeUsedInProduction(
        [
          {
            id: "x",
            officialDataStatus: OFFICIAL_DATA_STATUS.PLACEHOLDER,
            officialDataVersionId: null
          }
        ],
        {
          nodeEnv: "production",
          allowOfficialDataPlaceholders: false
        }
      )
    ).toThrow(AppError);
  });
});
EOF

echo "==> Bloco 5 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add fifa engine foundation\""
echo "  git push"
