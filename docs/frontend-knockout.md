# Bloco 10 — Frontend do mata-mata

## Objetivo

Criar uma experiência mobile first para previsões individuais do mata-mata.

## Componentes criados

- `KnockoutPhaseLabel`
- `KnockoutSlotCard`
- `KnockoutPhaseSection`
- `KnockoutLegend`

## Regras preservadas

- Nenhuma regra oficial de chaveamento é inventada no frontend.
- Slots exibem status de dados oficiais.
- Backend continua bloqueando placeholders em produção.
- Palpites são salvos por Server Action já validada no backend.

## Observações

O layout organiza slots por fase:

- 16-avos;
- oitavas;
- quartas;
- semifinais;
- disputa de 3º lugar;
- final.
