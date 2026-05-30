# Convenções Globais — Simulador Copa 2026

## Código

- TypeScript strict sempre que possível.
- Campos TypeScript em camelCase.
- Nomes de services com intenção clara e verbos quando executam ações.
- Server Actions com nomes verbais claros.
- Regras sensíveis sempre validadas no backend.
- Não duplicar regras críticas em frontend, Socket.io e backend.

## Prisma e banco

- Models Prisma em PascalCase.
- Tabelas PostgreSQL em snake_case e plural quando aplicável.
- Usar @@map para mapear nome real da tabela.
- Colunas PostgreSQL em snake_case.
- Usar @map quando o campo Prisma camelCase divergir da coluna.
- Integridade deve ser protegida com constraints, índices únicos e transações.

## Socket.io

- Eventos em snake_case.
- Todo evento deve estar em `lib/contracts/socketEvents.ts`.
- Handlers Socket.io não devem conter regra de consenso.
- Handlers devem chamar services centralizados.

## Rotas

- Rotas em kebab-case quando necessário.
- App Router como padrão.
- Route groups podem ser usados para organizar áreas como `(auth)`.

## Dados oficiais

- Dados oficiais devem ser versionados.
- Não inventar grupos, chaveamento, matriz de terceiros ou slots oficiais.
- Placeholders devem ter TODO explícito.
- Placeholders oficiais não podem rodar em produção.