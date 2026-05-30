# Banco de Dados — Bloco 1

Este documento descreve a fundação de banco de dados do Simulador da Copa do Mundo 2026.

## Objetivo

Modelar a base inicial para:

- usuários;
- Auth.js / NextAuth v5;
- sessões validáveis pelo servidor Socket.io;
- equipes privadas;
- membros e permissões;
- convites;
- dados oficiais versionados;
- previsões individuais;
- votos de equipe;
- consensos de equipe;
- resultados reais;
- rankings;
- badges;
- estatísticas globais;
- auditoria.

## Convenções

- Models Prisma em PascalCase.
- Tabelas PostgreSQL em snake_case e plural.
- Campos Prisma/TypeScript em camelCase.
- Colunas PostgreSQL em snake_case.
- Uso de `@map` e `@@map`.
- Regras críticas protegidas por constraints.
- Regras sensíveis também validadas no backend.
- Não usar Sequelize.

## Relações principais

```txt
User
 ├─ Account
 ├─ Session
 ├─ TeamMember ── Team ── TeamInvite
 │                  ├─ VotingSession
 │                  │   ├─ TeamGroupVote
 │                  │   ├─ TeamKnockoutVote
 │                  │   ├─ TeamGroupConsensus
 │                  │   └─ TeamKnockoutConsensus
 │                  ├─ TeamBadge
 │                  └─ RankingEntry
 ├─ IndividualGroupPrediction
 ├─ IndividualKnockoutPrediction
 ├─ UserBadge
 ├─ RankingEntry
 └─ AuditLog

OfficialDataVersion
 ├─ TournamentGroup
 │   ├─ NationalTeam
 │   └─ OfficialMatch
 ├─ OfficialBracketSlot
 ├─ OfficialThirdPlaceMatrixRule
 └─ RealTournamentResult

RankingRecalculationJob
 └─ RankingSnapshot
     └─ RankingEntry

Badge
 ├─ UserBadge
 └─ TeamBadge