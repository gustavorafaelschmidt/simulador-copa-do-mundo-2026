import { OfficialDataImportForm } from "../../../components/admin/OfficialDataImportForm.tsx";
import { OfficialDataVersionsTable } from "../../../components/admin/OfficialDataVersionsTable.tsx";
import { requireAdminGlobalUser } from "../../../lib/auth/currentUser";
import { getOfficialDataReadinessReport } from "../../../services/officialData/officialDataService.ts";
import { getOfficialDataVersions } from "../../../services/officialData/officialDataImportService.ts";

export default async function AdminOfficialDataPage() {
  await requireAdminGlobalUser();

  const [versions, readinessReport] = await Promise.all([
    getOfficialDataVersions(),
    getOfficialDataReadinessReport()
  ]);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Admin
          </p>

          <h1 className="mt-3 text-2xl font-bold">Dados oficiais FIFA</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Importe dados oficiais versionados para grupos, seleções, partidas, slots e
            matriz dos terceiros colocados.
          </p>

          <div className="mt-5 rounded-xl border border-app-border p-4">
            <p className="text-sm font-semibold">Readiness</p>
            <p className="mt-2 text-sm text-app-muted">
              Pode usar regras oficiais:{" "}
              <strong>{readinessReport.canUseOfficialRules ? "Sim" : "Não"}</strong>
            </p>

            {readinessReport.blockingReasons.length > 0 ? (
              <ul className="mt-3 list-disc space-y-1 pl-5 text-sm text-app-muted">
                {readinessReport.blockingReasons.map((reason) => (
                  <li key={reason}>{reason}</li>
                ))}
              </ul>
            ) : null}
          </div>
        </div>

        <OfficialDataImportForm />

        <OfficialDataVersionsTable versions={versions} />
      </section>
    </main>
  );
}
