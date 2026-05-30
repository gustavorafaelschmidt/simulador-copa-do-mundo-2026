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
