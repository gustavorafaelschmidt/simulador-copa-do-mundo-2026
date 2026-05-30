import type { RealTournamentResultDTO } from "../../lib/contracts/admin.ts";

type AdminResultsTableProps = {
  results: RealTournamentResultDTO[];
};

export function AdminResultsTable({ results }: AdminResultsTableProps) {
  if (results.length === 0) {
    return (
      <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
        Nenhum resultado real cadastrado ainda.
      </div>
    );
  }

  return (
    <section className="overflow-hidden rounded-app border border-app-border bg-app-surface shadow-app">
      <div className="border-b border-app-border p-4">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Resultados reais
        </p>
        <h2 className="mt-1 text-lg font-bold">{results.length} registro(s)</h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[760px] text-left text-sm">
          <thead className="bg-app-bg text-xs uppercase tracking-wide text-app-muted">
            <tr>
              <th className="px-4 py-3">Chave</th>
              <th className="px-4 py-3">Tipo</th>
              <th className="px-4 py-3">Grupo</th>
              <th className="px-4 py-3">Slot</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Payload</th>
            </tr>
          </thead>
          <tbody>
            {results.map((result) => (
              <tr className="border-t border-app-border align-top" key={result.id}>
                <td className="px-4 py-3 font-medium">{result.resultKey}</td>
                <td className="px-4 py-3">{result.type}</td>
                <td className="px-4 py-3">{result.group ?? "-"}</td>
                <td className="px-4 py-3">{result.bracketSlotId ?? "-"}</td>
                <td className="px-4 py-3">{result.officialDataStatus}</td>
                <td className="max-w-xs px-4 py-3">
                  <pre className="overflow-x-auto rounded-lg bg-app-bg p-2 text-xs">
                    {JSON.stringify(result.payload, null, 2)}
                  </pre>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
