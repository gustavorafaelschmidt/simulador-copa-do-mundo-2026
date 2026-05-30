# Bloco 15 — Importador oficial FIFA

## Objetivo

Criar uma esteira controlada para importar dados oficiais versionados.

## Manifesto

O manifesto contém:

- versão/fonte;
- grupos;
- seleções;
- partidas;
- slots oficiais;
- matriz dos terceiros colocados.

## Proteções

Em produção:

- `status` precisa ser `OFFICIAL`;
- precisa conter 48 seleções;
- a matriz dos terceiros colocados precisa conter as 495 combinações do Annexe C.

## Observação

Este bloco não extrai automaticamente dados do PDF. Ele define o formato seguro de entrada e impede que placeholders sejam usados como dados oficiais em produção.
