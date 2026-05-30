import { updateProfileAction } from "../../../actions/profile.ts";
import { ProfileForm } from "../../../components/forms/ProfileForm.tsx";
import { requireCurrentUser } from "../../../lib/auth/currentUser";
import { getUserProfile } from "../../../services/user/userProfileService.ts";

export default async function ProfileSettingsPage() {
  const user = await requireCurrentUser();
  const profile = await getUserProfile(user.id);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-2xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Perfil
        </p>

        <h1 className="mt-3 text-2xl font-bold">Editar perfil</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Mantenha seus dados atualizados para rankings, equipes e identificação no simulador.
        </p>

        <div className="mt-6">
          <ProfileForm
            action={updateProfileAction}
            profile={profile}
            submitLabel="Salvar alterações"
          />
        </div>
      </section>
    </main>
  );
}
