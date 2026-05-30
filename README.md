# Simulador da Copa do Mundo 2026

Aplicação web gamificada para simular a Copa do Mundo FIFA 2026 em modo individual e em equipes privadas, com votação em tempo real, consenso por maioria, rankings globais, estatísticas, gamificação e painel administrativo para resultados reais.

Este repositório está sendo construído por blocos. O Bloco 0 prepara apenas a fundação técnica do projeto.

## Stack

- Next.js com App Router
- React
- TypeScript strict
- Node.js
- Express
- Socket.io
- PostgreSQL
- Prisma ORM
- TailwindCSS
- Zod
- Auth.js / NextAuth v5 futuramente
- ESLint
- Prettier
- Vitest

## Regras importantes

- Não usar Sequelize.
- Não duplicar regras críticas.
- Regras sensíveis devem ser validadas no backend.
- Socket.io deve chamar services centralizados.
- Lógica de consenso deve ser criada antes dos handlers Socket.io finais.
- Eventos Socket.io devem ser declarados em `lib/contracts/socketEvents.ts`.
- Dados oficiais da Copa devem ser versionados.
- Não inventar regras oficiais da Copa.
- Placeholders oficiais não podem operar em produção.

## Instalação

```bash
npm install