import { requireCurrentUser } from "@/lib/auth/currentUser";

export default async function OnboardingPage() {
  const user = await requireCurrentUser();

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-3xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Onboarding
        </p>

        <h1 className="mt-3 text-2xl font-bold">Complete seu perfil</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Usuário autenticado: {user.email ?? user.name}. O formulário completo de
          onboarding será implementado no bloco específico de onboarding.
        </p>
      </section>
    </main>
  );
}
