#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 4 — equipes privadas, membros, convites e permissões..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/team
mkdir -p actions
mkdir -p app/equipes/'[teamId]'
mkdir -p docs
mkdir -p tests

cat > services/team/teamService.ts <<'EOF'
import { randomBytes } from "node:crypto";
import { prisma } from "@/lib/db/prisma";
import {
  TEAM_MEMBER_APPROVAL_STATUS,
  TEAM_MEMBER_ROLE
} from "@/lib/contracts/enums";
import type {
  ChangeTeamMemberRoleInputDTO,
  CreateTeamInputDTO,
  JoinTeamByCodeInputDTO,
  RemoveTeamMemberInputDTO,
  ReviewTeamMemberInputDTO,
  TeamDTO,
  TeamId,
  TeamMemberDTO
} from "@/lib/contracts/team";
import { AppError } from "@/lib/errors/AppError";

type TeamWithMembership = TeamDTO & {
  currentUserRole: keyof typeof TEAM_MEMBER_ROLE;
  currentUserApprovalStatus: keyof typeof TEAM_MEMBER_APPROVAL_STATUS;
};

type TeamDetailsDTO = TeamDTO & {
  currentUserRole: keyof typeof TEAM_MEMBER_ROLE;
  currentUserApprovalStatus: keyof typeof TEAM_MEMBER_APPROVAL_STATUS;
  members: TeamMemberDTO[];
};

function isPrismaUniqueConstraintError(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code?: unknown }).code === "P2002"
  );
}

export function buildTeamSlug(name: string): string {
  const slug = name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return slug || "equipe";
}

export function createInviteCode(): string {
  return randomBytes(8).toString("base64url").replace(/[^a-zA-Z0-9]/g, "").slice(0, 10).toUpperCase();
}

async function generateUniqueTeamSlug(baseSlug: string): Promise<string> {
  const normalizedBaseSlug = buildTeamSlug(baseSlug);

  for (let attempt = 0; attempt < 20; attempt += 1) {
    const candidate = attempt === 0 ? normalizedBaseSlug : `${normalizedBaseSlug}-${attempt + 1}`;

    const existingTeam = await prisma.team.findUnique({
      where: {
        slug: candidate
      },
      select: {
        id: true
      }
    });

    if (!existingTeam) {
      return candidate;
    }
  }

  throw new AppError({
    code: "CONFLICT",
    message: "Não foi possível gerar um slug único para a equipe.",
    statusCode: 409
  });
}

async function generateUniqueInviteCode(): Promise<string> {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const code = createInviteCode();

    const existingTeam = await prisma.team.findUnique({
      where: {
        inviteCode: code
      },
      select: {
        id: true
      }
    });

    const existingInvite = await prisma.teamInvite.findUnique({
      where: {
        code
      },
      select: {
        id: true
      }
    });

    if (!existingTeam && !existingInvite) {
      return code;
    }
  }

  throw new AppError({
    code: "CONFLICT",
    message: "Não foi possível gerar um código de convite único.",
    statusCode: 409
  });
}

function toTeamDTO(team: {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  inviteCode: string;
  ownerId: string;
  isActive: boolean;
  maxMembers: number;
  createdAt: Date;
  updatedAt: Date;
}): TeamDTO {
  return {
    id: team.id,
    name: team.name,
    slug: team.slug,
    description: team.description,
    inviteCode: team.inviteCode,
    ownerId: team.ownerId,
    isActive: team.isActive,
    maxMembers: team.maxMembers,
    createdAt: team.createdAt.toISOString(),
    updatedAt: team.updatedAt.toISOString()
  };
}

