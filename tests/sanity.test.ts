import { describe, expect, it } from "vitest";
import { AppError } from "@/lib/errors/AppError";
import { success, unauthorized } from "@/lib/errors/actionResponses";

describe("sanity", () => {
  it("deve executar o ambiente de testes", () => {
    expect(1 + 1).toBe(2);
  });

  it("deve criar um AppError estruturado", () => {
    const appError = new AppError({
      code: "VALIDATION_ERROR",
      message: "Dados inválidos.",
      statusCode: 422
    });

    expect(appError.code).toBe("VALIDATION_ERROR");
    expect(appError.statusCode).toBe(422);
    expect(appError.message).toBe("Dados inválidos.");
  });

  it("deve retornar respostas padronizadas de Server Actions", () => {
    expect(success({ id: "test" })).toEqual({
      ok: true,
      data: {
        id: "test"
      }
    });

    expect(unauthorized()).toEqual({
      ok: false,
      error: {
        code: "UNAUTHORIZED",
        message: "Autenticação obrigatória.",
        statusCode: 401
      }
    });
  });
});