import type { RankingSnapshotDTO } from "../../lib/contracts/ranking.ts";

type RankingTableProps = {
  snapshot: RankingSnapshotDTO | null;
  emptyMessage: string;
};

export function RankingTable({ snapshot, emptyMessage }: RankingTableProps) {
  if (!snapshot || snapshot.entries.length === 0) {
    return (
      <div className="rounded-app border border-dashed border-app-border bg-app-surface p-6 text-sm text-app-muted">
        {emptyMessage}
      </div>
    );
  }

  return (
    <section className="overflow-hidden rounded-app border border-app-border bg-app-surface shadow-app">
      <div className="border-b border-app-border p-4">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Atualizado em
        </p>
        <h2 className="mt-1 text-lg font-bold">
          {new Intl.DateTimeFormat("pt-BR", {
            dateStyle: "short",
            timeStyle: "short"
          }).format(new Date(snapshot.calculatedAt))}
        </h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[640px] text-left text-sm">
          <thead className="bg-app-bg text-xs uppercase tracking-wide text-app-muted">
            <tr>
              <th className="px-4 py-3">#</th>
              <th className="px-4 py-3">Participante</th>
              <th className="px-4 py-3">Pontos</th>
              <th className="px-4 py-3">Acertos</th>
              <th className="px-4 py-3">Previsões</th>
            </tr>
          </thead>
          <tbody>
            {snapshot.entries.map((entry) => (
              <tr className="border-t border-app-border" key={entry.id}>
                <td className="px-4 py-3 font-bold">{entry.rank}</td>
                <td className="px-4 py-3">{entry.participantKey}</td>
                <td className="px-4 py-3 font-semibold">{entry.score}</td>
                <td className="px-4 py-3">{entry.correctPredictions}</td>
                <td className="px-4 py-3">{entry.totalPredictions}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
