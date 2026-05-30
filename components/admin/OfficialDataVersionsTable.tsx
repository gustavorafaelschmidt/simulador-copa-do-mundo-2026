type OfficialDataVersionRow = {
  id: string;
  code: string;
  description: string;
  status: string;
  sourceDocumentRef: string | null;
  importedAt: Date | null;
  isActive: boolean;
};

type OfficialDataVersionsTableProps = {
  versions: OfficialDataVersionRow[];
};

export function OfficialDataVersionsTable({ versions }: OfficialDataVersionsTableProps) {
  if (versions.length === 0) {
    return (
      <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
        Nenhuma versão oficial importada ainda.
      </div>
    );
  }

  return (
    <section className="overflow-hidden rounded-app border border-app-border bg-app-surface shadow-app">
      <div className="border-b border-app-border p-4">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Versões
        </p>
        <h2 className="mt-1 text-lg font-bold">Dados oficiais versionados</h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-left text-sm">
          <thead className="bg-app-bg text-xs uppercase tracking-wide text-app-muted">
            <tr>
              <th className="px-4 py-3">Código</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Ativa</th>
              <th className="px-4 py-3">Fonte</th>
              <th className="px-4 py-3">Importada em</th>
            </tr>
          </thead>
          <tbody>
            {versions.map((version) => (
              <tr className="border-t border-app-border" key={version.id}>
                <td className="px-4 py-3 font-medium">{version.code}</td>
                <td className="px-4 py-3">{version.status}</td>
                <td className="px-4 py-3">{version.isActive ? "Sim" : "Não"}</td>
                <td className="px-4 py-3">{version.sourceDocumentRef ?? "-"}</td>
                <td className="px-4 py-3">
                  {version.importedAt
                    ? new Intl.DateTimeFormat("pt-BR", {
                        dateStyle: "short",
                        timeStyle: "short"
                      }).format(version.importedAt)
                    : "-"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
