#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando Bloco 16 — onboarding, perfil, configurações e proxy do Next..."

if [ ! -f "package.json" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p services/user
mkdir -p actions
mkdir -p components/forms
mkdir -p components/navigation
mkdir -p app/onboarding
mkdir -p app/configuracoes/perfil
mkdir -p docs
mkdir -p tests

cat > lib/validations/profile.ts <<'EOF'
import { z } from "zod";
import { nicknameSchema } from "./common.ts";

export const completeUserProfileSchema = z.object({
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
  birthDate: z.string().date("Data de nascimento inválida.")
});

export const updateUserProfileSchema = completeUserProfileSchema;

export type CompleteUserProfileInput = z.infer<typeof completeUserProfileSchema>;
export type UpdateUserProfileInput = z.infer<typeof updateUserProfileSchema>;
EOF

cat > services/user/profileUtils.ts <<'EOF'
import type { CompleteUserProfileInput } from "../../lib/validations/profile.ts";

export function buildFullName(input: Pick<CompleteUserProfileInput, "firstName" | "lastName">): string {
  return `${input.firstName.trim()} ${input.lastName.trim()}`.replace(/\s+/g, " ");
}

export function normalizeNickname(nickname: string): string {
  return nickname.trim();
}

export function parseBirthDateAsUtcDate(birthDate: string): Date {
  return new Date(`${birthDate}T00:00:00.000Z`);
}

export function isProfileComplete(user: {
  firstName?: string | null;
  lastName?: string | null;
  nickname?: string | null;
  birthDate?: Date | string | null;
  profileCompletedAt?: Date | string | null;
  onboardingCompletedAt?: Date | string | null;
}): boolean {
  return Boolean(
    user.firstName &&
      user.lastName &&
      user.nickname &&
      user.birthDate &&
      user.profileCompletedAt &&
      user.onboardingCompletedAt
  );
}
EOF

cat > services/user/userProfileService.ts <<'EOF'
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
EOF

cat > services/user/index.ts <<'EOF'
export * from "./profileUtils.ts";
export * from "./userProfileService.ts";
EOF

cat > actions/profile.ts <<'EOF'
"use server";

import { revalidatePath } from "next/cache";
import type { ActionResult } from "../lib/contracts/actionResult.ts";
import { APP_ROUTES } from "../lib/contracts/routes.ts";
import {
  error as actionError,
  success,
  validationError
} from "../lib/errors/actionResponses.ts";
import { requireCurrentUser } from "../lib/auth/currentUser";
import {
  completeUserProfileSchema,
  updateUserProfileSchema
} from "../lib/validations/profile.ts";
import {
  completeUserOnboarding,
  updateUserProfile
} from "../services/user/userProfileService.ts";

function formDataToObject(formData: FormData): Record<string, FormDataEntryValue> {
  return Object.fromEntries(formData.entries());
}

export async function completeOnboardingAction(
  formData: FormData
): Promise<ActionResult<{ redirectTo: string }>> {
  const user = await requireCurrentUser();
  const parsedInput = completeUserProfileSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de onboarding inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    await completeUserOnboarding(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.ONBOARDING);
    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      redirectTo: APP_ROUTES.DASHBOARD
    });
  } catch (error) {
    return actionError(error);
  }
}

export async function updateProfileAction(
  formData: FormData
): Promise<ActionResult<{ profileUpdated: true }>> {
  const user = await requireCurrentUser();
  const parsedInput = updateUserProfileSchema.safeParse(formDataToObject(formData));

  if (!parsedInput.success) {
    return validationError("Dados de perfil inválidos.", parsedInput.error.flatten().fieldErrors);
  }

  try {
    await updateUserProfile(user.id, parsedInput.data);

    revalidatePath(APP_ROUTES.SETTINGS_PROFILE);
    revalidatePath(APP_ROUTES.DASHBOARD);

    return success({
      profileUpdated: true
    });
  } catch (error) {
    return actionError(error);
  }
}
EOF

node <<'NODE'
const fs = require("node:fs");

const routesPath = "lib/contracts/routes.ts";
let source = fs.readFileSync(routesPath, "utf8");

const replacements = [
  ['SETTINGS: "/configuracoes",', 'SETTINGS: "/configuracoes",\n  SETTINGS_PROFILE: "/configuracoes/perfil",'],
  ['ONBOARDING: "/onboarding",', 'ONBOARDING: "/onboarding",']
];

for (const [needle, replacement] of replacements) {
  if (source.includes(needle) && !source.includes("SETTINGS_PROFILE")) {
    source = source.replace(needle, replacement);
  }
}

fs.writeFileSync(routesPath, source);
NODE

cat > components/forms/ProfileForm.tsx <<'EOF'
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
EOF

cat > components/navigation/AppNav.tsx <<'EOF'
import Link from "next/link";
import { APP_ROUTES } from "../../lib/contracts/routes.ts";

const navigationItems = [
  ["Dashboard", APP_ROUTES.DASHBOARD],
  ["Previsões", APP_ROUTES.PREDICTIONS],
  ["Equipes", APP_ROUTES.TEAMS],
  ["Ranking", APP_ROUTES.RANKING_INDIVIDUAL],
  ["Gamificação", APP_ROUTES.GAMIFICATION],
  ["Perfil", APP_ROUTES.SETTINGS_PROFILE]
] as const;

