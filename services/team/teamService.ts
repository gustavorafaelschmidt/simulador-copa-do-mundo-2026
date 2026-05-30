import { prisma } from "../../lib/db/prisma.ts";
import {
  TEAM_MEMBER_APPROVAL_STATUS,
  TEAM_MEMBER_ROLE
} from "../../lib/contracts/enums.ts";
import type {
  ChangeTeamMemberRoleInputDTO,
  CreateTeamInputDTO,
  JoinTeamByCodeInputDTO,
  RemoveTeamMemberInputDTO,
  ReviewTeamMemberInputDTO,
  TeamDTO,
  TeamId,
  TeamMemberDTO
} from "../../lib/contracts/team.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import { buildTeamSlug, createInviteCode } from "./teamUtils.ts";

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
