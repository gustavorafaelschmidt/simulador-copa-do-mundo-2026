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
