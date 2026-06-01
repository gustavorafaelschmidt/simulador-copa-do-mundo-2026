import type { UserProfileDTO } from "../../services/user/userProfileService.ts";

type ProfileFormProps = {
  action: (formData: FormData) => Promise<unknown>;
  profile?: UserProfileDTO | null;
  submitLabel: string;
};

export function ProfileForm({ action, profile, submitLabel }: ProfileFormProps) {
  return (
    <form action={action} className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-sm font-medium">Nome</span>
          <input
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            defaultValue={profile?.firstName ?? ""}
            name="firstName"
            required
          />
        </label>

        <label className="block">
          <span className="text-sm font-medium">Sobrenome</span>
          <input
            className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
            defaultValue={profile?.lastName ?? ""}
            name="lastName"
            required
          />
        </label>
      </div>

      <label className="block">
        <span className="text-sm font-medium">Nickname</span>
        <input
          className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
          defaultValue={profile?.nickname ?? ""}
          name="nickname"
          required
        />
      </label>

      <label className="block">
        <span className="text-sm font-medium">Data de nascimento</span>
        <input
          className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
          defaultValue={profile?.birthDate ?? ""}
          name="birthDate"
          required
          type="date"
        />
      </label>

      <button
        className="w-full rounded-xl bg-app-primary px-4 py-3 font-semibold text-white transition hover:opacity-90"
        type="submit"
      >
        {submitLabel}
      </button>
    </form>
  );
}
