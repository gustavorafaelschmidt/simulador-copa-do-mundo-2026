import { StatusPill } from "./StatusPill.tsx";

type PredictionProgressProps = {
  total: number;
  completed: number;
  label: string;
};

export function calculatePredictionProgressPercentage(total: number, completed: number): number {
  if (total <= 0) {
    return 0;
  }

  return Math.round((completed / total) * 100);
}

export function PredictionProgress({ total, completed, label }: PredictionProgressProps) {
  const percentage = calculatePredictionProgressPercentage(total, completed);

  return (
    <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Progresso
          </p>
          <h2 className="mt-2 text-xl font-bold">{label}</h2>
          <p className="mt-1 text-sm text-app-muted">
            {completed} de {total} previsões salvas.
          </p>
        </div>

        <StatusPill
          label={`${percentage}%`}
          tone={percentage === 100 ? "success" : percentage > 0 ? "warning" : "neutral"}
        />
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-app-border">
        <div
          aria-label={`${percentage}% concluído`}
          className="h-full rounded-full bg-app-primary"
          style={{ width: `${percentage}%` }}
        />
      </div>
    </section>
  );
}
