import { saveIndividualKnockoutPredictionAction } from "../../actions/prediction.ts";
import type { NationalTeamDTO } from "../../lib/contracts/officialData.ts";
import type { KnockoutPredictionBoardItem } from "../../services/prediction/predictionService.ts";
import { SelectField } from "../forms/SelectField.tsx";
import { getKnockoutPhaseLabel } from "./KnockoutPhaseLabel.tsx";
import { StatusPill } from "./StatusPill.tsx";

type KnockoutSlotCardProps = {
  slot: KnockoutPredictionBoardItem;
  teams: NationalTeamDTO[];
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

export function KnockoutSlotCard({ slot, teams }: KnockoutSlotCardProps) {
  const predictedWinner = teams.find((team) => team.id === slot.prediction?.winnerTeamId);

  return (
    <article className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            {getKnockoutPhaseLabel(slot.phase)}
          </p>

          <h3 className="mt-2 text-lg font-bold">{slot.slotCode}</h3>

          <p className="mt-1 text-sm text-app-muted">
            Ordem: {slot.sortOrder}
            {slot.sourceSlotCodeA || slot.sourceSlotCodeB
              ? ` · Origem: ${slot.sourceSlotCodeA ?? "TBD"} x ${
                  slot.sourceSlotCodeB ?? "TBD"
                }`
              : ""}
          </p>
        </div>

        <div className="flex shrink-0 flex-col items-end gap-2">
          <StatusPill label={slot.officialDataStatus} tone={getDataStatusTone(slot.officialDataStatus)} />
          {slot.prediction ? <StatusPill label="Salvo" tone="success" /> : null}
        </div>
      </div>

      {slot.winnerGoesToSlotCode ? (
        <p className="mt-4 rounded-xl bg-app-bg px-3 py-2 text-sm text-app-muted">
          Vencedor avança para: <strong>{slot.winnerGoesToSlotCode}</strong>
        </p>
      ) : null}

      {predictedWinner ? (
        <p className="mt-4 rounded-xl bg-green-50 px-3 py-2 text-sm text-green-800">
          Palpite atual: <strong>{predictedWinner.shortName}</strong>
        </p>
      ) : null}

      <form action={saveIndividualKnockoutPredictionAction as unknown as (formData: FormData) => Promise<void>} className="mt-5 space-y-4">
        <input name="bracketSlotId" type="hidden" value={slot.id} />

        <SelectField
          defaultValue={slot.prediction?.winnerTeamId ?? ""}
          label="Vencedor previsto"
          name="winnerTeamId"
          required
        >
          <option value="">Selecione</option>
          {teams.map((team) => (
            <option key={team.id} value={team.id}>
              {team.groupLetter ? `Grupo ${team.groupLetter} · ` : ""}
              {team.shortName}
            </option>
          ))}
        </SelectField>

        <button
          className="w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white transition hover:opacity-90"
          type="submit"
        >
          Salvar previsão
        </button>
      </form>
    </article>
  );
}
