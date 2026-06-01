import Link from "next/link";
import { createTeamAction, joinTeamByCodeAction } from "@/actions/team";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { TEAM_MEMBER_APPROVAL_STATUS } from "@/lib/contracts/enums";
import { requireCurrentUser } from "@/lib/auth/currentUser";
import { listTeamsForUser } from "@/services/team/teamService";

export default async function TeamsPage() {
  const user = await requireCurrentUser();
  const teams = await listTeamsForUser(user.id);

  return (
    <main className="min-h-dvh px-4 py-8">
      <div className="mx-auto grid max-w-6xl gap-6 lg:grid-cols-[1fr_360px]">
        <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
          <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
            Equipes
          </p>

          <h1 className="mt-3 text-2xl font-bold">Minhas equipes</h1>

          <div className="mt-6 grid gap-3">
            {teams.length === 0 ? (
              <p className="rounded-xl border border-dashed border-app-border p-4 text-sm text-app-muted">
                Você ainda não participa de nenhuma equipe.
              </p>
            ) : (
              teams.map((team) => (
                <Link
                  key={team.id}
                  className="rounded-xl border border-app-border p-4 transition hover:border-app-primary"
                  href={APP_ROUTES.TEAM_DETAILS(team.id)}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <h2 className="font-semibold">{team.name}</h2>
                      <p className="mt-1 text-sm text-app-muted">
                        Papel: {team.currentUserRole} · Status: {team.currentUserApprovalStatus}
                      </p>
                    </div>

                    {team.currentUserApprovalStatus === TEAM_MEMBER_APPROVAL_STATUS.PENDING ? (
                      <span className="rounded-full bg-yellow-100 px-3 py-1 text-xs font-semibold text-yellow-800">
                        Pendente
                      </span>
                    ) : null}
                  </div>
                </Link>
              ))
            )}
          </div>
        </section>

        <aside className="space-y-6">
          <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
            <h2 className="text-lg font-bold">Criar equipe</h2>

            <form action={createTeamAction as unknown as (formData: FormData) => Promise<void>} className="mt-4 space-y-4">
              <label className="block">
                <span className="text-sm font-medium">Nome</span>
                <input
                  className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                  name="name"
                  required
                />
              </label>

              <label className="block">
                <span className="text-sm font-medium">Slug opcional</span>
                <input
                  className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                  name="slug"
                  placeholder="minha-equipe"
                />
              </label>

              <label className="block">
                <span className="text-sm font-medium">Descrição</span>
                <textarea
                  className="mt-1 min-h-24 w-full rounded-xl border border-app-border px-3 py-2"
                  name="description"
                />
              </label>

              <label className="block">
                <span className="text-sm font-medium">Limite de membros</span>
                <input
                  className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                  type="number"
                  min="2"
                  max="100"
                  name="maxMembers"
                  defaultValue="20"
                />
              </label>

              <button
                className="w-full rounded-xl bg-app-primary px-4 py-2 font-semibold text-white"
                type="submit"
              >
                Criar equipe
              </button>
            </form>
          </section>

          <section className="rounded-app border border-app-border bg-app-surface p-5 shadow-app">
            <h2 className="text-lg font-bold">Entrar por código</h2>

            <form action={joinTeamByCodeAction as unknown as (formData: FormData) => Promise<void>} className="mt-4 space-y-4">
              <label className="block">
                <span className="text-sm font-medium">Código de convite</span>
                <input
                  className="mt-1 w-full rounded-xl border border-app-border px-3 py-2 uppercase"
                  name="inviteCode"
                  required
                />
              </label>

              <button
                className="w-full rounded-xl border border-app-border px-4 py-2 font-semibold"
                type="submit"
              >
                Solicitar entrada
              </button>
            </form>
          </section>
        </aside>
      </div>
    </main>
  );
}