export function AppNav() {
  return (
    <nav className="border-b border-app-border bg-app-surface">
      <div className="mx-auto flex max-w-6xl gap-2 overflow-x-auto px-4 py-3">
        {navigationItems.map(([label, href]) => (
          <Link
            className="shrink-0 rounded-full border border-app-border px-4 py-2 text-sm font-semibold text-app-muted transition hover:border-app-primary hover:text-app-primary"
            href={href}
            key={href}
          >
            {label}
          </Link>
        ))}
      </div>
    </nav>
  );
}
EOF

cat > app/onboarding/page.tsx <<'EOF'
import { completeOnboardingAction } from "../../actions/profile.ts";
import { ProfileForm } from "../../components/forms/ProfileForm.tsx";
import { requireCurrentUser } from "../../lib/auth/currentUser";
import { getUserProfile } from "../../services/user/userProfileService.ts";

export default async function OnboardingPage() {
  const user = await requireCurrentUser();
  const profile = await getUserProfile(user.id);

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-2xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Onboarding
        </p>

        <h1 className="mt-3 text-2xl font-bold">Complete seu perfil</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Precisamos desses dados para liberar o dashboard, rankings e participação em
          equipes. Cadastros via Google podem não retornar todas as informações obrigatórias.
        </p>

        <div className="mt-6">
          <ProfileForm
            action={completeOnboardingAction}
            profile={profile}
            submitLabel="Concluir onboarding"
          />
        </div>
      </section>
    </main>
  );
}
EOF

cat > app/configuracoes/page.tsx <<'EOF'
import Link from "next/link";
import { APP_ROUTES } from "../../lib/contracts/routes.ts";
import { requireCurrentUser } from "../../lib/auth/currentUser";

export default async function SettingsPage() {
  await requireCurrentUser();

  return (
    <main className="min-h-dvh bg-app-bg px-4 py-8">
      <section className="mx-auto max-w-3xl rounded-app border border-app-border bg-app-surface p-6 shadow-app">
        <p className="text-sm font-semibold uppercase tracking-wide text-app-primary">
          Configurações
        </p>

        <h1 className="mt-3 text-2xl font-bold">Minha conta</h1>

        <p className="mt-3 text-sm leading-6 text-app-muted">
          Gerencie suas informações pessoais e preferências da plataforma.
        </p>

        <div className="mt-6">
          <Link
            className="inline-flex rounded-xl bg-app-primary px-4 py-3 font-semibold text-white"
            href={APP_ROUTES.SETTINGS_PROFILE}
          >
            Editar perfil
          </Link>
        </div>
      </section>
    </main>
  );
}
EOF

cat > app/configuracoes/perfil/page.tsx <<'EOF'
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
EOF

cat > proxy.ts <<'EOF'
export { default, config } from "./middleware.ts";
EOF

cat > docs/onboarding-profile.md <<'EOF'
# Bloco 16 — Onboarding e perfil

## Objetivo

Finalizar a base de onboarding e edição de perfil.

## Regras

- Usuário autenticado precisa completar perfil antes do dashboard.
- O cadastro via Google pode não retornar nome, nickname ou data de nascimento.
- O backend exige:
  - nome;
  - sobrenome;
  - nickname único;
  - data de nascimento.
- Onboarding grava `profileCompletedAt` e `onboardingCompletedAt`.
- Edição de perfil mantém a regra de nickname único.

## Next.js proxy

Foi criado `proxy.ts` reexportando a regra atual de `middleware.ts` para compatibilidade progressiva com a convenção nova do Next.
EOF

cat > tests/profile.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import {
  buildFullName,
  isProfileComplete,
  normalizeNickname,
  parseBirthDateAsUtcDate
} from "../services/user/profileUtils.ts";
import { completeUserProfileSchema } from "../lib/validations/profile.ts";

describe("profile and onboarding", () => {
  it("deve montar nome completo normalizado", () => {
    expect(buildFullName({ firstName: " Gustavo ", lastName: " Schmidt " })).toBe(
      "Gustavo Schmidt"
    );
  });

  it("deve normalizar nickname", () => {
    expect(normalizeNickname(" mestre_2026 ")).toBe("mestre_2026");
  });

  it("deve converter data de nascimento para UTC", () => {
    expect(parseBirthDateAsUtcDate("2000-01-01").toISOString()).toBe(
      "2000-01-01T00:00:00.000Z"
    );
  });

  it("deve validar payload completo de perfil", () => {
    const result = completeUserProfileSchema.safeParse({
      firstName: "Gustavo",
      lastName: "Schmidt",
      nickname: "gustavo_2026",
      birthDate: "2000-01-01"
    });

    expect(result.success).toBe(true);
  });

  it("deve rejeitar nickname inválido", () => {
    const result = completeUserProfileSchema.safeParse({
      firstName: "Gustavo",
      lastName: "Schmidt",
      nickname: "x",
      birthDate: "2000-01-01"
    });

    expect(result.success).toBe(false);
  });

  it("deve identificar perfil completo", () => {
    expect(
      isProfileComplete({
        firstName: "Gustavo",
        lastName: "Schmidt",
        nickname: "gustavo_2026",
        birthDate: "2000-01-01",
        profileCompletedAt: "2026-01-01",
        onboardingCompletedAt: "2026-01-01"
      })
    ).toBe(true);
  });
});
EOF

echo "==> Bloco 16 aplicado."
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
echo "  git commit -m \"feat: add onboarding and profile management\""
echo "  git push"
