import { refreshMyBadgesAction } from "../../../actions/gamification.ts";
import { BadgeCard } from "../../../components/badges/BadgeCard.tsx";
import { requireCurrentUser } from "../../../lib/auth/currentUser";
import { evaluateAndAwardUserBadges } from "../../../services/badges/badgeService.ts";

export default async function GamificationPage() {
  const user = await requireCurrentUser();
  const userBadges = await evaluateAndAwardUserBadges(user.id);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Gamificação
          </p>

          <h1 className="mt-3 text-2xl font-bold">Minhas conquistas</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Badges são concedidas automaticamente conforme você participa do simulador.
          </p>

          <form action={refreshMyBadgesAction} className="mt-5">
            <button
              className="rounded-xl border border-app-border px-4 py-2 font-semibold"
              type="submit"
            >
              Atualizar badges
            </button>
          </form>
        </div>

        {userBadges.length === 0 ? (
          <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
            Nenhuma badge conquistada ainda. Faça previsões, entre em equipes e acompanhe
            o ranking para desbloquear conquistas.
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {userBadges.map((userBadge) => (
              <BadgeCard
                awardedAt={userBadge.awardedAt}
                badge={userBadge.badge}
                key={userBadge.id}
              />
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