function toTeamMemberDTO(member: {
  id: string;
  teamId: string;
  userId: string;
  role: keyof typeof TEAM_MEMBER_ROLE;
  approvalStatus: keyof typeof TEAM_MEMBER_APPROVAL_STATUS;
  approvedAt: Date | null;
  joinedAt: Date | null;
  removedAt: Date | null;
  user?: {
    id: string;
    name: string | null;
    nickname: string | null;
    image: string | null;
  };
}): TeamMemberDTO {
  return {
    id: member.id,
    teamId: member.teamId,
    userId: member.userId,
    role: member.role,
    approvalStatus: member.approvalStatus,
    approvedAt: member.approvedAt?.toISOString() ?? null,
    joinedAt: member.joinedAt?.toISOString() ?? null,
    removedAt: member.removedAt?.toISOString() ?? null,
    ...(member.user
      ? {
          user: {
            id: member.user.id,
            name: member.user.name,
            nickname: member.user.nickname,
            image: member.user.image
          }
        }
      : {})
  };
}

export async function createTeam(
  ownerUserId: string,
  input: CreateTeamInputDTO
): Promise<TeamDTO> {
  const slug = await generateUniqueTeamSlug(input.slug ?? input.name);
  const inviteCode = await generateUniqueInviteCode();
  const now = new Date();

  try {
    const team = await prisma.team.create({
      data: {
        name: input.name.trim(),
        slug,
        description: input.description?.trim() || null,
        inviteCode,
        ownerId: ownerUserId,
        maxMembers: input.maxMembers ?? 20,
        members: {
          create: {
            userId: ownerUserId,
            role: TEAM_MEMBER_ROLE.CAPTAIN,
            approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.APPROVED,
            approvedByUserId: ownerUserId,
            approvedAt: now,
            joinedAt: now
          }
        },
        invites: {
          create: {
            code: inviteCode,
            createdByUserId: ownerUserId
          }
        }
      }
    });

    return toTeamDTO(team);
  } catch (error) {
    if (isPrismaUniqueConstraintError(error)) {
      throw new AppError({
        code: "CONFLICT",
        message: "Já existe uma equipe com esse slug ou código de convite.",
        statusCode: 409
      });
    }

    throw error;
  }
}

export async function listTeamsForUser(userId: string): Promise<TeamWithMembership[]> {
  const memberships = await prisma.teamMember.findMany({
    where: {
      userId,
      approvalStatus: {
        not: TEAM_MEMBER_APPROVAL_STATUS.REMOVED
      }
    },
    include: {
      team: true
    },
    orderBy: {
      createdAt: "desc"
    }
  });

  return memberships.map((membership) => ({
    ...toTeamDTO(membership.team),
    currentUserRole: membership.role,
    currentUserApprovalStatus: membership.approvalStatus
  }));
}

export async function getTeamDetails(teamId: TeamId, currentUserId: string): Promise<TeamDetailsDTO> {
  const team = await prisma.team.findUnique({
    where: {
      id: teamId
    },
    include: {
      members: {
        include: {
          user: {
            select: {
              id: true,
              name: true,
              nickname: true,
              image: true
            }
          }
        },
        orderBy: [
          {
            role: "asc"
          },
          {
            createdAt: "asc"
          }
        ]
      }
    }
  });

  if (!team) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Equipe não encontrada.",
      statusCode: 404
    });
  }

  const currentMembership = team.members.find((member) => member.userId === currentUserId);

  if (!currentMembership || currentMembership.approvalStatus === TEAM_MEMBER_APPROVAL_STATUS.REMOVED) {
    throw new AppError({
      code: "FORBIDDEN",
      message: "Você não participa desta equipe.",
      statusCode: 403
    });
  }

  return {
    ...toTeamDTO(team),
    currentUserRole: currentMembership.role,
    currentUserApprovalStatus: currentMembership.approvalStatus,
    members: team.members.map(toTeamMemberDTO)
  };
}

export async function assertApprovedTeamMember(teamId: string, userId: string) {
  const membership = await prisma.teamMember.findUnique({
    where: {
      teamId_userId: {
        teamId,
        userId
      }
    }
  });

  if (!membership || membership.approvalStatus !== TEAM_MEMBER_APPROVAL_STATUS.APPROVED) {
    throw new AppError({
      code: "FORBIDDEN",
      message: "Você precisa ser membro aprovado da equipe.",
      statusCode: 403
    });
  }

  return membership;
}

