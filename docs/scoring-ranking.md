# Bloco 11 — Pontuação e rankings

## Objetivo

Criar a fundação de pontuação, ranking individual, ranking por equipes e recálculo idempotente.

## Regras de pontuação

As regras de pontuação são regras de gamificação do produto, não regras oficiais FIFA.

Pontuação inicial:

- 1º colocado exato do grupo: 10 pontos;
- 2º colocado exato do grupo: 10 pontos;
- 3º colocado exato do grupo: 8 pontos;
- 4º colocado exato do grupo: 5 pontos;
- seleção classificada em posição diferente: 3 pontos;
- vencedor de confronto de mata-mata: 15 pontos.

## Resultados reais esperados

`RealTournamentResult.payload` para grupo:

```json
{
  "orderedTeamIds": ["team_1", "team_2", "team_3", "team_4"]
}
```

`RealTournamentResult.payload` para mata-mata:

```json
{
  "winnerTeamId": "team_1"
}
```

## Ranking individual

Usa previsões individuais salvas em:

- `IndividualGroupPrediction`;
- `IndividualKnockoutPrediction`.

## Ranking por equipes

Usa consensos salvos em:

- `TeamGroupConsensus`;
- `TeamKnockoutConsensus`.

## Idempotência

`RankingRecalculationJob.idempotencyKey` impede execução duplicada para a mesma chave.

Se o job já foi concluído, o mesmo snapshot é retornado.
