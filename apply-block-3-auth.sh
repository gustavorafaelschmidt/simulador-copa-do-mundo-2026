#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 3 — Auth.js/NextAuth v5, cadastro, login e onboarding..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p app/api/auth/'[...nextauth]'
mkdir -p app/'(auth)'/entrar
mkdir -p app/'(auth)'/cadastro
mkdir -p app/dashboard
mkdir -p app/onboarding
mkdir -p actions
mkdir -p services/auth
mkdir -p lib/auth
mkdir -p lib/validations
mkdir -p tests
mkdir -p types

cat > lib/validations/auth.ts <<'EOF'
import { z } from "zod";
import { nicknameSchema } from "@/lib/validations/common";

export const emailSchema = z
  .string()
  .trim()
  .email("Email inválido.")
  .max(254, "Email muito longo.")
  .transform((value) => value.toLowerCase());

export const passwordSchema = z
  .string()
  .min(8, "Senha deve ter pelo menos 8 caracteres.")
  .max(128, "Senha deve ter no máximo 128 caracteres.")
  .regex(/[A-Z]/, "Senha deve conter pelo menos uma letra maiúscula.")
  .regex(/[a-z]/, "Senha deve conter pelo menos uma letra minúscula.")
  .regex(/[0-9]/, "Senha deve conter pelo menos um número.");

export const registerWithCredentialsSchema = z
  .object({
    firstName: z
      .string()
      .trim()
      .min(2, "Nome deve ter pelo menos 2 caracteres.")
      .max(80, "Nome deve ter no máximo 80 caracteres."),
    lastName: z
      .string()
      .trim()
      .min(2, "Sobrenome deve ter pelo menos 2 caracteres.")
      .max(120, "Sobrenome deve ter no máximo 120 caracteres."),
    nickname: nicknameSchema,
    birthDate: z.string().date("Data de nascimento inválida."),
    email: emailSchema,
    password: passwordSchema,
    confirmPassword: z.string().min(1, "Confirmação de senha obrigatória.")
  })
  .refine((data) => data.password === data.confirmPassword, {
    path: ["confirmPassword"],
    message: "As senhas não conferem."
  });

export const loginWithCredentialsSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, "Senha obrigatória.")
});

export type RegisterWithCredentialsInput = z.infer<typeof registerWithCredentialsSchema>;
export type LoginWithCredentialsInput = z.infer<typeof loginWithCredentialsSchema>;
EOF

cat > lib/auth/password.ts <<'EOF'
import { randomBytes, scrypt as scryptCallback, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";

const scrypt = promisify(scryptCallback);

const PASSWORD_HASH_ALGORITHM = "scrypt";
const SALT_LENGTH_BYTES = 16;
const KEY_LENGTH_BYTES = 64;

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(SALT_LENGTH_BYTES).toString("hex");
  const derivedKey = (await scrypt(password, salt, KEY_LENGTH_BYTES)) as Buffer;

  return `${PASSWORD_HASH_ALGORITHM}:${salt}:${derivedKey.toString("hex")}`;
}

export async function verifyPassword(password: string, storedPasswordHash: string): Promise<boolean> {
  const [algorithm, salt, storedKey] = storedPasswordHash.split(":");

  if (algorithm !== PASSWORD_HASH_ALGORITHM || !salt || !storedKey) {
    return false;
  }

  const storedKeyBuffer = Buffer.from(storedKey, "hex");
  const derivedKey = (await scrypt(password, salt, storedKeyBuffer.length)) as Buffer;

  if (storedKeyBuffer.length !== derivedKey.length) {
    return false;
  }

  return timingSafeEqual(storedKeyBuffer, derivedKey);
}
EOF

cat > services/auth/authService.ts <<'EOF'
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
EOF

cat > auth.ts <<'EOF'
import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import Credentials from "next-auth/providers/credentials";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { prisma } from "@/lib/db/prisma";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { loginWithCredentialsSchema } from "@/lib/validations/auth";
import { validateCredentials } from "@/services/auth/authService";

