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
