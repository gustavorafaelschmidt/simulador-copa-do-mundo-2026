# Bloco 13 — Gamificação, badges e estatísticas globais

## Objetivo

Adicionar uma camada inicial de gamificação com badges e estatísticas globais.

## Badges iniciais

- `FIRST_GROUP_PREDICTION`
- `ALL_GROUPS_PREDICTED`
- `FIRST_TEAM_CREATED`
- `FIRST_TEAM_JOINED`
- `FIRST_TEAM_CONSENSUS`
- `FIRST_RANKING_POINTS`

## Regras

A avaliação de badges é idempotente:

- usa `upsert`;
- respeita badge única por usuário;
- não duplica conquistas.

## Estatísticas globais

Snapshots agregam:

- usuários;
- equipes;
- previsões individuais;
- consensos;
- resultados reais;
- snapshots de ranking;
- taxa simples de engajamento.

## Próximos passos

- Criar badges por equipe.
- Criar eventos de notificação em tempo real.
- Evoluir estatísticas para gráficos.