const providers = [
  Credentials({
    id: "credentials",
    name: "Email e senha",
    credentials: {
      email: {
        label: "Email",
        type: "email"
      },
      password: {
        label: "Senha",
        type: "password"
      }
    },
    async authorize(credentials) {
      const parsedCredentials = loginWithCredentialsSchema.safeParse(credentials);

      if (!parsedCredentials.success) {
        return null;
      }

      const user = await validateCredentials(parsedCredentials.data);

      if (!user) {
        return null;
      }

      return {
        id: user.id,
        email: user.email,
        name: user.name,
        image: user.image,
        globalRole: user.globalRole,
        primaryAuthProvider: user.primaryAuthProvider,
        profileCompleted: user.profileCompleted,
        onboardingCompleted: user.onboardingCompleted
      };
    }
  }),
  ...(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET
    ? [
        Google({
          clientId: process.env.GOOGLE_CLIENT_ID,
          clientSecret: process.env.GOOGLE_CLIENT_SECRET
        })
      ]
    : [])
];

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  secret: process.env.AUTH_SECRET ?? process.env.NEXTAUTH_SECRET,
  trustHost: true,
  session: {
    /*
      Credentials Provider funciona de forma mais previsível com JWT.
      A tabela sessions permanece modelada para compatibilidade com Auth.js
      e para evolução futura de validação direta pelo servidor Socket.io.
    */
    strategy: "jwt"
  },
  pages: {
    signIn: APP_ROUTES.LOGIN
  },
  providers,
  callbacks: {
    async signIn({ user, account }) {
      if (account?.provider === "google" && user.id) {
        await prisma.user.update({
          where: {
            id: user.id
          },
          data: {
            primaryAuthProvider: "GOOGLE",
            name: user.name ?? undefined,
            image: user.image ?? undefined
          }
        });
      }

      return true;
    },

    async jwt({ token, user }) {
      const userId = user?.id ?? token.userId;

      if (!userId) {
        return token;
      }

      const dbUser = await prisma.user.findUnique({
        where: {
          id: String(userId)
        },
        select: {
          id: true,
          globalRole: true,
          primaryAuthProvider: true,
          profileCompletedAt: true,
          onboardingCompletedAt: true
        }
      });

      if (!dbUser) {
        return token;
      }

      token.userId = dbUser.id;
      token.globalRole = dbUser.globalRole;
      token.primaryAuthProvider = dbUser.primaryAuthProvider;
      token.profileCompleted = Boolean(dbUser.profileCompletedAt);
      token.onboardingCompleted = Boolean(dbUser.onboardingCompletedAt);

      return token;
    },

    async session({ session, token }) {
      if (session.user) {
        session.user.id = String(token.userId);
        session.user.globalRole = token.globalRole ?? "USER";
        session.user.primaryAuthProvider = token.primaryAuthProvider ?? "CREDENTIALS";
        session.user.profileCompleted = Boolean(token.profileCompleted);
        session.user.onboardingCompleted = Boolean(token.onboardingCompleted);
      }

      return session;
    }
  }
});
EOF

cat > app/api/auth/'[...nextauth]'/route.ts <<'EOF'
import { handlers } from "@/auth";

export const { GET, POST } = handlers;
EOF

cat > types/next-auth.d.ts <<'EOF'
import type { DefaultSession } from "next-auth";
import type { AuthProvider, GlobalRole } from "@/lib/contracts/enums";

declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      globalRole: GlobalRole;
      primaryAuthProvider: AuthProvider;
      profileCompleted: boolean;
      onboardingCompleted: boolean;
    } & DefaultSession["user"];
  }

  interface User {
    globalRole?: GlobalRole;
    primaryAuthProvider?: AuthProvider;
    profileCompleted?: boolean;
    onboardingCompleted?: boolean;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    userId?: string;
    globalRole?: GlobalRole;
    primaryAuthProvider?: AuthProvider;
    profileCompleted?: boolean;
    onboardingCompleted?: boolean;
  }
}
EOF

cat > lib/auth/currentUser.ts <<'EOF'
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
EOF

cat > actions/auth.ts <<'EOF'
"use server";

import { AuthError } from "next-auth";
import { signIn, signOut } from "@/auth";
import { APP_ROUTES } from "@/lib/contracts/routes";
import type { ActionResult } from "@/lib/contracts/actionResult";
import { error as actionError, success, validationError } from "@/lib/errors/actionResponses";
import {
  loginWithCredentialsSchema,
  registerWithCredentialsSchema
} from "@/lib/validations/auth";
import { registerUserWithCredentials } from "@/services/auth/authService";

function formDataToObject(formData: FormData) {
  return Object.fromEntries(formData.entries());
}

