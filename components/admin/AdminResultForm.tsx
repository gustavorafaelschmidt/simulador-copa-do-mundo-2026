import {
  GROUP_LETTER_VALUES,
  KNOCKOUT_PHASE_VALUES,
  REAL_RESULT_TYPE_VALUES
} from "../../lib/contracts/enums.ts";
import { upsertRealTournamentResultAction } from "../../actions/adminResults.ts";

export function AdminResultForm() {
  return (
    <form
      action={upsertRealTournamentResultAction}
      className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
    >
      <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
        Novo resultado
      </p>

      <h2 className="mt-2 text-xl font-bold">Cadastrar ou atualizar resultado real</h2>

      <div className="mt-5 grid gap-4 md:grid-cols-2">
        <label className="block">
          <span className="text-sm font-medium">Tipo</span>
          <select
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="type"
            required
          >
            {REAL_RESULT_TYPE_VALUES.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-medium">Result key opcional</span>
          <input
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="resultKey"
            placeholder="group_standing:A"
          />
        </label>

        <label className="block">
          <span className="text-sm font-medium">Grupo</span>
          <select className="mt-1 w-full rounded-xl border border-app-border px-3 py-2" name="group">
            <option value="">Não se aplica</option>
            {GROUP_LETTER_VALUES.map((group) => (
              <option key={group} value={group}>
                {group}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-medium">Fase mata-mata</span>
          <select
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="knockoutPhase"
          >
            <option value="">Não se aplica</option>
            {KNOCKOUT_PHASE_VALUES.map((phase) => (
              <option key={phase} value={phase}>
                {phase}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-medium">Official match ID</span>
          <input className="mt-1 w-full rounded-xl border border-app-border px-3 py-2" name="officialMatchId" />
        </label>

        <label className="block">
          <span className="text-sm font-medium">Bracket slot ID</span>
          <input className="mt-1 w-full rounded-xl border border-app-border px-3 py-2" name="bracketSlotId" />
        </label>

        <label className="block md:col-span-2">
          <span className="text-sm font-medium">Fonte/documento oficial</span>
          <input
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            name="sourceDocumentRef"
            placeholder="FWC26_regulations_EN.pdf / Article / Annexe"
          />
        </label>

        <label className="block md:col-span-2">
          <span className="text-sm font-medium">Payload JSON</span>
          <textarea
            className="mt-1 min-h-40 w-full rounded-xl border border-app-border px-3 py-2 font-mono text-sm"
            name="payloadJson"
            required
            defaultValue={'{\n  "orderedTeamIds": ["team_1", "team_2", "team_3", "team_4"]\n}'}
          />
        </label>
      </div>

      <button
        className="mt-5 w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white"
        type="submit"
      >
        Salvar resultado real
      </button>
    </form>
  );
}
