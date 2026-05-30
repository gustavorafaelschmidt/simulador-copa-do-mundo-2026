# Bloco 4 — Equipes privadas

## Objetivo

Implementar a fundação de equipes privadas, membros, convites e permissões.

## Regras implementadas

- Usuário autenticado pode criar equipe.
- Criador da equipe vira `CAPTAIN`.
- `CAPTAIN` nasce aprovado automaticamente.
- Equipe recebe `inviteCode` único.
- Convite inicial é criado com o mesmo código da equipe.
- Usuário pode solicitar entrada por código.
- Solicitação entra como `PENDING`.
- Apenas `CAPTAIN` pode aprovar ou rejeitar membros.
- Apenas `CAPTAIN` pode alterar papel entre `ADMIN` e `MEMBER`.
- `CAPTAIN` não pode ser removido por esta ação.
- `CAPTAIN` não pode ser atribuído por alteração comum de papel.

## Pontos críticos

A autoridade do capitão é central para os próximos blocos:

- abrir votação;
- fechar votação;
- aplicar voto de minerva.

Essas ações ainda não foram implementadas neste bloco.

## Concorrência e integridade

O banco já possui constraint única:

```txt
teamId + userId
```

Isso impede que o mesmo usuário entre duas vezes na mesma equipe.

## Próximos passos

- Bloco de consenso deve importar `assertTeamCaptain`.
- Socket.io não deve validar regra de capitão manualmente.
- Socket.io deve chamar services centralizados.
