#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando ajuste — mata-mata com bolinhas de bandeira, sem nomes nas chaves..."

if [ ! -f "package.json" ] || [ ! -f "components/world-cup/VisualWorldCupSimulator.tsx" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-23-flag-only-bracket docs
cp components/world-cup/VisualWorldCupSimulator.tsx .backup/block-23-flag-only-bracket/VisualWorldCupSimulator.tsx.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
let source = fs.readFileSync(filePath, "utf8");

source = source.replace(
`const roundGapClasses: Record<"round32" | "round16" | "quarterFinals" | "semiFinals", string> = {
  round32: "gap-3",
  round16: "gap-8 pt-8",
  quarterFinals: "gap-20 pt-20",
  semiFinals: "gap-44 pt-40"
};`,
`const roundGapClasses: Record<"round32" | "round16" | "quarterFinals" | "semiFinals", string> = {
  round32: "gap-3",
  round16: "gap-9 pt-8",
  quarterFinals: "gap-24 pt-22",
  semiFinals: "gap-52 pt-44"
};`
);

const newBracketBlock = String.raw`function BracketFlagButton({
  team,
  selected,
  disabled,
  onClick
}: {
  team: VisualDemoTeam | null;
  selected: boolean;
  disabled: boolean;
  onClick: () => void;
}) {
  return (
    <button
      aria-label={team ? \`Selecionar \${team.name}\` : "Seleção indefinida"}
      className={\`group relative grid size-10 place-items-center rounded-full border-2 bg-white shadow-[0_10px_24px_rgba(15,23,42,0.10)] transition \${
        selected
          ? "border-[#06a641] ring-4 ring-[#06a641]/15"
          : "border-slate-200 hover:border-[#06a641]/70 hover:ring-4 hover:ring-[#06a641]/10"
      } \${disabled ? "cursor-not-allowed opacity-35" : "cursor-pointer"}\`}
      disabled={disabled}
      onClick={onClick}
      title={team?.name ?? "A definir"}
      type="button"
    >
      {team ? (
        <TeamFlag
          className="h-6 w-8 rounded-full border-0 shadow-none"
          team={team}
        />
      ) : (
        <span className="size-6 rounded-full bg-slate-100" />
      )}

      {selected ? (
        <span className="absolute -right-1 -top-1 grid size-5 place-items-center rounded-full bg-[#06a641] text-[10px] font-black text-white shadow-sm">
          ✓
        </span>
      ) : null}
    </button>
  );
}

function MatchupLabel({ match }: { match: VisualBracketMatch }) {
  return (
    <span className="inline-flex max-w-[58px] items-center justify-center truncate rounded-full bg-slate-100 px-1.5 py-0.5 text-[7px] font-black uppercase tracking-[0.04em] text-slate-400">
      J{match.matchNumber} · {match.homeToken}×{match.awayToken}
    </span>
  );
}

function BracketMatchCard({
  match,
  side,
  pickedTeamId,
  onPick
}: {
  match: VisualBracketMatch;
  side: "left" | "right";
  pickedTeamId?: string;
  onPick: (matchId: string, teamId: string) => void;
}) {
  const selectedTeam =
    pickedTeamId === match.homeTeam?.id
      ? match.homeTeam
      : pickedTeamId === match.awayTeam?.id
        ? match.awayTeam
        : null;

  return (
    <article className="relative flex w-[68px] flex-col items-center rounded-[24px] border border-slate-200 bg-white/95 px-1.5 py-2 shadow-[0_12px_30px_rgba(15,23,42,0.08)] backdrop-blur">
      <MatchupLabel match={match} />

      <div className="mt-1.5 flex flex-col items-center gap-1.5">
        <BracketFlagButton
          disabled={!match.homeTeam}
          onClick={() => match.homeTeam && onPick(match.id, match.homeTeam.id)}
          selected={pickedTeamId === match.homeTeam?.id}
          team={match.homeTeam}
        />
        <BracketFlagButton
          disabled={!match.awayTeam}
          onClick={() => match.awayTeam && onPick(match.id, match.awayTeam.id)}
          selected={pickedTeamId === match.awayTeam?.id}
          team={match.awayTeam}
        />
      </div>

      <span className={\`mt-1 text-[7px] font-black uppercase tracking-[0.06em] \${
        selectedTeam ? "text-[#06a641]" : "text-slate-300"
      }\`}>
        {selectedTeam ? "OK" : "Clique"}
      </span>
    </article>
  );
}

function RoundColumn({
  matches,
  roundKey,
  side,
  bracketPicks,
  onPick
}: {
  matches: VisualBracketMatch[];
  roundKey: "round32" | "round16" | "quarterFinals" | "semiFinals";
  side: "left" | "right";
  bracketPicks: VisualBracketPicks;
  onPick: (matchId: string, teamId: string) => void;
}) {
  return (
    <div
      className={\`relative flex min-h-[650px] flex-col \${roundGapClasses[roundKey]} \${
        side === "right" ? "items-end" : "items-start"
      }\`}
    >
      {matches.map((match) => (
        <BracketMatchCard
          key={match.id}
          match={match}
          onPick={onPick}
          pickedTeamId={bracketPicks[match.id]}
          side={side}
        />
      ))}
    </div>
  );
}

function BracketLines() {
  return (
    <div aria-hidden="true" className="pointer-events-none absolute inset-0 opacity-50">
      <div className="absolute left-[9%] top-[12%] h-[76%] border-l border-dashed border-slate-200" />
      <div className="absolute left-[20%] top-[18%] h-[64%] border-l border-dashed border-slate-200" />
      <div className="absolute left-[31%] top-[28%] h-[44%] border-l border-dashed border-slate-200" />
      <div className="absolute left-[42%] top-[40%] h-[20%] border-l border-dashed border-slate-200" />

      <div className="absolute right-[9%] top-[12%] h-[76%] border-l border-dashed border-slate-200" />
      <div className="absolute right-[20%] top-[18%] h-[64%] border-l border-dashed border-slate-200" />
      <div className="absolute right-[31%] top-[28%] h-[44%] border-l border-dashed border-slate-200" />
      <div className="absolute right-[42%] top-[40%] h-[20%] border-l border-dashed border-slate-200" />

      <div className="absolute left-[8%] right-[8%] top-1/2 border-t border-dashed border-slate-200" />
    </div>
  );
}

function FinalFlagButton({
  team,
  selected,
  onClick
}: {
  team: VisualDemoTeam | null;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      aria-label={team ? \`Selecionar \${team.name} como campeã\` : "Finalista indefinido"}
      className={\`relative grid size-12 place-items-center rounded-full border-2 bg-white shadow-[0_14px_30px_rgba(15,23,42,0.12)] transition \${
        selected
          ? "border-[#06a641] ring-4 ring-[#06a641]/15"
          : "border-slate-200 hover:border-[#06a641]"
      } \${!team ? "cursor-not-allowed opacity-35" : ""}\`}
      disabled={!team}
      onClick={onClick}
      title={team?.name ?? "A definir"}
      type="button"
    >
      {team ? (
        <TeamFlag
          className="h-7 w-9 rounded-full border-0 shadow-none"
          team={team}
        />
      ) : (
        <span className="size-7 rounded-full bg-slate-100" />
      )}

      {selected ? (
        <span className="absolute -right-1 -top-1 grid size-5 place-items-center rounded-full bg-[#06a641] text-[10px] font-black text-white shadow-sm">
          ✓
        </span>
      ) : null}
    </button>
  );
}

function InteractiveBracket({
  rounds,
  bracketPicks = {},
  champion,
  onPick
}: {
  rounds: Record<VisualBracketRoundKey, VisualBracketMatch[]>;
  bracketPicks?: VisualBracketPicks;
  champion: VisualDemoTeam | null;
  onPick: (matchId: string, teamId: string) => void;
}) {
  const leftRound32 = rounds.round32.slice(0, 8);
  const rightRound32 = rounds.round32.slice(8);
  const leftRound16 = rounds.round16.slice(0, 4);
  const rightRound16 = rounds.round16.slice(4);
  const leftQuarterFinals = rounds.quarterFinals.slice(0, 2);
  const rightQuarterFinals = rounds.quarterFinals.slice(2);
  const leftSemiFinal = rounds.semiFinals.slice(0, 1);
  const rightSemiFinal = rounds.semiFinals.slice(1);
  const finalMatch = rounds.final[0];

  return (
    <section className="rounded-[34px] border border-slate-200 bg-gradient-to-b from-white to-slate-50 px-4 py-8 shadow-[0_22px_70px_rgba(15,23,42,0.08)]">
      <div className="mb-8 flex flex-col items-start justify-between gap-4 md:flex-row md:items-end">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.24em] text-[#06a641]">
            Mata-mata
          </p>
          <h2 className="mt-1 text-3xl font-black text-slate-900">Espião</h2>
          <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-slate-500">
            Clique nas bandeiras para escolher os vencedores de cada confronto.
          </p>
        </div>

        <div className="rounded-full bg-[#06a641]/10 px-4 py-2 text-xs font-black uppercase tracking-[0.14em] text-[#047a31]">
          Layout espelhado
        </div>
      </div>

      <div className="-mx-4 overflow-x-auto px-4 pb-4">
        <div className="relative mx-auto min-h-[740px] w-[920px] rounded-[30px] bg-white/60 px-5 py-8">
          <BracketLines />

          <div className="absolute inset-x-5 inset-y-8 grid grid-cols-[1fr_150px_1fr] gap-4">
            <div className="grid grid-cols-4 gap-3">
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={leftRound32}
                onPick={onPick}
                roundKey="round32"
                side="left"
              />
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={leftRound16}
                onPick={onPick}
                roundKey="round16"
                side="left"
              />
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={leftQuarterFinals}
                onPick={onPick}
                roundKey="quarterFinals"
                side="left"
              />
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={leftSemiFinal}
                onPick={onPick}
                roundKey="semiFinals"
                side="left"
              />
            </div>

            <div className="flex flex-col items-center justify-center">
              <span className="mb-3 text-[10px] font-black uppercase tracking-[0.26em] text-slate-400">
                Final
              </span>

              <div className="grid size-24 place-items-center rounded-full border border-slate-200 bg-white text-4xl shadow-[0_16px_44px_rgba(15,23,42,0.08)]">
                🏆
              </div>

              <div className="mt-4 rounded-full bg-[#06a641] px-5 py-2 text-center text-[10px] font-black uppercase tracking-[0.16em] text-white shadow-[0_14px_30px_rgba(6,166,65,0.22)]">
                Campeã
              </div>

              <div className="mt-4 flex items-center justify-center gap-3">
                {finalMatch ? (
                  <>
                    <FinalFlagButton
                      onClick={() => finalMatch.homeTeam && onPick(finalMatch.id, finalMatch.homeTeam.id)}
                      selected={bracketPicks[finalMatch.id] === finalMatch.homeTeam?.id}
                      team={finalMatch.homeTeam}
                    />
                    <FinalFlagButton
                      onClick={() => finalMatch.awayTeam && onPick(finalMatch.id, finalMatch.awayTeam.id)}
                      selected={bracketPicks[finalMatch.id] === finalMatch.awayTeam?.id}
                      team={finalMatch.awayTeam}
                    />
                  </>
                ) : null}
              </div>

              <p className="mt-4 max-w-[145px] truncate text-center text-xs font-black text-slate-800">
                {champion ? champion.name : "A definir"}
              </p>
            </div>

            <div className="grid grid-cols-4 gap-3">
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={rightSemiFinal}
                onPick={onPick}
                roundKey="semiFinals"
                side="right"
              />
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={rightQuarterFinals}
                onPick={onPick}
                roundKey="quarterFinals"
                side="right"
              />
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={rightRound16}
                onPick={onPick}
                roundKey="round16"
                side="right"
              />
              <RoundColumn
                bracketPicks={bracketPicks}
                matches={rightRound32}
                onPick={onPick}
                roundKey="round32"
                side="right"
              />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-5 gap-2 border-t border-slate-200 pt-4 text-center text-[10px] font-black uppercase tracking-[0.14em] text-slate-400">
        <span>{roundLabels.round32}</span>
        <span>{roundLabels.round16}</span>
        <span>{roundLabels.quarterFinals}</span>
        <span>{roundLabels.semiFinals}</span>
        <span>{roundLabels.final}</span>
      </div>
    </section>
  );
}

`;

source = source.replace(
  /function BracketTeamButton[\s\S]*?function QualifiedStrip/,
  `${newBracketBlock}function QualifiedStrip`
);

source = source.replace(
  /function BracketFlagButton[\s\S]*?function QualifiedStrip/,
  `${newBracketBlock}function QualifiedStrip`
);

if (!source.includes("function BracketFlagButton")) {
  throw new Error("Novo bracket flag-only não foi aplicado.");
}

if (source.includes("max-w-[90px]") || source.includes("max-w-[68px]")) {
  throw new Error("Ainda existem nomes visíveis dos times nos botões do mata-mata.");
}

fs.writeFileSync(filePath, source);
NODE

cat > docs/flag-only-bracket.md <<'EOF'
# Ajuste — Mata-mata com bandeiras

## Entrega

- Remove nomes visíveis das seleções dentro das chaves.
- Mantém nomes apenas como `title`/`aria-label` para acessibilidade.
- Reduz rótulos dos jogos para formato compacto.
- Reduz largura total do bracket.
- Mantém botões arredondados e visual moderno.
EOF

echo "==> Ajuste aplicado."
echo ""
echo "Agora rode:"
echo "  npm run lint"
echo "  npm run test"
echo "  npm run db:generate"
echo "  npm run db:seed"
echo "  npm run build"
echo "  npm run dev"
echo ""
echo "Depois commit:"
echo "  git status"
echo "  git add ."
echo "  git commit -m \"style: simplify knockout bracket with flag-only buttons\""
echo "  git push"
