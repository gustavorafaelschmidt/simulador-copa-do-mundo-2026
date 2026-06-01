#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção consolidada — type-check do build no computador novo..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p types .backup/build-typecheck-catchup

backup() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" ".backup/build-typecheck-catchup/$(echo "$file" | tr '/' '__').backup"
  fi
}

backup lib/errors/actionResponses.ts
backup components/forms/ProfileForm.tsx
backup services/admin/resultAdminService.ts
backup services/consensus/consensusService.ts
backup lib/validations/env.ts
backup lib/socket/socketAck.ts
backup lib/socket/socketAuth.ts
backup tests/socket.test.ts
backup types/autocannon.d.ts

cat > types/autocannon.d.ts <<'EOF'
declare module "autocannon" {
  export type AutocannonOptions = {
    url: string;
    connections?: number;
    duration?: number;
    pipelining?: number;
    method?: string;
    headers?: Record<string, string>;
    body?: string;
  };

  export type AutocannonMetric = {
    average?: number;
    mean?: number;
    stddev?: number;
    min?: number;
    max?: number;
    total?: number;
    p0_001?: number;
    p0_01?: number;
    p0_1?: number;
    p1?: number;
    p2_5?: number;
    p10?: number;
    p25?: number;
    p50?: number;
    p75?: number;
    p90?: number;
    p97_5?: number;
    p99?: number;
    p99_9?: number;
    p99_99?: number;
    p99_999?: number;
  };

  export type AutocannonResult = {
    url?: string;
    socketPath?: string;
    connections?: number;
    duration?: number;
    pipelining?: number;
    workers?: number;
    requests: AutocannonMetric;
    latency: AutocannonMetric;
    throughput: AutocannonMetric;
    errors: number;
    timeouts: number;
    mismatches: number;
    non2xx: number;
    resets: number;
  };

  export type Autocannon = {
    (options: AutocannonOptions): Promise<AutocannonResult>;
    printResult(result: AutocannonResult): string;
  };

  const autocannon: Autocannon;

  export default autocannon;
}
EOF

cat > lib/errors/actionResponses.ts <<'EOF'
import type { ActionError, ActionResult } from "../contracts/actionResult.ts";
import { AppError } from "./AppError.ts";

function toActionError(error: unknown): ActionError {
  if (error instanceof AppError) {
    return {
      code: error.code,
      message: error.message,
      statusCode: error.statusCode,
      details: error.details
    };
  }

  if (error instanceof Error) {
    return {
      code: "INTERNAL_ERROR",
      message: error.message,
      statusCode: 500
    };
  }

  return {
    code: "INTERNAL_ERROR",
    message: "Erro interno inesperado.",
    statusCode: 500
  };
}

export function success<TData>(data: TData, message?: string): ActionResult<TData> {
  return {
    ok: true,
    data,
    ...(message ? { message } : {})
  };
}

export function error<TData = never>(errorInput: unknown): ActionResult<TData> {
  return {
    ok: false,
    error: toActionError(errorInput)
  };
}

export function validationError<TData = never>(
  message = "Dados inválidos.",
  details?: unknown
): ActionResult<TData> {
  return {
    ok: false,
    error: {
      code: "VALIDATION_ERROR",
      message,
      statusCode: 422,
      details: details as ActionError["details"]
    }
  };
}

export function unauthorized<TData = never>(
  message = "Autenticação obrigatória."
): ActionResult<TData> {
  return {
    ok: false,
    error: {
      code: "UNAUTHORIZED",
      message,
      statusCode: 401
    }
  };
}

export function forbidden<TData = never>(
  message = "Você não tem permissão para executar esta ação."
): ActionResult<TData> {
  return {
    ok: false,
    error: {
      code: "FORBIDDEN",
      message,
      statusCode: 403
    }
  };
}
EOF

node <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

function read(file) {
  return fs.existsSync(file) ? fs.readFileSync(file, "utf8") : "";
}

function write(file, content) {
  fs.writeFileSync(file, content);
}

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) return walk(fullPath);
    return entry.isFile() && /\.(ts|tsx)$/.test(fullPath) ? [fullPath] : [];
  });
}

function patch(file, fn) {
  if (!fs.existsSync(file)) return;
  const source = read(file);
  const next = fn(source);
  if (next !== source) write(file, next);
}

// Zod v4: default precisa ser boolean após transform.
patch("lib/validations/env.ts", (s) =>
  s
    .replaceAll('booleanStringSchema.default("false")', "booleanStringSchema.default(false)")
    .replaceAll("booleanStringSchema.default('false')", "booleanStringSchema.default(false)")
    .replaceAll('booleanStringSchema.default("true")', "booleanStringSchema.default(true)")
    .replaceAll("booleanStringSchema.default('true')", "booleanStringSchema.default(true)")
);

