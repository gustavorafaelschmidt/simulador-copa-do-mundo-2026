import { saveIndividualGroupPredictionAction } from "../../actions/prediction.ts";
import type { GroupPredictionBoardItem } from "../../services/prediction/predictionService.ts";
import { SelectField } from "../forms/SelectField.tsx";
import { StatusPill } from "./StatusPill.tsx";

type GroupPredictionCardProps = {
  group: GroupPredictionBoardItem;
};

function getDataStatusTone(status: string) {
  if (status === "OFFICIAL") {
    return "success" as const;
  }

  if (status === "PLACEHOLDER") {
    return "warning" as const;
  }

  if (status === "DEPRECATED") {
    return "danger" as const;
  }

  return "neutral" as const;
}

export function GroupPredictionCard({ group }: GroupPredictionCardProps) {
  return (
    <article className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Grupo {group.letter}
          </p>
          <h2 className="mt-2 text-xl font-bold">{group.name}</h2>
          <p className="mt-1 text-sm text-app-muted">
            Escolha os três primeiros. O 4º colocado será calculado automaticamente.
          </p>
        </div>

        <div className="flex shrink-0 flex-col items-end gap-2">
          <StatusPill
            label={group.officialDataStatus}
            tone={getDataStatusTone(group.officialDataStatus)}
          />
          {group.prediction ? <StatusPill label="Salvo" tone="success" /> : null}
        </div>
      </div>

      <div className="mt-5 rounded-xl border border-app-border p-3">
        <p className="text-xs font-semibold uppercase tracking-wide text-app-muted">
          Seleções do grupo
        </p>

        <ol className="mt-3 grid gap-2 text-sm">
          {group.teams.map((team) => (
            <li className="flex items-center justify-between gap-3" key={team.id}>
              <span>
                {team.groupPosition}. {team.shortName}
              </span>
              <span className="text-xs text-app-muted">{team.fifaCode}</span>
            </li>
          ))}
        </ol>
      </div>

      <form action={saveIndividualGroupPredictionAction as unknown as (formData: FormData) => Promise<void>} className="mt-5 space-y-4">
        <input name="group" type="hidden" value={group.letter} />

        <SelectField
          defaultValue={group.prediction?.firstPlaceTeamId ?? ""}
          label="1º colocado"
          name="firstPlaceTeamId"
          required
        >
          <option value="">Selecione</option>
          {group.teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupPosition}. {team.shortName}
            </option>
          ))}
        </SelectField>

        <SelectField
          defaultValue={group.prediction?.secondPlaceTeamId ?? ""}
          label="2º colocado"
          name="secondPlaceTeamId"
          required
        >
          <option value="">Selecione</option>
          {group.teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupPosition}. {team.shortName}
            </option>
          ))}
        </SelectField>

        <SelectField
          defaultValue={group.prediction?.thirdPlaceTeamId ?? ""}
          label="3º colocado"
          name="thirdPlaceTeamId"
          required
        >
          <option value="">Selecione</option>
          {group.teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupPosition}. {team.shortName}
            </option>
          ))}
        </SelectField>

        {group.prediction ? (
          <p className="rounded-xl bg-app-bg px-3 py-2 text-sm text-app-muted">
            4º calculado:{" "}
            <strong>
              {group.teams.find((team) => team.id === group.prediction?.fourthPlaceTeamId)
                ?.shortName ?? "não identificado"}
            </strong>
          </p>
        ) : null}

        <button
          className="w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white transition hover:opacity-90"
          type="submit"
        >
          Salvar previsão do grupo {group.letter}
        </button>
      </form>
    </article>
  );
}
