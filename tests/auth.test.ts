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
