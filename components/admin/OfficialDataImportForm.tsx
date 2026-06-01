import { importOfficialDataManifestAction } from "../../actions/officialData.ts";

const exampleManifest = {
  source: {
    code: "FWC26_OFFICIAL_TODO",
    description: "TODO: substituir por manifesto oficial completo extraído dos documentos FIFA.",
    sourceDocumentRef: "FWC26_regulations_EN.pdf",
    status: "PARTIAL"
  },
  groups: Array.from({ length: 12 }, (_, index) => {
    const letter = String.fromCharCode(65 + index);

    return {
      letter,
      name: `Grupo ${letter}`
    };
  }),
  teams: [],
  matches: [],
  bracketSlots: [],
  thirdPlaceMatrix: []
};

export function OfficialDataImportForm() {
  return (
    <form
      action={importOfficialDataManifestAction as unknown as (formData: FormData) => Promise<void>}
      className="rounded-app border border-app-border bg-app-surface p-5 shadow-app"
    >
      <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
        Importação oficial
      </p>

      <h2 className="mt-2 text-xl font-bold">Importar manifesto JSON</h2>

      <p className="mt-3 text-sm leading-6 text-app-muted">
        Use somente dados oficiais versionados. Em produção, manifestos parciais ou sem
        as 495 combinações do Annexe C serão bloqueados.
      </p>

      <label className="mt-5 block">
        <span className="text-sm font-medium">Manifesto JSON</span>
        <textarea
          className="mt-1 min-h-96 w-full rounded-xl border border-app-border px-3 py-2 font-mono text-xs"
          name="manifestJson"
          required
          defaultValue={JSON.stringify(exampleManifest, null, 2)}
        />
      </label>

      <button
        className="mt-5 w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white"
        type="submit"
      >
        Importar dados oficiais
      </button>
    </form>
  );
}
