# Bloco 12 — Painel administrativo de resultados reais

## Objetivo

Permitir que administradores globais cadastrem resultados reais da Copa para alimentar pontuação e rankings.

## Tipos de payload suportados

### Classificação de grupo

```json
{
  "orderedTeamIds": ["team_1", "team_2", "team_3", "team_4"]
}
```

### Resultado de mata-mata

```json
{
  "winnerTeamId": "team_1"
}
```

## Segurança

- A página exige `ADMIN_GLOBAL`.
- A Server Action chama `requireAdminGlobalUser`.
- O payload é validado no backend.
- Resultados são salvos como `OFFICIAL`.
- O recálculo de ranking usa jobs idempotentes.

## Observação

Esse painel não substitui importador oficial de dados FIFA. Ele é a camada administrativa operacional para resultados reais.
