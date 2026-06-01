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

        <form action={loginWithCredentialsAction as unknown as (formData: FormData) => Promise<void>} className="mt-6 space-y-4">
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

        <form action={signInWithGoogleAction as unknown as (formData: FormData) => Promise<void>} className="mt-3">
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
