import Link from "next/link";
import { saveIndividualGroupPredictionAction } from "../../../../actions/prediction.ts";
import { APP_ROUTES } from "../../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../../lib/auth/currentUser";
import { listGroupPredictionBoard } from "../../../../services/prediction/predictionService.ts";

export default async function GroupPredictionsPage() {
  const user = await requireCurrentUser();
  const groups = await listGroupPredictionBoard(user.id);

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-6xl">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.PREDICTIONS}>
          ← Voltar para previsões
        </Link>

        <div className="mt-4 rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Fase de grupos
          </p>

          <h1 className="mt-3 text-2xl font-bold">Previsões dos grupos</h1>

          <p className="mt-3 text-sm leading-6 text-app-muted">
            Selecione 1º, 2º e 3º colocados de cada grupo. O backend calcula e
            persiste automaticamente o 4º colocado para manter consistência.
          </p>
        </div>

        <div className="mt-6 grid gap-4 lg:grid-cols-2">
          {groups.map((group) => (
            <article
              key={group.id}
              className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h2 className="text-xl font-bold">{group.name}</h2>
                  <p className="mt-1 text-sm text-app-muted">
                    Status dos dados: {group.officialDataStatus}
                  </p>
                </div>

                {group.prediction ? (
                  <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-800">
                    Salvo
                  </span>
                ) : null}
              </div>

              <form action={saveIndividualGroupPredictionAction} className="mt-5 space-y-4">
                <input name="group" type="hidden" value={group.letter} />

                {[
                  ["firstPlaceTeamId", "1º colocado"],
                  ["secondPlaceTeamId", "2º colocado"],
                  ["thirdPlaceTeamId", "3º colocado"]
                ].map(([fieldName, label]) => (
                  <label className="block" key={fieldName}>
                    <span className="text-sm font-medium">{label}</span>
                    <select
                      className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                      name={fieldName}
                      required
                      defaultValue={
                        fieldName === "firstPlaceTeamId"
                          ? group.prediction?.firstPlaceTeamId ?? ""
                          : fieldName === "secondPlaceTeamId"
                            ? group.prediction?.secondPlaceTeamId ?? ""
                            : group.prediction?.thirdPlaceTeamId ?? ""
                      }
                    >
                      <option value="">Selecione</option>
                      {group.teams.map((team) => (
                        <option key={team.id} value={team.id}>
                          {team.groupPosition}. {team.shortName}
                        </option>
                      ))}
                    </select>
                  </label>
                ))}

                <button
                  className="w-full rounded-xl bg-app-primary px-4 py-2 font-semibold text-white"
                  type="submit"
                >
                  Salvar grupo {group.letter}
                </button>
              </form>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