export async function assertTeamCaptain(teamId: string, userId: string) {
  const membership = await assertApprovedTeamMember(teamId, userId);

  if (membership.role !== TEAM_MEMBER_ROLE.CAPTAIN) {
    throw new AppError({
      code: "FORBIDDEN",
      message: "Apenas o capitão pode executar esta ação.",
      statusCode: 403
    });
  }

  return membership;
}

export async function joinTeamByInviteCode(
  userId: string,
  input: JoinTeamByCodeInputDTO
): Promise<TeamMemberDTO> {
  const normalizedCode = input.inviteCode.trim().toUpperCase();

  return prisma.$transaction(async (tx) => {
    const invite = await tx.teamInvite.findUnique({
      where: {
        code: normalizedCode
      },
      include: {
        team: true
      }
    });

    if (!invite || invite.revokedAt) {
      throw new AppError({
        code: "NOT_FOUND",
        message: "Convite inválido ou revogado.",
        statusCode: 404
      });
    }

    if (invite.expiresAt && invite.expiresAt.getTime() < Date.now()) {
      throw new AppError({
        code: "BUSINESS_RULE_VIOLATION",
        message: "Convite expirado.",
        statusCode: 422
      });
    }

    if (invite.maxUses !== null && invite.usedCount >= invite.maxUses) {
      throw new AppError({
        code: "BUSINESS_RULE_VIOLATION",
        message: "Convite atingiu o limite de usos.",
        statusCode: 422
      });
    }

    const approvedMembersCount = await tx.teamMember.count({
      where: {
        teamId: invite.teamId,
        approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.APPROVED
      }
    });

    if (approvedMembersCount >= invite.team.maxMembers) {
      throw new AppError({
        code: "BUSINESS_RULE_VIOLATION",
        message: "A equipe já atingiu o limite de membros.",
        statusCode: 422
      });
    }

    const existingMembership = await tx.teamMember.findUnique({
      where: {
        teamId_userId: {
          teamId: invite.teamId,
          userId
        }
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            nickname: true,
            image: true
          }
        }
      }
    });

    if (existingMembership) {
      if (existingMembership.approvalStatus === TEAM_MEMBER_APPROVAL_STATUS.REMOVED) {
        const updatedMembership = await tx.teamMember.update({
          where: {
            id: existingMembership.id
          },
          data: {
            approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.PENDING,
            removedAt: null
          },
          include: {
            user: {
              select: {
                id: true,
                name: true,
                nickname: true,
                image: true
              }
            }
          }
        });

        return toTeamMemberDTO(updatedMembership);
      }

      return toTeamMemberDTO(existingMembership);
    }

    await tx.teamInvite.update({
      where: {
        id: invite.id
      },
      data: {
        usedCount: {
          increment: 1
        }
      }
    });

    const membership = await tx.teamMember.create({
      data: {
        teamId: invite.teamId,
        userId,
        role: TEAM_MEMBER_ROLE.MEMBER,
        approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.PENDING
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            nickname: true,
            image: true
          }
        }
      }
    });

    return toTeamMemberDTO(membership);
  });
}

export async function reviewTeamMember(
  reviewerUserId: string,
  input: ReviewTeamMemberInputDTO
): Promise<TeamMemberDTO> {
  await assertTeamCaptain(input.teamId, reviewerUserId);

  const member = await prisma.teamMember.findUnique({
    where: {
      id: input.memberId
    }
  });

  if (!member || member.teamId !== input.teamId) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Membro não encontrado nesta equipe.",
      statusCode: 404
    });
  }

  if (member.role === TEAM_MEMBER_ROLE.CAPTAIN) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "O capitão não pode ser revisado por esta ação.",
      statusCode: 422
    });
  }

  const now = new Date();

  const updatedMember = await prisma.teamMember.update({
    where: {
      id: input.memberId
    },
    data:
      input.approvalStatus === TEAM_MEMBER_APPROVAL_STATUS.APPROVED
        ? {
            approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.APPROVED,
            approvedByUserId: reviewerUserId,
            approvedAt: now,
            joinedAt: now
          }
        : {
            approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.REJECTED,
            approvedByUserId: reviewerUserId,
            approvedAt: now
          },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          nickname: true,
          image: true
        }
      }
    }
  });

  return toTeamMemberDTO(updatedMember);
}

