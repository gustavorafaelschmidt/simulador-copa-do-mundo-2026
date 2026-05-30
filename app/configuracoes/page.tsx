import Link from "next/link";
import { APP_ROUTES } from "../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../lib/auth/currentUser";

export default async function SettingsPage() {
  await requireCurrentUser();

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-3xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Configurações
        </p>

        <h1 className="mt-3 text-2xl font-bold">Minha conta</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Gerencie suas informações pessoais e preferências da plataforma.
        </p>

        <div className="mt-6">
          <Link
            className="inline-flex rounded-xl bg-app-primary px-4 py-3 font-semibold text-white"
            href={APP_ROUTES.SETTINGS_PROFILE}
          >
            Editar perfil
          </Link>
        </div>
      </section>
    </main>
  );
}
