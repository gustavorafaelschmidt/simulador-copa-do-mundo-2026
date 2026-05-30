import { prisma } from "../../lib/db/prisma.ts";
import { AppError } from "../../lib/errors/AppError.ts";
import type {
  CompleteUserProfileInput,
  UpdateUserProfileInput
} from "../../lib/validations/profile.ts";
import {
  buildFullName,
  normalizeNickname,
  parseBirthDateAsUtcDate
} from "./profileUtils.ts";

export type UserProfileDTO = {
  id: string;
  email: string | null;
  name: string | null;
  firstName: string | null;
  lastName: string | null;
  nickname: string | null;
  birthDate: string | null;
  image: string | null;
  profileCompleted: boolean;
  onboardingCompleted: boolean;
};

function isPrismaUniqueConstraintError(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code?: unknown }).code === "P2002"
  );
}

function toUserProfileDTO(user: {
  id: string;
  email: string | null;
  name: string | null;
  firstName: string | null;
  lastName: string | null;
  nickname: string | null;
  birthDate: Date | null;
  image: string | null;
  profileCompletedAt: Date | null;
  onboardingCompletedAt: Date | null;
}): UserProfileDTO {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    firstName: user.firstName,
    lastName: user.lastName,
    nickname: user.nickname,
    birthDate: user.birthDate?.toISOString().slice(0, 10) ?? null,
    image: user.image,
    profileCompleted: Boolean(user.profileCompletedAt),
    onboardingCompleted: Boolean(user.onboardingCompletedAt)
  };
}

async function assertNicknameAvailableForUser(nickname: string, userId: string): Promise<void> {
  const existingUser = await prisma.user.findUnique({
    where: {
      nickname
    },
    select: {
      id: true
    }
  });

  if (existingUser && existingUser.id !== userId) {
    throw new AppError({
      code: "CONFLICT",
      message: "Este nickname já está em uso.",
      statusCode: 409
    });
  }
}

export async function getUserProfile(userId: string): Promise<UserProfileDTO> {
  const user = await prisma.user.findUnique({
    where: {
      id: userId
    },
    select: {
      id: true,
      email: true,
      name: true,
      firstName: true,
      lastName: true,
      nickname: true,
      birthDate: true,
      image: true,
      profileCompletedAt: true,
      onboardingCompletedAt: true
    }
  });

  if (!user) {
    throw new AppError({
      code: "NOT_FOUND",
      message: "Usuário não encontrado.",
      statusCode: 404
    });
  }

  return toUserProfileDTO(user);
}

export async function completeUserOnboarding(
  userId: string,
  input: CompleteUserProfileInput
): Promise<UserProfileDTO> {
  const nickname = normalizeNickname(input.nickname);

  await assertNicknameAvailableForUser(nickname, userId);

  try {
    const user = await prisma.user.update({
      where: {
        id: userId
      },
      data: {
        firstName: input.firstName.trim(),
        lastName: input.lastName.trim(),
        nickname,
        birthDate: parseBirthDateAsUtcDate(input.birthDate),
        name: buildFullName(input),
        profileCompletedAt: new Date(),
        onboardingCompletedAt: new Date()
      },
      select: {
        id: true,
        email: true,
        name: true,
        firstName: true,
        lastName: true,
        nickname: true,
        birthDate: true,
        image: true,
        profileCompletedAt: true,
        onboardingCompletedAt: true
      }
    });

    return toUserProfileDTO(user);
  } catch (error) {
    if (isPrismaUniqueConstraintError(error)) {
      throw new AppError({
        code: "CONFLICT",
        message: "Este nickname já está em uso.",
        statusCode: 409
      });
    }

    throw error;
  }
}

export async function updateUserProfile(
  userId: string,
  input: UpdateUserProfileInput
): Promise<UserProfileDTO> {
  const nickname = normalizeNickname(input.nickname);

  await assertNicknameAvailableForUser(nickname, userId);

  try {
    const user = await prisma.user.update({
      where: {
        id: userId
      },
      data: {
        firstName: input.firstName.trim(),
        lastName: input.lastName.trim(),
        nickname,
        birthDate: parseBirthDateAsUtcDate(input.birthDate),
        name: buildFullName(input),
        profileCompletedAt: new Date()
      },
      select: {
        id: true,
        email: true,
        name: true,
        firstName: true,
        lastName: true,
        nickname: true,
        birthDate: true,
        image: true,
        profileCompletedAt: true,
        onboardingCompletedAt: true
      }
    });

    return toUserProfileDTO(user);
  } catch (error) {
    if (isPrismaUniqueConstraintError(error)) {
      throw new AppError({
        code: "CONFLICT",
        message: "Este nickname já está em uso.",
        statusCode: 409
      });
    }

    throw error;
  }
}
