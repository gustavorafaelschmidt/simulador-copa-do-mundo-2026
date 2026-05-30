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
