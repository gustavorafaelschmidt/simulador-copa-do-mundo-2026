# Bloco 8 — Previsões individuais

## Objetivo

Permitir que usuários autenticados salvem previsões individuais de fase de grupos e mata-mata.

## Fase de grupos

O usuário seleciona:

- 1º colocado;
- 2º colocado;
- 3º colocado.

O backend calcula automaticamente o 4º colocado a partir das quatro seleções do grupo.

## Mata-mata

O usuário escolhe um vencedor por slot de mata-mata.

Enquanto os dados oficiais não estiverem completos, slots podem existir como placeholders em desenvolvimento. Em produção, o guard de dados oficiais bloqueia uso incorreto.

## Integridade

- Uma previsão de grupo por usuário/grupo.
- Uma previsão de mata-mata por usuário/slot.
- Upsert para permitir edição antes do bloqueio.
- `PREDICTIONS_LOCKED=true` bloqueia novas alterações.
