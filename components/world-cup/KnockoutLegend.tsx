import { StatusPill } from "./StatusPill.tsx";

export function KnockoutLegend() {
  return (
    <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
        Importante
      </p>

      <h2 className="mt-2 text-lg font-bold">Dados oficiais e placeholders</h2>

      <p className="mt-3 text-sm leading-6 text-app-muted">
        Os slots de mata-mata podem estar como placeholders durante o desenvolvimento.
        Em produção, o backend bloqueia chaveamento não oficial ou incompleto.
      </p>

      <div className="mt-4 flex flex-wrap gap-2">
        <StatusPill label="OFFICIAL" tone="success" />
        <StatusPill label="PLACEHOLDER" tone="warning" />
        <StatusPill label="DEPRECATED" tone="danger" />
      </div>
    </section>
  );
}
