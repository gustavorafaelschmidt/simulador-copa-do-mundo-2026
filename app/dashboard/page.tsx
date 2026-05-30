import { requireCurrentUser } from "@/lib/auth/currentUser";

export default async function DashboardPage() {
  const user = await requireCurrentUser();

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-4xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Dashboard
        </p>

        <h1 className="mt-3 text-2xl font-bold">Olá, {user.name ?? user.email}</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Autenticação base configurada. Os módulos de bolão, equipes, rankings e
          painel administrativo serão conectados nos próximos blocos.
        </p>
      </section>
    </main>
  );
}
