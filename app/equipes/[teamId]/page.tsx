import Link from "next/link";
import {
  changeTeamMemberRoleAction,
  removeTeamMemberAction,
  reviewTeamMemberAction
} from "@/actions/team";
import {
  TEAM_MEMBER_APPROVAL_STATUS,
  TEAM_MEMBER_ROLE
} from "@/lib/contracts/enums";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { requireCurrentUser } from "@/lib/auth/currentUser";
import { getTeamDetails } from "@/services/team/teamService";

type TeamDetailsPageProps = {
  params: Promise<{
    teamId: string;
  }>;
};

export default async function TeamDetailsPage({ params }: TeamDetailsPageProps) {
  const { teamId } = await params;
  const user = await requireCurrentUser();
  const team = await getTeamDetails(teamId, user.id);
  const isCaptain =
    team.currentUserRole === TEAM_MEMBER_ROLE.CAPTAIN &&
    team.currentUserApprovalStatus === TEAM_MEMBER_APPROVAL_STATUS.APPROVED;

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-5xl rounded-app border border-app-border bg-app-surface p-5 shadow-app">
        <Link className="text-sm font-semibold text-app-primary" href={APP_ROUTES.TEAMS}>
          ← Voltar para equipes
        </Link>

        <div className="mt-4 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
              Equipe
            </p>

            <h1 className="mt-2 text-2xl font-bold">{team.name}</h1>

            <p className="mt-2 text-sm text-app-muted">
              Código de convite: <strong>{team.inviteCode}</strong>
            </p>

            {team.description ? (
              <p className="mt-3 text-sm leading-6 text-app-muted">{team.description}</p>
            ) : null}
          </div>

          <div className="rounded-xl border border-app-border p-3 text-sm">
            <p>Papel: {team.currentUserRole}</p>
            <p>Status: {team.currentUserApprovalStatus}</p>
          </div>
        </div>

        <div className="mt-8">
          <h2 className="text-lg font-bold">Membros</h2>

          <div className="mt-4 grid gap-3">
            {team.members.map((member) => {
              const isPending = member.approvalStatus === TEAM_MEMBER_APPROVAL_STATUS.PENDING;
              const isTargetCaptain = member.role === TEAM_MEMBER_ROLE.CAPTAIN;

              return (
                <article key={member.id} className="rounded-xl border border-app-border p-4">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <h3 className="font-semibold">
                        {member.user?.nickname ?? member.user?.name ?? member.userId}
                      </h3>

                      <p className="mt-1 text-sm text-app-muted">
                        Papel: {member.role} · Status: {member.approvalStatus}
                      </p>
                    </div>

                    {isCaptain && !isTargetCaptain ? (
                      <div className="flex flex-wrap gap-2">
                        {isPending ? (
                          <>
                            <form action={reviewTeamMemberAction as unknown as (formData: FormData) => Promise<void>}>
                              <input name="teamId" type="hidden" value={team.id} />
                              <input name="memberId" type="hidden" value={member.id} />
                              <input name="approvalStatus" type="hidden" value="APPROVED" />
                              <button
                                className="rounded-lg bg-app-primary px-3 py-2 text-sm font-semibold text-white"
                                type="submit"
                              >
                                Aprovar
                              </button>
                            </form>

                            <form action={reviewTeamMemberAction as unknown as (formData: FormData) => Promise<void>}>
                              <input name="teamId" type="hidden" value={team.id} />
                              <input name="memberId" type="hidden" value={member.id} />
                              <input name="approvalStatus" type="hidden" value="REJECTED" />
                              <button
                                className="rounded-lg border border-app-border px-3 py-2 text-sm font-semibold"
                                type="submit"
                              >
                                Rejeitar
                              </button>
                            </form>
                          </>
                        ) : null}

                        {member.approvalStatus === TEAM_MEMBER_APPROVAL_STATUS.APPROVED ? (
                          <form action={changeTeamMemberRoleAction as unknown as (formData: FormData) => Promise<void>}>
                            <input name="teamId" type="hidden" value={team.id} />
                            <input name="memberId" type="hidden" value={member.id} />
                            <select
                              className="rounded-lg border border-app-border px-3 py-2 text-sm"
                              name="role"
                              defaultValue={member.role}
                            >
                              <option value="ADMIN">ADMIN</option>
                              <option value="MEMBER">MEMBER</option>
                            </select>
                            <button
                              className="ml-2 rounded-lg border border-app-border px-3 py-2 text-sm font-semibold"
                              type="submit"
                            >
                              Alterar
                            </button>
                          </form>
                        ) : null}

                        {member.approvalStatus !== TEAM_MEMBER_APPROVAL_STATUS.REMOVED ? (
                          <form action={removeTeamMemberAction as unknown as (formData: FormData) => Promise<void>}>
                            <input name="teamId" type="hidden" value={team.id} />
                            <input name="memberId" type="hidden" value={member.id} />
                            <button
                              className="rounded-lg border border-red-200 px-3 py-2 text-sm font-semibold text-red-700"
                              type="submit"
                            >
                              Remover
                            </button>
                          </form>
                        ) : null}
                      </div>
                    ) : null}
                  </div>
                </article>
              );
            })}
          </div>
        </div>
      </section>
    </main>
  );
}
