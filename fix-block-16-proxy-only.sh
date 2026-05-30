#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção do Bloco 16 — migrando middleware.ts para proxy.ts..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

if [ -f "middleware.ts" ]; then
  mkdir -p .backup/block-16-proxy
  cp middleware.ts .backup/block-16-proxy/middleware.ts.backup
fi

cat > proxy.ts <<'EOF'
import { NextResponse } from "next/server";
import { auth } from "./auth";
import { APP_ROUTES } from "./lib/contracts/routes";
import { GLOBAL_ROLE } from "./lib/contracts/enums";

const protectedPrefixes = [
  APP_ROUTES.DASHBOARD,
  APP_ROUTES.TEAMS,
  APP_ROUTES.SETTINGS,
  APP_ROUTES.ADMIN,
  APP_ROUTES.ONBOARDING
];

function isProtectedPath(pathname: string) {
  return protectedPrefixes.some((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`));
}

export default auth((request) => {
  const { nextUrl } = request;
  const session = request.auth;

  if (!isProtectedPath(nextUrl.pathname)) {
    return NextResponse.next();
  }

  if (!session?.user) {
    return NextResponse.redirect(new URL(APP_ROUTES.LOGIN, nextUrl));
  }

  const isOnboardingRoute = nextUrl.pathname === APP_ROUTES.ONBOARDING;

  if (!session.user.onboardingCompleted && !isOnboardingRoute) {
    return NextResponse.redirect(new URL(APP_ROUTES.ONBOARDING, nextUrl));
  }

  if (
    nextUrl.pathname.startsWith(APP_ROUTES.ADMIN) &&
    session.user.globalRole !== GLOBAL_ROLE.ADMIN_GLOBAL
  ) {
    return NextResponse.redirect(new URL(APP_ROUTES.DASHBOARD, nextUrl));
  }

  return NextResponse.next();
});

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/equipes/:path*",
    "/configuracoes/:path*",
    "/admin/:path*",
    "/onboarding/:path*"
  ]
};
EOF

rm -f middleware.ts

echo "==> middleware.ts removido e proxy.ts agora contém a lógica completa."
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
echo "  git commit -m \"feat: add onboarding and profile management\""
echo "  git push"