export async function registerWithCredentialsAction(
  formData: FormData
): Promise<ActionResult<{ userId: string; redirectTo: string }>> {
  const parsedInput = registerWithCredentialsSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de cadastro inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    const user = await registerUserWithCredentials(parsedInput.data);

    await signIn("credentials", {
      email: parsedInput.data.email,
      password: parsedInput.data.password,
      redirect: false
    });

    return success({
      userId: user.id,
      redirectTo: APP_ROUTES.DASHBOARD
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function loginWithCredentialsAction(
  formData: FormData
): Promise<ActionResult<{ redirectTo: string }>> {
  const parsedInput = loginWithCredentialsSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Credenciais inválidas.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    await signIn("credentials", {
      email: parsedInput.data.email,
      password: parsedInput.data.password,
      redirect: false
    });

    return success({
      redirectTo: APP_ROUTES.DASHBOARD
    });
  } catch (error) {
    if (error instanceof AuthError) {
      return validationError("Email ou senha inválidos.");
    }

    return actionError(error);
  }
}

export async function signInWithGoogleAction(): Promise<void> {
  await signIn("google", {
    redirectTo: APP_ROUTES.DASHBOARD
  });
}

export async function logoutAction(): Promise<void> {
  await signOut({
    redirectTo: APP_ROUTES.HOME
  });
}
EOF

cat > middleware.ts <<'EOF'
import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { GLOBAL_ROLE } from "@/lib/contracts/enums";

const protectedPrefixes = [
  APP_ROUTES.DASHBOARD,
  APP_ROUTES.TEAMS,
  APP_ROUTES.SETTINGS,
  APP_ROUTES.ADMIN,
  APP_ROUTES.ONBOARDING
];

function isProtectedPath(pathname: string) {
  return protectedPrefixes.some((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`));
}

export default auth((request) => {
  const { nextUrl } = request;
  const session = request.auth;

  if (!isProtectedPath(nextUrl.pathname)) {
    return NextResponse.next();
  }

  if (!session?.user) {
    return NextResponse.redirect(new URL(APP_ROUTES.LOGIN, nextUrl));
  }

  const isOnboardingRoute = nextUrl.pathname === APP_ROUTES.ONBOARDING;

  if (!session.user.onboardingCompleted && !isOnboardingRoute) {
    return NextResponse.redirect(new URL(APP_ROUTES.ONBOARDING, nextUrl));
  }

  if (
    nextUrl.pathname.startsWith(APP_ROUTES.ADMIN) &&
    session.user.globalRole !== GLOBAL_ROLE.ADMIN_GLOBAL
  ) {
    return NextResponse.redirect(new URL(APP_ROUTES.DASHBOARD, nextUrl));
  }

  return NextResponse.next();
});

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/equipes/:path*",
    "/configuracoes/:path*",
    "/admin/:path*",
    "/onboarding/:path*"
  ]
};
EOF

cat > app/'(auth)'/entrar/page.tsx <<'EOF'
import Link from "next/link";
import { loginWithCredentialsAction, signInWithGoogleAction } from "@/actions/auth";
import { APP_ROUTES } from "@/lib/contracts/routes";

export default function LoginPage() {
  return (
    <main className="flex min-h-dvh items-center justify-center px-4 py-8">
      <section className="w-full max-w-md rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Simulador Copa 2026
        </p>

        <h1 className="mt-3 text-2xl font-bold">Entrar</h1>

        <form action={loginWithCredentialsAction} className="mt-6 space-y-4">
          <label className="block">
            <span className="text-sm font-medium">Email</span>
            <input
              className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
              type="email"
              name="email"
              autoComplete="email"
              required
            />
          </label>

          <label className="block">
            <span className="text-sm font-medium">Senha</span>
            <input
              className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
              type="password"
              name="password"
              autoComplete="current-password"
              required
            />
          </label>

          <button
            className="w-full rounded-xl bg-app-primary px-4 py-2 font-semibold text-white"
            type="submit"
          >
            Entrar com email
          </button>
        </form>

        <form action={signInWithGoogleAction} className="mt-3">
          <button
            className="w-full rounded-xl border border-app-border px-4 py-2 font-semibold"
            type="submit"
          >
            Entrar com Google
          </button>
        </form>

        <p className="mt-5 text-sm text-app-muted">
          Ainda não tem conta?{" "}
          <Link className="font-semibold text-app-primary" href={APP_ROUTES.REGISTER}>
            Criar cadastro
          </Link>
        </p>
      </section>
    </main>
  );
}
EOF

cat > app/'(auth)'/cadastro/page.tsx <<'EOF'
import Link from "next/link";
import { registerWithCredentialsAction } from "@/actions/auth";
import { APP_ROUTES } from "@/lib/contracts/routes";

export default function RegisterPage() {
  return (
    <main className="flex min-h-dvh items-center justify-center px-4 py-8">
      <section className="w-full max-w-md rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Simulador Copa 2026
        </p>

        <h1 className="mt-3 text-2xl font-bold">Criar cadastro</h1>

        <form action={registerWithCredentialsAction} className="mt-6 space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <label className="block">
              <span className="text-sm font-medium">Nome</span>
              <input
                className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                name="firstName"
                autoComplete="given-name"
                required
              />
            </label>

            <label className="block">
              <span className="text-sm font-medium">Sobrenome</span>
              <input
                className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
                name="lastName"
                autoComplete="family-name"
                required
              />
            </label>
          </div>

          <label className="block">
            <span className="text-sm font-medium">Nickname</span>
            <input
              className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
              name="nickname"
              autoComplete="nickname"
              required
            />
          </label>

          <label className="block">
            <span className="text-sm font-medium">Data de nascimento</span>
            <input
              className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
              type="date"
              name="birthDate"
              required
            />
          </label>

          <label className="block">
            <span className="text-sm font-medium">Email</span>
            <input
              className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
              type="email"
              name="email"
              autoComplete="email"
              required
            />
          </label>

          <label className="block">
            <span className="text-sm font-medium">Senha</span>
            <input
              className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
              type="password"
              name="password"
              autoComplete="new-password"
              required
            />
          </label>

          <label className="block">
            <span className="text-sm font-medium">Confirmar senha</span>
            <input
              className="mt-1 w-full rounded-xl border border-app-border px-3 py-2"
              type="password"
              name="confirmPassword"
              autoComplete="new-password"
              required
            />
          </label>

          <button
            className="w-full rounded-xl bg-app-primary px-4 py-2 font-semibold text-white"
            type="submit"
          >
            Criar conta
          </button>
        </form>

        <p className="mt-5 text-sm text-app-muted">
          Já tem conta?{" "}
          <Link className="font-semibold text-app-primary" href={APP_ROUTES.LOGIN}>
            Entrar
          </Link>
        </p>
      </section>
    </main>
  );
}
EOF

cat > app/dashboard/page.tsx <<'EOF'
import { requireCurrentUser } from "@/lib/auth/currentUser";

export default async function DashboardPage() {
  const user = await requireCurrentUser();

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-4xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Dashboard
        </p>

        <h1 className="mt-3 text-2xl font-bold">Olá, {user.name ?? user.email}</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Autenticação base configurada. Os módulos de bolão, equipes, rankings e
          painel administrativo serão conectados nos próximos blocos.
        </p>
      </section>
    </main>
  );
}
EOF

cat > app/onboarding/page.tsx <<'EOF'
import { requireCurrentUser } from "@/lib/auth/currentUser";

export default async function OnboardingPage() {
  const user = await requireCurrentUser();

  return (
    <main className="min-h-dvh px-4 py-8">
      <section className="mx-auto max-w-3xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Onboarding
        </p>

        <h1 className="mt-3 text-2xl font-bold">Complete seu perfil</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Usuário autenticado: {user.email ?? user.name}. O formulário completo de
          onboarding será implementado no bloco específico de onboarding.
        </p>
      </section>
    </main>
  );
}
EOF

cat > tests/auth.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { hashPassword, verifyPassword } from "@/lib/auth/password";
import {
  loginWithCredentialsSchema,
  registerWithCredentialsSchema
} from "@/lib/validations/auth";

describe("auth", () => {
  it("deve gerar e validar hash de senha", async () => {
    const passwordHash = await hashPassword("Senha123");

    await expect(verifyPassword("Senha123", passwordHash)).resolves.toBe(true);
    await expect(verifyPassword("SenhaErrada123", passwordHash)).resolves.toBe(false);
  });

  it("deve validar payload de cadastro com senha forte", () => {
    const result = registerWithCredentialsSchema.safeParse({
      firstName: "Gustavo",
      lastName: "Schmidt",
      nickname: "gustavo_test",
      birthDate: "2000-01-01",
      email: "GUSTAVO@EXEMPLO.COM",
      password: "Senha123",
      confirmPassword: "Senha123"
    });

    expect(result.success).toBe(true);

    if (result.success) {
      expect(result.data.email).toBe("gustavo@exemplo.com");
    }
  });

  it("deve rejeitar cadastro com confirmação de senha divergente", () => {
    const result = registerWithCredentialsSchema.safeParse({
      firstName: "Gustavo",
      lastName: "Schmidt",
      nickname: "gustavo_test",
      birthDate: "2000-01-01",
      email: "gustavo@exemplo.com",
      password: "Senha123",
      confirmPassword: "Senha456"
    });

    expect(result.success).toBe(false);
  });

  it("deve validar payload de login", () => {
    const result = loginWithCredentialsSchema.safeParse({
      email: "USER@EXEMPLO.COM",
      password: "qualquer-senha"
    });

    expect(result.success).toBe(true);

    if (result.success) {
      expect(result.data.email).toBe("user@exemplo.com");
    }
  });
});
EOF

echo "==> Bloco 3 aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run dev"
echo ""
echo "Em outro terminal:"
echo "  npm run socket:dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"feat: add authentication foundation\""
echo "  git push"
