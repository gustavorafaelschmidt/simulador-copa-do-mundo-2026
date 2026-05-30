# Bloco 7 — Socket.io

## Objetivo

Conectar o servidor Socket.io aos services centralizados de consenso.

## Regra arquitetural

Handlers Socket.io não implementam regra de negócio sensível.

Eles apenas:

1. autenticam a conexão;
2. validam payloads com Zod;
3. chamam services;
4. emitem eventos para rooms;
5. retornam ACK padronizado.

## Autenticação

O servidor Socket.io lê o token Auth.js/NextAuth por cookie usando `getToken`.

## Rooms

- `team:{teamId}`
- `voting_session:{votingSessionId}`

## Eventos de entrada

Os nomes continuam centralizados em:

```txt
lib/contracts/socketEvents.ts
```

## Eventos de saída

- `voting_status_updated`
- `group_vote_updated`
- `knockout_vote_updated`
- `tiebreaker_required`
- `voting_closed`
- `socket_error`

## Pontos futuros

- O front ainda precisa de client Socket.io.
- O resumo de votos em tempo real ainda está como `null`.
- O evento `consensus_defined` será usado quando o service retornar o consenso serializado.
