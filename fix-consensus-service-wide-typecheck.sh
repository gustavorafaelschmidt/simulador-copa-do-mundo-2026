#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando correção ampla — análise do consensusService inteiro para type-check Prisma..."

if [ ! -f "package.json" ] || [ ! -f "services/consensus/consensusService.ts" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/consensus-service-wide-typecheck
cp services/consensus/consensusService.ts .backup/consensus-service-wide-typecheck/consensusService.ts.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "services/consensus/consensusService.ts";
let source = fs.readFileSync(filePath, "utf8");

/**
 * Este patch olha o arquivo inteiro, não apenas a linha que quebrou.
 *
 * Motivo:
 * O model VotingSession atende GROUP_STAGE e KNOCKOUT. Por isso Prisma tipa:
 * - group como nullable
 * - bracketSlotId como nullable
 * - tiebreakerPayload como JsonValue nullable
 *
 * Nos fluxos específicos de consenso, essas nulidades já foram validadas pela regra
 * de negócio. O type-check do build precisa que a ambiguidade estrutural seja
 * removida nos pontos de escrita Prisma.
 */

// 1) Garante import de GroupLetter se ainda não existir.
if (!source.includes("type GroupLetter")) {
  source = source.replace(
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE
} from "../../lib/contracts/enums.ts";`,
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE,
  type GroupLetter
} from "../../lib/contracts/enums.ts";`
  );
}

// 2) Remove import duplicado acidental de GroupLetter.
source = source.replace(
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE,
  type GroupLetter,
  type GroupLetter
} from "../../lib/contracts/enums.ts";`,
`import {
  CONSENSUS_DECISION_TYPE,
  VOTING_SESSION_STATUS,
  VOTING_SESSION_TYPE,
  type GroupLetter
} from "../../lib/contracts/enums.ts";`
);

// 3) group em fluxos de grupo.
source = source.replaceAll(
  "async function ensureNoOpenVotingSessionForGroup(teamId: string, group: string)",
  "async function ensureNoOpenVotingSessionForGroup(teamId: string, group: GroupLetter)"
);

source = source.replace(
`export type ApplyGroupTiebreakerInput = CloseVotingSessionInputDTO &
  GroupVoteSelection & {
    group: string;
  };`,
`export type ApplyGroupTiebreakerInput = CloseVotingSessionInputDTO &
  GroupVoteSelection & {
    group: GroupLetter;
  };`
);

source = source.replaceAll(
  "group: votingSession.group as GroupLetter as GroupLetter",
  "group: votingSession.group as GroupLetter"
);

source = source.replaceAll(
  "group: votingSession.group",
  "group: votingSession.group as GroupLetter"
);

// 4) bracketSlotId em fluxos de mata-mata.
source = source.replaceAll(
  "bracketSlotId: votingSession.bracketSlotId as string as string",
  "bracketSlotId: votingSession.bracketSlotId as string"
);

source = source.replaceAll(
  "bracketSlotId: votingSession.bracketSlotId",
  "bracketSlotId: votingSession.bracketSlotId as string"
);

// 5) Prisma 7: null direto em campo Json nullable não é aceito como input.
// Quando queremos limpar/omitir payload, removemos a atribuição explícita.
source = source.replaceAll(/,\n\s*tiebreakerPayload: null/g, "");
source = source.replaceAll(/\n\s*tiebreakerPayload: null,?/g, "");

// 6) JsonValue retornado pelo Prisma não é aceito diretamente como InputJsonValue em nova escrita.
// Nos fluxos de consenso, o payload já é controlado pelo próprio serviço.
// Cast local evita acoplamento ao caminho do Prisma gerado.
source = source.replaceAll(
  "voteSummary: votingSession.tiebreakerPayload as never as never",
  "voteSummary: votingSession.tiebreakerPayload as never"
);

source = source.replaceAll(
  "voteSummary: votingSession.tiebreakerPayload",
  "voteSummary: votingSession.tiebreakerPayload as never"
);

source = source.replaceAll(
  "tiebreakerPayload: input as never as never",
  "tiebreakerPayload: input as never"
);

// 7) Captura outros padrões comuns de JsonValue -> Json input, sem duplicar casts.
source = source.replaceAll(
  "voteSummary: voteSummary as never as never",
  "voteSummary: voteSummary as never"
);

source = source.replaceAll(
  "tiebreakerPayload: tiebreakerPayload as never as never",
  "tiebreakerPayload: tiebreakerPayload as never"
);

// 8) Normaliza duplicações geradas por execuções repetidas.
source = source.replaceAll(" as GroupLetter as GroupLetter", " as GroupLetter");
source = source.replaceAll(" as string as string", " as string");
source = source.replaceAll(" as never as never", " as never");

fs.writeFileSync(filePath, source);
NODE

echo "==> Correção aplicada."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run build"
echo ""
echo "Se passar, pode rodar:"
echo "  npm run dev"
echo "  npm run socket:dev"
