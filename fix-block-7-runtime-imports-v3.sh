#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção robusta do Bloco 7 — normalizando imports do runtime Socket.io..."

if [ ! -f "package.json" ] || [ ! -f "server/socket.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-7-imports
cp server/socket.ts .backup/block-7-imports/socket.ts.backup

node <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const root = process.cwd();

const runtimeDirs = [
  "server",
  "lib/socket",
  "services/consensus",
  "services/team",
  "lib/fifa",
  "lib/validations",
  "lib/contracts",
  "lib/db",
  "lib/errors",
  "lib/logger"
];

function walk(dir) {
  if (!fs.existsSync(dir)) return [];

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  return entries.flatMap((entry) => {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      return walk(fullPath);
    }

    if (entry.isFile() && fullPath.endsWith(".ts") && !fullPath.endsWith(".d.ts")) {
      return [fullPath];
    }

    return [];
  });
}

function findTarget(specifier) {
  const normalized = specifier.replaceAll("\\", "/");

  const candidates = [];

  if (normalized.startsWith("@/")) {
    const withoutAlias = normalized.slice(2);
    candidates.push(
      path.join(root, withoutAlias),
      path.join(root, `${withoutAlias}.ts`),
      path.join(root, `${withoutAlias}.tsx`),
      path.join(root, withoutAlias, "index.ts"),
      path.join(root, withoutAlias, "index.tsx")
    );
  } else if (normalized.startsWith("./") || normalized.startsWith("../")) {
    candidates.push(
      path.join(root, normalized),
      path.join(root, `${normalized}.ts`),
      path.join(root, `${normalized}.tsx`),
      path.join(root, normalized, "index.ts"),
      path.join(root, normalized, "index.tsx")
    );
  }

  return candidates.find((candidate) => fs.existsSync(candidate) && fs.statSync(candidate).isFile());
}

function toRelativeSpecifier(currentFile, targetFile) {
  let relative = path.relative(path.dirname(currentFile), targetFile).replaceAll(path.sep, "/");

  if (!relative.startsWith(".")) {
    relative = `./${relative}`;
  }

  return relative;
}

function normalizeImportSpecifier(currentFile, specifier) {
  if (specifier.startsWith("@/")) {
    const target = findTarget(specifier);
    return target ? toRelativeSpecifier(currentFile, target) : specifier;
  }

  if (specifier.startsWith("./") || specifier.startsWith("../")) {
    if (/\.(ts|tsx|js|jsx|json|css|scss|mjs|cjs)$/.test(specifier)) {
      return specifier;
    }

    const absoluteBase = path.resolve(path.dirname(currentFile), specifier);
    const relativeFromRoot = path.relative(root, absoluteBase).replaceAll(path.sep, "/");
    const target = findTarget(relativeFromRoot);
    return target ? toRelativeSpecifier(currentFile, target) : specifier;
  }

  return specifier;
}

function normalizeFile(file) {
  let source = fs.readFileSync(file, "utf8");

  source = source.replace(
    /(from\s+["'])([^"']+)(["'])/g,
    (match, prefix, specifier, suffix) =>
      `${prefix}${normalizeImportSpecifier(file, specifier)}${suffix}`
  );

  source = source.replace(
    /(import\s*\(\s*["'])([^"']+)(["']\s*\))/g,
    (match, prefix, specifier, suffix) =>
      `${prefix}${normalizeImportSpecifier(file, specifier)}${suffix}`
  );

  fs.writeFileSync(file, source);
}

for (const dir of runtimeDirs) {
  for (const file of walk(path.join(root, dir))) {
    normalizeFile(file);
  }
}

const tsconfigPath = path.join(root, "tsconfig.json");
const tsconfig = JSON.parse(fs.readFileSync(tsconfigPath, "utf8"));
tsconfig.compilerOptions = tsconfig.compilerOptions ?? {};
tsconfig.compilerOptions.allowImportingTsExtensions = true;
fs.writeFileSync(tsconfigPath, `${JSON.stringify(tsconfig, null, 2)}\n`);

const packageJsonPath = path.join(root, "package.json");
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
packageJson.scripts = packageJson.scripts ?? {};
packageJson.scripts["socket:dev"] = "tsx watch server/socket.ts";
fs.writeFileSync(packageJsonPath, `${JSON.stringify(packageJson, null, 2)}\n`);
NODE

if npm ls tsconfig-paths >/dev/null 2>&1; then
  npm uninstall tsconfig-paths
fi

echo ""
echo "==> Conferindo aliases restantes no runtime Socket.io..."
if grep -R "@/services\|@/lib\|@/actions\|@/types\|@/contracts\|@/auth" server lib/socket services/consensus services/team lib/fifa lib/validations lib/contracts lib/db lib/errors lib/logger --include="*.ts"; then
  echo ""
  echo "ERRO: ainda existem aliases @/ em arquivos do runtime Socket.io."
  exit 1
else
  echo "OK: runtime Socket.io sem aliases @/."
fi

echo ""
echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run socket:dev"
echo ""
echo "Se passar, commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add socket realtime handlers\""
echo "  git push"