// Códigos compatíveis com AppErrorCode.
for (const file of [
  ...walk("lib/socket"),
  ...walk("lib/errors"),
  ...walk("services"),
  ...walk("actions"),
  ...walk("server"),
  ...walk("tests")
]) {
  patch(file, (s) =>
    s
      .replaceAll('"INTERNAL_SERVER_ERROR"', '"INTERNAL_ERROR"')
      .replaceAll("'INTERNAL_SERVER_ERROR'", "'INTERNAL_ERROR'")
      .replaceAll('"CONFIGURATION_ERROR"', '"INTERNAL_ERROR"')
      .replaceAll("'CONFIGURATION_ERROR'", "'INTERNAL_ERROR'")
  );
}

// ProfileForm: Server Actions retornam ActionResult<T>, mas <form> espera Promise<void>.
patch("components/forms/ProfileForm.tsx", (s) => {
  if (!s.includes("const formAction = action as unknown as")) {
    s = s.replace(
      "export function ProfileForm({ action, profile, submitLabel }: ProfileFormProps) {\n  return (",
      "export function ProfileForm({ action, profile, submitLabel }: ProfileFormProps) {\n  const formAction = action as unknown as (formData: FormData) => Promise<void>;\n\n  return ("
    );
  }
  return s.replace('<form action={action} className="space-y-4">', '<form action={formAction} className="space-y-4">');
});

// Outros <form action={algumaAction}>.
for (const file of [...walk("app"), ...walk("components")]) {
  patch(file, (s) => {
    s = s.replace(
      /action=\{([A-Za-z_$][\w$]*Action)\}/g,
      (_m, name) => `action={${name} as unknown as (formData: FormData) => Promise<void>}`
    );
    return s.replace(
      /as unknown as \(formData: FormData\) => Promise<void> as unknown as \(formData: FormData\) => Promise<void>/g,
      "as unknown as (formData: FormData) => Promise<void>"
    );
  });
}

// Admin results: enums Prisma + JSON payload.
patch("services/admin/resultAdminService.ts", (s) => {
  s = s.replace(
`import {
  OFFICIAL_DATA_STATUS,
  REAL_RESULT_TYPE
} from "../../lib/contracts/enums.ts";`,
`import {
  OFFICIAL_DATA_STATUS,
  REAL_RESULT_TYPE,
  type GroupLetter,
  type KnockoutPhase
} from "../../lib/contracts/enums.ts";`
  );

  s = s.replace(
`import {
  OFFICIAL_DATA_STATUS,
  REAL_RESULT_TYPE,
  type GroupLetter,
  type KnockoutPhase,
  type GroupLetter,
  type KnockoutPhase
} from "../../lib/contracts/enums.ts";`,
`import {
  OFFICIAL_DATA_STATUS,
  REAL_RESULT_TYPE,
  type GroupLetter,
  type KnockoutPhase
} from "../../lib/contracts/enums.ts";`
  );

  s = s.replace("  group?: string;\n  knockoutPhase?: string;", "  group?: GroupLetter;\n  knockoutPhase?: KnockoutPhase;");
  s = s.replace(/\nimport type \{ Prisma \} from ["'][^"']*prisma\/generated\/client["'];/g, "");
  s = s.replace(/\nimport type \{ Prisma \} from ["']@prisma\/client["'];/g, "");
  s = s.replaceAll("validateRealResultPayload(input.type, input.payload) as Prisma.InputJsonValue", "validateRealResultPayload(input.type, input.payload) as never");
  s = s.replaceAll("const validatedPayload = validateRealResultPayload(input.type, input.payload);", "const validatedPayload = validateRealResultPayload(input.type, input.payload) as never;");
  return s;
});

// Consensus: group enum.
patch("services/consensus/consensusService.ts", (s) => {
  s = s.replace(
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE
} from "../../lib/contracts/enums.ts";`,
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE,
  type GroupLetter
} from "../../lib/contracts/enums.ts";`
  );

  s = s.replace(
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE,
  type GroupLetter,
  type GroupLetter
} from "../../lib/contracts/enums.ts";`,
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE,
  type GroupLetter
} from "../../lib/contracts/enums.ts";`
  );

  s = s.replace(
    "async function ensureNoOpenVotingSessionForGroup(teamId: string, group: string)",
    "async function ensureNoOpenVotingSessionForGroup(teamId: string, group: GroupLetter)"
  );

  s = s.replace(
`export type ApplyGroupTiebreakerInput = CloseVotingSessionInputDTO &
  GroupVoteSelection & {
    group: string;
  };`,
`export type ApplyGroupTiebreakerInput = CloseVotingSessionInputDTO &
  GroupVoteSelection & {
    group: GroupLetter;
  };`
  );

  return s;
});
NODE

echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run build"
echo ""
echo "Se passar, pode rodar:"
echo "  npm run dev"
echo "  npm run socket:dev"
