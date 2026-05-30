import Link from "next/link";
import { saveIndividualKnockoutPredictionAction } from "../../../../actions/prediction.ts";
import { APP_ROUTES } from "../../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../../lib/auth/currentUser";
import {
  listKnockoutPredictionBoard,
  listNationalTeamsForPredictionSelect
} from "../../../../services/prediction/predictionService.ts";

export default async function KnockoutPredictionsPage() {
  const user = await requireCurrentUser();
  const [slots, teams] = await Promise.all([
    listKnockoutPredictionBoard(user.id),
    listNationalTeamsForPredictionSelect()
  ]);

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-6xl">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.PREDICTIONS}>
          ← Voltar para previsões
        </Link>

        <div className="mt-4 rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Mata-mata
          </p>

          <h1 className="mt-3 text-2xl font-bold">Previsões do mata-mata</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Os slots ainda podem estar como placeholders em desenvolvimento. Em produção,
            o backend bloqueia uso de dados oficiais incompletos.
          </p>
        </div>

        <div className="mt-6 grid gap-4 lg:grid-cols-2">
          {slots.map((slot) => (
            <article
              key={slot.id}
              className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">{slot.slotCode}</h2>
                  <p className="mt-1 text-sm text-app-muted">
                    Fase: {slot.phase} · Status: {slot.officialDataStatus}
                  </p>
                </div>

                {slot.prediction ? (
                  <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-800">
                    Salvo
                  </span>
                ) : null}
              </div>

              <form action={saveIndividualKnockoutPredictionAction} className="mt-5 space-y-4">
                <input name="bracketSlotId" type="hidden" value={slot.id} />

                <label className="block">
                  <span className="text-sm font-medium">Vencedor previsto</span>
                  <select
                    className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                    name="winnerTeamId"
                    required
                    defaultValue={slot.prediction?.winnerTeamId ?? ""}
                  >
                    <option value="">Selecione</option>
                    {teams.map((team) => (
                      <option key={team.id} value={team.id}>
                        {team.groupLetter ? `Grupo ${team.groupLetter} · ` : ""}
                        {team.shortName}
                      </option>
                    ))}
                  </select>
                </label>

                <button
                  className="w-full rounded-xl bg-app-primary px-4 py-2 font-semibold text-white"
                  type="submit"
                >
                  Salvar previsão
                </button>
              </form>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
