#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 15 — parser puro do manifesto oficial e import correto da página admin..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p lib/fifa/official-import

cat > lib/fifa/official-import/parseOfficialDataManifest.ts <<'EOF'
import { AppError } from "../../errors/AppError.ts";
import { officialDataImportManifestSchema } from "./officialDataManifestSchema.ts";
import {
  assertOfficialImportManifestConsistency,
  assertOfficialManifestIsProductionSafe
} from "./officialDataImportGuards.ts";
import type { OfficialDataImportManifest } from "./officialDataImportTypes.ts";

export function parseOfficialDataManifest(rawManifest: unknown): OfficialDataImportManifest {
  const parsed = officialDataImportManifestSchema.safeParse(rawManifest);

  if (!parsed.success) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Manifesto de dados oficiais inválido.",
      statusCode: 422,
      details: parsed.error.flatten().fieldErrors
    });
  }

  assertOfficialImportManifestConsistency(parsed.data);
  assertOfficialManifestIsProductionSafe(parsed.data);

  return parsed.data;
}
EOF

node <<'NODE'
const fs = require("node:fs");

const indexPath = "lib/fifa/official-import/index.ts";
let indexSource = fs.existsSync(indexPath) ? fs.readFileSync(indexPath, "utf8") : "";

if (!indexSource.includes('export * from "./parseOfficialDataManifest.ts";')) {
  indexSource += '\nexport * from "./parseOfficialDataManifest.ts";\n';
}

fs.writeFileSync(indexPath, `${indexSource.trim()}\n`);

const pagePath = "app/admin/dados-oficiais/page.tsx";
if (fs.existsSync(pagePath)) {
  let pageSource = fs.readFileSync(pagePath, "utf8");

  pageSource = pageSource.replace(
`import {
  getOfficialDataReadinessReport,
  getOfficialDataVersions
} from "../../../services/officialData/officialDataImportService.ts";`,
`import { getOfficialDataReadinessReport } from "../../../services/officialData/officialDataService.ts";
import { getOfficialDataVersions } from "../../../services/officialData/officialDataImportService.ts";`
  );

  fs.writeFileSync(pagePath, pageSource);
}
NODE

echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run dev"
echo ""
echo "Se passar, commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add official data import pipeline\""
echo "  git push"
