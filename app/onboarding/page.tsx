import { completeOnboardingAction } from "../../actions/profile.ts";
import { ProfileForm } from "../../components/forms/ProfileForm.tsx";
import { requireCurrentUser } from "../../lib/auth/currentUser";
import { getUserProfile } from "../../services/user/userProfileService.ts";

export default async function OnboardingPage() {
  const user = await requireCurrentUser();
  const profile = await getUserProfile(user.id);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-2xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Onboarding
        </p>

        <h1 className="mt-3 text-2xl font-bold">Complete seu perfil</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Precisamos desses dados para liberar o dashboard, rankings e participação em
          equipes. Cadastros via Google podem não retornar todas as informações obrigatórias.
        </p>

        <div className="mt-6">
          <ProfileForm
            action={completeOnboardingAction as unknown as (formData: FormData) => Promise<void>}
            profile={profile}
            submitLabel="Concluir onboarding"
          />
        </div>
      </section>
    </main>
  );
}
