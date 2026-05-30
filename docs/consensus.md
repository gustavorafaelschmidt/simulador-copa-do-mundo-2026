# Bloco 6 — Consenso de equipe

## Objetivo

Centralizar a regra de consenso de equipe antes da integração Socket.io.

## Regras

- `CAPTAIN` abre votação.
- `CAPTAIN` fecha votação.
- `CAPTAIN` aplica voto de minerva.
- Membro só vota se estiver aprovado.
- Voto usa `upsert`.
- Socket.io não replica regra de negócio; apenas chama estes services.

## Consenso

- Maioria simples por posição.
- Empate no topo exige `TIEBREAKER_REQUIRED`.
- Seleção inconsistente com equipe duplicada também exige voto de minerva.