export async function changeTeamMemberRole(
  captainUserId: string,
  input: ChangeTeamMemberRoleInputDTO
): Promise<TeamMemberDTO> {
  await assertTeamCaptain(input.teamId, captainUserId);

  const member = await prisma.teamMember.findUnique({
    where: {
      id: input.memberId
    }
  });

  if (!member || member.teamId !== input.teamId) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Membro não encontrado nesta equipe.",
      statusCode: 404
    });
  }

  if (member.role === TEAM_MEMBER_ROLE.CAPTAIN || input.role === TEAM_MEMBER_ROLE.CAPTAIN) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "O papel CAPTAIN não pode ser alterado por esta ação.",
      statusCode: 422
    });
  }

  const updatedMember = await prisma.teamMember.update({
    where: {
      id: input.memberId
    },
    data: {
      role: input.role
    },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          nickname: true,
          image: true
        }
      }
    }
  });

  return toTeamMemberDTO(updatedMember);
}

export async function removeTeamMember(
  captainUserId: string,
  input: RemoveTeamMemberInputDTO
): Promise<TeamMemberDTO> {
  await assertTeamCaptain(input.teamId, captainUserId);

  const member = await prisma.teamMember.findUnique({
    where: {
      id: input.memberId
    }
  });

  if (!member || member.teamId !== input.teamId) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Membro não encontrado nesta equipe.",
      statusCode: 404
    });
  }

  if (member.role === TEAM_MEMBER_ROLE.CAPTAIN) {
    throw new AppError({
      code: "BUSINESS_RULE_VIOLATION",
      message: "O capitão não pode ser removido por esta ação.",
      statusCode: 422
    });
  }

  const updatedMember = await prisma.teamMember.update({
    where: {
      id: input.memberId
    },
    data: {
      approvalStatus: TEAM_MEMBER_APPROVAL_STATUS.REMOVED,
      removedAt: new Date()
    },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          nickname: true,
          image: true
        }
      }
    }
  });

  return toTeamMemberDTO(updatedMember);
}
EOF

cat > actions/team.ts <<'EOF'
"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "@/lib/contracts/actionResult";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { error as actionError, success, validationError } from "@/lib/errors/actionResponses";
import { requireCurrentUser } from "@/lib/auth/currentUser";
import {
  changeTeamMemberRoleSchema,
  createTeamSchema,
  joinTeamByCodeSchema,
  removeTeamMemberSchema,
  reviewTeamMemberSchema
} from "@/lib/validations/team";
import {
  changeTeamMemberRole,
  createTeam,
  joinTeamByInviteCode,
  removeTeamMember,
  reviewTeamMember
} from "@/services/team/teamService";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  const entries = Object.entries(Object.fromEntries(formData.entries()));

  return Object.fromEntries(entries.filter(([, value]) => value !== ""));
}

