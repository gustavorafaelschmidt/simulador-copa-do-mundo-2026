import type { GlobalStatsPayload } from "../../services/stats/globalStatsCalculator.ts";

type GlobalStatsCardsProps = {
  payload: GlobalStatsPayload;
};

const statItems = [
  ["usersCount", "Usuários"],
  ["teamsCount", "Equipes"],
  ["individualPredictionsCount", "Previsões individuais"],
  ["teamConsensusCount", "Consensos de equipe"],
  ["realResultsCount", "Resultados reais"],
  ["rankingSnapshotsCount", "Rankings calculados"],
  ["engagementRate", "Engajamento (%)"]
] as const;

export function GlobalStatsCards({ payload }: GlobalStatsCardsProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {statItems.map(([key, label]) => (
        <article
          className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
          key={key}
        >
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            {label}
          </p>
          <p className="mt-3 text-3xl font-bold">{payload[key]}</p>
        </article>
      ))}
    </div>
  );
}
