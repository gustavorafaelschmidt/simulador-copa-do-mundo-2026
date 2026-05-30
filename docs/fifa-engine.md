# Bloco 5 — Fundação do Motor FIFA

## Objetivo

Criar a base do motor FIFA sem inventar regras oficiais da Copa do Mundo 2026.

## O que este bloco faz

- Cria tipos puros em `lib/fifa/types.ts`.
- Cria guards para impedir uso incorreto de dados oficiais incompletos.
- Cria helpers para validar escolhas completas de grupo.
- Cria helpers para extrair classificados e terceiros colocados a partir de previsões.
- Cria guards para slots oficiais e matriz dos terceiros colocados.
- Cria service inicial para consultar readiness dos dados oficiais.

## O que este bloco não faz

- Não escolhe os 8 melhores terceiros.
- Não resolve a matriz oficial dos terceiros colocados.
- Não monta chaveamento oficial de 16-avos.
- Não calcula critérios reais de desempate da FIFA.
- Não usa placeholders como regra oficial.

## Regra crítica

Qualquer função que dependa de chaveamento oficial deve exigir dados com:

```txt
OfficialDataStatus.OFFICIAL
officialDataVersionId preenchido
```

Em produção, placeholders não podem operar como dados oficiais.

## Próximos passos

Quando documentos oficiais forem fornecidos, os dados serão importados para:

- `OfficialDataVersion`;
- `TournamentGroup`;
- `NationalTeam`;
- `OfficialMatch`;
- `OfficialBracketSlot`;
- `OfficialThirdPlaceMatrixRule`.
