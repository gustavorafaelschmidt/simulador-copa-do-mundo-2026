import Link from "next/link";
import { GroupPredictionCard } from "../../../../components/world-cup/GroupPredictionCard.tsx";
import { PredictionProgress } from "../../../../components/world-cup/PredictionProgress.tsx";
import { APP_ROUTES } from "../../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../../lib/auth/currentUser";
import { listGroupPredictionBoard } from "../../../../services/prediction/predictionService.ts";

export default async function GroupPredictionsPage() {
  const user = await requireCurrentUser();
  const groups = await listGroupPredictionBoard(user.id);
  const completedGroups = groups.filter((group) => group.prediction).length;

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-6xl">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.PREDICTIONS}>
          ← Voltar para previsões
        </Link>

        <div className="mt-4 grid gap-4 lg:grid-cols-[1fr_360px]">
          <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
            <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
              Fase de grupos
            </p>

            <h1 className="mt-3 text-2xl font-bold">Previsões dos grupos</h1>

            <p className="mt-3 text-sm leading-6 text-app-muted">
              Selecione 1º, 2º e 3º colocados de cada grupo. O backend calcula e
              persiste automaticamente o 4º colocado para manter consistência.
            </p>
          </section>

          <PredictionProgress completed={completedGroups} label="Grupos previstos" total={groups.length} />
        </div>

        <div className="mt-6 grid gap-4 lg:grid-cols-2">
          {groups.map((group) => (
            <GroupPredictionCard group={group} key={group.id} />
          ))}
        </div>
      </section>
    </main>
  );
}
