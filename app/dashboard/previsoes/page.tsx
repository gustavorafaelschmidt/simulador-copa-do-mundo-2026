import Link from "next/link";
import { APP_ROUTES } from "../../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../../lib/auth/currentUser";

export default async function PredictionsPage() {
  await requireCurrentUser();

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-4xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Previsões individuais
        </p>

        <h1 className="mt-3 text-2xl font-bold">Monte seu palpite da Copa 2026</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Salve suas previsões individuais para fase de grupos e mata-mata. As regras
          oficiais completas serão aplicadas conforme os dados oficiais versionados forem
          substituindo os placeholders.
        </p>

        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <Link
            className="rounded-xl border border-app-border p-5 transition hover:border-app-primary"
            href={APP_ROUTES.PREDICTIONS_GROUPS}
          >
            <h2 className="font-semibold">Fase de grupos</h2>
            <p className="mt-2 text-sm text-app-muted">
              Escolha 1º, 2º e 3º colocados. O 4º é calculado automaticamente.
            </p>
          </Link>

          <Link
            className="rounded-xl border border-app-border p-5 transition hover:border-app-primary"
            href={APP_ROUTES.PREDICTIONS_KNOCKOUT}
          >
            <h2 className="font-semibold">Mata-mata</h2>
            <p className="mt-2 text-sm text-app-muted">
              Estrutura preparada para os slots oficiais de 16-avos até a final.
            </p>
          </Link>
        </div>
      </section>
    </main>
  );
}
