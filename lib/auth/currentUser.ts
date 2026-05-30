import { auth } from "@/auth";
import { GLOBAL_ROLE } from "@/lib/contracts/enums";
import { AppError } from "@/lib/errors/AppError";

export async function getCurrentSession() {
  return auth();
}

export async function getCurrentUser() {
  const session = await auth();

  return session?.user ?? null;
}

export async function requireCurrentUser() {
  const user = await getCurrentUser();

  if (!user) {
    throw new AppError({
      code: "UNAUTHORIZED",
      message: "Autenticação obrigatória.",
      statusCode: 401
    });
  }

  return user;
}

export async function requireAdminGlobalUser() {
  const user = await requireCurrentUser();

  if (user.globalRole !== GLOBAL_ROLE.ADMIN_GLOBAL) {
    throw new AppError({
      code: "FORBIDDEN",
      message: "Acesso restrito a administradores globais.",
      statusCode: 403
    });
  }

  return user;
}
