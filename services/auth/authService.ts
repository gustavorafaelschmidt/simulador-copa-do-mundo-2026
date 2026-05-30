import { prisma } from "@/lib/db/prisma";
import { AppError } from "@/lib/errors/AppError";
import { hashPassword, verifyPassword } from "@/lib/auth/password";
import type {
  LoginWithCredentialsInput,
  RegisterWithCredentialsInput
} from "@/lib/validations/auth";

type RegisteredUserResult = {
  id: string;
  email: string;
};

function isPrismaUniqueConstraintError(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code?: unknown }).code === "P2002"
  );
}

export async function registerUserWithCredentials(
  input: RegisterWithCredentialsInput
): Promise<RegisteredUserResult> {
  const email = input.email.toLowerCase();
  const nickname = input.nickname.trim();

  const existingUser = await prisma.user.findFirst({
    where: {
      OR: [{ email }, { nickname }]
    },
    select: {
      email: true,
      nickname: true
    }
  });

  if (existingUser?.email === email) {
    throw new AppError({
      code: "CONFLICT",
      message: "Já existe uma conta cadastrada com este email.",
      statusCode: 409
    });
  }

  if (existingUser?.nickname === nickname) {
    throw new AppError({
      code: "CONFLICT",
      message: "Este nickname já está em uso.",
      statusCode: 409
    });
  }

  const passwordHash = await hashPassword(input.password);
  const fullName = `${input.firstName.trim()} ${input.lastName.trim()}`;
  const completedAt = new Date();

  try {
    const user = await prisma.user.create({
      data: {
        name: fullName,
        firstName: input.firstName.trim(),
        lastName: input.lastName.trim(),
        nickname,
        birthDate: new Date(`${input.birthDate}T00:00:00.000Z`),
        email,
        passwordHash,
        primaryAuthProvider: "CREDENTIALS",
        profileCompletedAt: completedAt,
        onboardingCompletedAt: completedAt
      },
      select: {
        id: true,
        email: true
      }
    });

    if (!user.email) {
      throw new AppError({
        code: "INTERNAL_ERROR",
        message: "Usuário criado sem email. Verifique a modelagem de autenticação.",
        statusCode: 500
      });
    }

    return {
      id: user.id,
      email: user.email
    };
  } catch (error) {
    if (isPrismaUniqueConstraintError(error)) {
      throw new AppError({
        code: "CONFLICT",
        message: "Email ou nickname já está em uso.",
        statusCode: 409
      });
    }

    throw error;
  }
}

export async function validateCredentials(input: LoginWithCredentialsInput) {
  const user = await prisma.user.findUnique({
    where: {
      email: input.email.toLowerCase()
    },
    select: {
      id: true,
      email: true,
      name: true,
      image: true,
      passwordHash: true,
      globalRole: true,
      primaryAuthProvider: true,
      profileCompletedAt: true,
      onboardingCompletedAt: true
    }
  });

  if (!user?.passwordHash) {
    return null;
  }

  const passwordMatches = await verifyPassword(input.password, user.passwordHash);

  if (!passwordMatches) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    name: user.name,
    image: user.image,
    globalRole: user.globalRole,
    primaryAuthProvider: user.primaryAuthProvider,
    profileCompleted: Boolean(user.profileCompletedAt),
    onboardingCompleted: Boolean(user.onboardingCompletedAt)
  };
}
