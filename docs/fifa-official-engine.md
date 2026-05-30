# Bloco 14 — Motor FIFA oficial

## Fonte

Este bloco implementa regras baseadas no regulamento oficial `FWC26_regulations_EN.pdf`.

## Implementado

- Cálculo de team conduct score:
  - amarelo: -1;
  - vermelho indireto: -3;
  - vermelho direto: -4;
  - amarelo + vermelho direto: -5.
- Classificação de grupos com:
  - pontos;
  - saldo;
  - gols pró;
  - confronto direto para times ainda empatados;
  - team conduct;
  - ranking FIFA atual;
  - rankings FIFA anteriores.
- Seleção dos classificados:
  - 1º e 2º de cada um dos 12 grupos;
  - 8 melhores terceiros.
- Ordenação dos terceiros por:
  - pontos;
  - saldo;
  - gols pró;
  - team conduct;
  - ranking FIFA atual;
  - rankings FIFA anteriores.
- Estrutura dos 16-avos conforme Artigo 12.6.
- Guard para matriz oficial Annexe C.

## Não implementado ainda

O Annexe C possui 495 combinações. Este bloco não inventa a matriz completa.

A função `resolveThirdPlaceAssignments` exige que regras oficiais sejam carregadas em dados versionados. Sem isso, ela bloqueia a resolução do chaveamento dependente dos terceiros.
