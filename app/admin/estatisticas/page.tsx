import { createGlobalStatSnapshotAction } from "../../../actions/stats.ts";
import { GlobalStatsCards } from "../../../components/stats/GlobalStatsCards.tsx";
import { requireAdminGlobalUser } from "../../../lib/auth/currentUser";
import {
  createGlobalStatSnapshot,
  getLatestGlobalStatSnapshot
} from "../../../services/stats/globalStatsService.ts";

export default async function AdminStatsPage() {
  await requireAdminGlobalUser();

  const snapshot = (await getLatestGlobalStatSnapshot()) ?? (await createGlobalStatSnapshot());

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Admin
          </p>

          <h1 className="mt-3 text-2xl font-bold">Estatísticas globais</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Snapshot administrativo com volume de usuários, equipes, previsões,
            consensos, resultados e rankings.
          </p>

          <p className="mt-3 text-xs text-app-muted">
            Último snapshot:{" "}
            {new Intl.DateTimeFormat("pt-BR", {
              dateStyle: "short",
              timeStyle: "short"
            }).format(new Date(snapshot.calculatedAt))}
          </p>

          <form action={createGlobalStatSnapshotAction} className="mt-5">
            <button
              className="rounded-xl border border-app-border px-4 py-2 font-semibold"
              type="submit"
            >
              Gerar novo snapshot
            </button>
          </form>
        </div>

        <GlobalStatsCards payload={snapshot.payload} />
      </section>
    </main>
  );
}
