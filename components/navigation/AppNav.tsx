import Link from "next/link";
import { APP_ROUTES } from "../../lib/contracts/routes.ts";

const navigationItems = [
  ["Dashboard", APP_ROUTES.DASHBOARD],
  ["Previsões", APP_ROUTES.PREDICTIONS],
  ["Equipes", APP_ROUTES.TEAMS],
  ["Ranking", APP_ROUTES.RANKING_INDIVIDUAL],
  ["Gamificação", APP_ROUTES.GAMIFICATION],
  ["Perfil", APP_ROUTES.SETTINGS_PROFILE]
] as const;

export function AppNav() {
  return (
    <nav className="border-b border-app-border bg-app-surface">
      <div className="mx-auto flex max-w-6xl gap-2 overflow-x-auto px-4 py-3">
        {navigationItems.map(([label, href]) => (
          <Link
            className="shrink-0 rounded-full border border-app-border px-4 py-2 text-sm font-semibold text-app-muted transition hover:border-app-primary hover:text-app-primary"
            href={href}
            key={href}
          >
            {label}
          </Link>
        ))}
      </div>
    </nav>
  );
}
