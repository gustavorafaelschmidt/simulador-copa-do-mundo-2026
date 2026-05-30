import Link from "next/link";
import { RankingTable } from "../../../components/ranking/RankingTable.tsx";
import { RANKING_TYPE } from "../../../lib/contracts/enums.ts";
import { APP_ROUTES } from "../../../lib/contracts/routes.ts";
import { getLatestRankingSnapshot } from "../../../services/ranking/rankingService.ts";

export default async function TeamRankingPage() {
  const snapshot = await getLatestRankingSnapshot(RANKING_TYPE.TEAM);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-5xl space-y-6">
        <div className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Ranking
          </p>
          <h1 className="mt-3 text-2xl font-bold">Ranking por equipes</h1>
          <p className="mt-3 text-sm text-app-muted">
            Classificação global das equipes com base nos consensos definidos.
          </p>
          <Link className="mt-4 inline-flex text-sm font-semibold text-app-primary" href={APP_ROUTES.RANKING_INDIVIDUAL}>
            Ver ranking individual →
          </Link>
        </div>

        <RankingTable
          emptyMessage="Nenhum ranking por equipes calculado ainda."
          snapshot={snapshot}
        />
      </section>
    </main>
  );
}
