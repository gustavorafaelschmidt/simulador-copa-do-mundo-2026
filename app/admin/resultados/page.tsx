import { recalculateAllRankingsAction } from "../../../actions/adminResults.ts";
import { AdminResultForm } from "../../../components/admin/AdminResultForm.tsx";
import { AdminResultsTable } from "../../../components/admin/AdminResultsTable.tsx";
import { requireAdminGlobalUser } from "../../../lib/auth/currentUser";
import { listRealTournamentResults } from "../../../services/admin/resultAdminService.ts";

export default async function AdminResultsPage() {
  await requireAdminGlobalUser();
  const results = await listRealTournamentResults();

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Admin
          </p>

          <h1 className="mt-3 text-2xl font-bold">Resultados reais da Copa</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Cadastre resultados oficiais para alimentar pontuação e rankings. Use somente
            dados confirmados por documento oficial ou resultado real validado.
          </p>

          <form action={recalculateAllRankingsAction} className="mt-5">
            <button
              className="rounded-xl border border-app-border px-4 py-2 font-semibold"
              type="submit"
            >
              Recalcular rankings
            </button>
          </form>
        </div>

        <AdminResultForm />

        <AdminResultsTable results={results} />
      </section>
    </main>
  );
}
