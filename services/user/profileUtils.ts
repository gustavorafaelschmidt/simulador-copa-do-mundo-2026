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