export async function createTeamAction(
  formData: FormData
): Promise<ActionResult<{ teamId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = createTeamSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados da equipe inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const team = await createTeam(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAMS);

    return success({
      teamId: team.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function joinTeamByCodeAction(
  formData: FormData
): Promise<ActionResult<{ teamId: string; memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = joinTeamByCodeSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Código de convite inválido.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const membership = await joinTeamByInviteCode(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAMS);

    return success({
      teamId: membership.teamId,
      memberId: membership.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function reviewTeamMemberAction(
  formData: FormData
): Promise<ActionResult<{ memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = reviewTeamMemberSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de revisão inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const member = await reviewTeamMember(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAMS);
    revalidatePath(APP_ROUTES.TEAM_DETAILS(parsedInput.data.teamId));

    return success({
      memberId: member.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function changeTeamMemberRoleAction(
  formData: FormData
): Promise<ActionResult<{ memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = changeTeamMemberRoleSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de alteração de papel inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const member = await changeTeamMemberRole(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAM_DETAILS(parsedInput.data.teamId));

    return success({
      memberId: member.id
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function removeTeamMemberAction(
  formData: FormData
): Promise<ActionResult<{ memberId: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = removeTeamMemberSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de remoção inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const member = await removeTeamMember(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.TEAM_DETAILS(parsedInput.data.teamId));

    return success({
      memberId: member.id
    });
  } catch (error) {
    return actionError(error);
  }
}
EOF

cat > app/equipes/page.tsx <<'EOF'
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

            <form action={createTeamAction} className="mt-4 space-y-4">
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

            <form action={joinTeamByCodeAction} className="mt-4 space-y-4">
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
EOF

cat > app/equipes/'[teamId]'/page.tsx <<'EOF'
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
                            <form action={reviewTeamMemberAction}>
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

                            <form action={reviewTeamMemberAction}>
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
                          <form action={changeTeamMemberRoleAction}>
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
                          <form action={removeTeamMemberAction}>
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
EOF

cat > docs/team-module.md <<'EOF'
# Bloco 4 — Equipes privadas

## Objetivo

Implementar a fundação de equipes privadas, membros, convites e permissões.

## Regras implementadas

- Usuário autenticado pode criar equipe.
- Criador da equipe vira `CAPTAIN`.
- `CAPTAIN` nasce aprovado automaticamente.
- Equipe recebe `inviteCode` único.
- Convite inicial é criado com o mesmo código da equipe.
- Usuário pode solicitar entrada por código.
- Solicitação entra como `PENDING`.
- Apenas `CAPTAIN` pode aprovar ou rejeitar membros.
- Apenas `CAPTAIN` pode alterar papel entre `ADMIN` e `MEMBER`.
- `CAPTAIN` não pode ser removido por esta ação.
- `CAPTAIN` não pode ser atribuído por alteração comum de papel.

## Pontos críticos

A autoridade do capitão é central para os próximos blocos:

- abrir votação;
- fechar votação;
- aplicar voto de minerva.

Essas ações ainda não foram implementadas neste bloco.

## Concorrência e integridade

O banco já possui constraint única:

```txt
teamId + userId
```

Isso impede que o mesmo usuário entre duas vezes na mesma equipe.

## Próximos passos

- Bloco de consenso deve importar `assertTeamCaptain`.
- Socket.io não deve validar regra de capitão manualmente.
- Socket.io deve chamar services centralizados.
EOF

cat > tests/team.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { TEAM_MEMBER_ROLE } from "@/lib/contracts/enums";
import { changeTeamMemberRoleSchema, createTeamSchema } from "@/lib/validations/team";
import { buildTeamSlug, createInviteCode } from "@/services/team/teamService";

describe("team module", () => {
  it("deve gerar slug seguro para equipe", () => {
    expect(buildTeamSlug("Minha Equipe do Bolão!")).toBe("minha-equipe-do-bolao");
  });

  it("deve gerar código de convite em caixa alta", () => {
    const code = createInviteCode();

    expect(code).toMatch(/^[A-Z0-9]+$/);
    expect(code.length).toBeGreaterThanOrEqual(6);
  });

  it("deve validar criação de equipe", () => {
    const result = createTeamSchema.safeParse({
      name: "Equipe Campeã",
      slug: "equipe-campea",
      description: "Equipe privada do bolão.",
      maxMembers: 20
    });

    expect(result.success).toBe(true);
  });

  it("não deve permitir atribuir CAPTAIN por alteração de papel", () => {
    const result = changeTeamMemberRoleSchema.safeParse({
      teamId: "team_1",
      memberId: "member_1",
      role: TEAM_MEMBER_ROLE.CAPTAIN
    });

    expect(result.success).toBe(false);
  });
});
EOF

echo "==> Bloco 4 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add team management foundation\""
echo "  git push"
