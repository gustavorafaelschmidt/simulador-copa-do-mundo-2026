#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção final do Bloco 7 — extensões .ts nos imports do runtime Socket.io..."

if [ ! -f "package.json" ] || [ ! -f "server/socket.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-7-imports-v4
cp server/socket.ts .backup/block-7-imports-v4/socket.ts.backup

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

    if (entry.isDirectory()) return walk(fullPath);

    if (entry.isFile() && fullPath.endsWith(".ts") && !fullPath.endsWith(".d.ts")) {
      return [fullPath];
    }

    return [];
  });
}

function resolveTargetFile(currentFile, specifier) {
  if (!specifier.startsWith("@/") && !specifier.startsWith("./") && !specifier.startsWith("../")) {
    return null;
  }

  let baseAbs;

  if (specifier.startsWith("@/")) {
    baseAbs = path.join(root, specifier.slice(2));
  } else {
    baseAbs = path.resolve(path.dirname(currentFile), specifier);
  }

  const candidates = [
    baseAbs,
    `${baseAbs}.ts`,
    `${baseAbs}.tsx`,
    path.join(baseAbs, "index.ts"),
    path.join(baseAbs, "index.tsx")
  ];

  return candidates.find((candidate) => fs.existsSync(candidate) && fs.statSync(candidate).isFile()) ?? null;
}

function toRelativeTsSpecifier(currentFile, targetFile) {
  let relative = path.relative(path.dirname(currentFile), targetFile).replaceAll(path.sep, "/");

  if (!relative.startsWith(".")) {
    relative = `./${relative}`;
  }

  return relative;
}

function normalizeSpecifier(currentFile, specifier) {
  if (!specifier.startsWith("@/") && !specifier.startsWith("./") && !specifier.startsWith("../")) {
    return specifier;
  }

  if (specifier.endsWith(".css") || specifier.endsWith(".scss") || specifier.endsWith(".json")) {
    return specifier;
  }

  const targetFile = resolveTargetFile(currentFile, specifier);

  if (!targetFile) {
    return specifier;
  }

  return toRelativeTsSpecifier(currentFile, targetFile);
}

function normalizeFile(file) {
  let source = fs.readFileSync(file, "utf8");

  source = source.replace(
    /(from\s+["'])([^"']+)(["'])/g,
    (_match, prefix, specifier, suffix) => {
      return `${prefix}${normalizeSpecifier(file, specifier)}${suffix}`;
    }
  );

  source = source.replace(
    /(import\s*\(\s*["'])([^"']+)(["']\s*\))/g,
    (_match, prefix, specifier, suffix) => {
      return `${prefix}${normalizeSpecifier(file, specifier)}${suffix}`;
    }
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

echo ""
echo "==> Conferindo imports problemáticos no runtime Socket.io..."
if grep -R "@/services\|@/lib\|@/actions\|@/types\|@/contracts\|@/auth" server lib/socket services/consensus services/team lib/fifa lib/validations lib/contracts lib/db lib/errors lib/logger --include="*.ts"; then
  echo ""
  echo "ERRO: ainda existem aliases @/ em arquivos do runtime Socket.io."
  exit 1
fi

if grep -R 'from "\.\./[^"]*[^.]"\|from "\./[^"]*[^.]"\|from '\''\.\./[^'\'']*[^.]'\''\|from '\''\./[^'\'']*[^.]'\''' server lib/socket services/consensus services/team lib/fifa lib/validations lib/contracts lib/db lib/errors lib/logger --include="*.ts"; then
  echo ""
  echo "Aviso: pode haver import relativo sem extensão acima. Se o socket ainda falhar, me mande o log."
else
  echo "OK: runtime Socket.io sem aliases @/ e com imports locais normalizados."
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
