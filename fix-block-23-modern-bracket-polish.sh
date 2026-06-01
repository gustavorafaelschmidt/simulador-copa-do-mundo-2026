#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando ajuste — mata-mata espelhado moderno, arredondado e mais compacto..."

if [ ! -f "package.json" ] || [ ! -f "components/world-cup/VisualWorldCupSimulator.tsx" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-23-modern-bracket-polish docs
cp components/world-cup/VisualWorldCupSimulator.tsx .backup/block-23-modern-bracket-polish/VisualWorldCupSimulator.tsx.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
let source = fs.readFileSync(filePath, "utf8");

// Ajusta espaçamentos do bracket para ficar mais coeso.
source = source.replace(
`const roundGapClasses: Record<"round32" | "round16" | "quarterFinals" | "semiFinals", string> = {
  round32: "gap-3",
  round16: "gap-10 pt-7",
  quarterFinals: "gap-24 pt-20",
  semiFinals: "gap-52 pt-44"
};`,
`const roundGapClasses: Record<"round32" | "round16" | "quarterFinals" | "semiFinals", string> = {
  round32: "gap-3",
  round16: "gap-8 pt-8",
  quarterFinals: "gap-20 pt-20",
  semiFinals: "gap-44 pt-40"
};`
);

const newBracketBlock = `function BracketTeamButton({
  team,
  selected,
  disabled,
  onClick,
  side,
  compact = false
}: {
  team: VisualDemoTeam | null;
  selected: boolean;
  disabled: boolean;
  onClick: () => void;
  side: "left" | "right";
  compact?: boolean;
}) {
  return (
    <button
      className={\`group flex w-full items-center justify-between gap-2 rounded-full border px-2 py-1.5 text-left transition \${
        selected
          ? "border-[#06a641] bg-[#06a641] text-white shadow-[0_10px_24px_rgba(6,166,65,0.22)]"
          : "border-slate-200 bg-white text-slate-700 shadow-sm hover:border-[#06a641]/60 hover:bg-[#06a641]/5"
      } \${disabled ? "cursor-not-allowed opacity-45" : "cursor-pointer"} \${side === "right" ? "flex-row-reverse text-right" : ""}\`}
      disabled={disabled}
      onClick={onClick}
      type="button"
    >
      <span className={\`flex min-w-0 items-center gap-2 \${side === "right" ? "flex-row-reverse" : ""}\`}>
        {team ? <TeamFlag team={team} /> : (
          <span className="grid h-4 w-6 shrink-0 place-items-center rounded-full border border-slate-200 bg-slate-50" />
        )}
        <span className={\`min-w-0 truncate font-bold \${compact ? "max-w-[68px] text-[10px]" : "max-w-[90px] text-[11px]"}\`}>
          {team?.name ?? "A definir"}
        </span>
      </span>

      <span
        className={\`grid size-5 shrink-0 place-items-center rounded-full text-[10px] font-black \${
          selected ? "bg-white text-[#06a641]" : "bg-slate-100 text-[#06a641]"
        }\`}
      >
        {selected ? "✓" : "›"}
      </span>
    </button>
  );
}

function MatchupLabel({ match }: { match: VisualBracketMatch }) {
  return (
    <span className="inline-flex max-w-full items-center justify-center rounded-full bg-slate-100 px-2 py-0.5 text-[8px] font-black uppercase tracking-[0.08em] text-slate-400">
      Jogo {match.matchNumber} · {match.homeToken} × {match.awayToken}
    </span>
  );
}

function BracketMatchCard({
  match,
  side,
  pickedTeamId,
  onPick,
  compact = false
}: {
  match: VisualBracketMatch;
  side: "left" | "right";
  pickedTeamId?: string;
  onPick: (matchId: string, teamId: string) => void;
  compact?: boolean;
}) {
  const selectedTeam =
    pickedTeamId === match.homeTeam?.id
      ? match.homeTeam
      : pickedTeamId === match.awayTeam?.id
        ? match.awayTeam
        : null;

  return (
    <article
      className={\`relative rounded-[22px] border border-slate-200 bg-white/95 p-2 shadow-[0_12px_34px_rgba(15,23,42,0.08)] backdrop-blur \${compact ? "w-[132px]" : "w-[156px]"}\`}
    >
      <div className={\`mb-1.5 flex \${side === "right" ? "justify-end" : "justify-start"}\`}>
        <MatchupLabel match={match} />
      </div>

      <div className="space-y-1.5">
        <BracketTeamButton
          compact={compact}
          disabled={!match.homeTeam}
          onClick={() => match.homeTeam && onPick(match.id, match.homeTeam.id)}
          selected={pickedTeamId === match.homeTeam?.id}
          side={side}
          team={match.homeTeam}
        />
        <BracketTeamButton
          compact={compact}
          disabled={!match.awayTeam}
          onClick={() => match.awayTeam && onPick(match.id, match.awayTeam.id)}
          selected={pickedTeamId === match.awayTeam?.id}
          side={side}
          team={match.awayTeam}
        />
      </div>

      <p
        className={\`mt-1.5 truncate text-[9px] font-black uppercase tracking-[0.08em] \${
          selectedTeam ? "text-[#06a641]" : "text-slate-300"
        } \${side === "right" ? "text-right" : "text-left"}\`}
      >
        {selectedTeam ? selectedTeam.name : "Clique"}
      </p>
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
  const compact = roundKey !== "round32";

  return (
    <div
      className={\`relative flex min-h-[650px] flex-col \${roundGapClasses[roundKey]} \${
        side === "right" ? "items-end" : "items-start"
      }\`}
    >
      {matches.map((match) => (
        <BracketMatchCard
          compact={compact}
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
    <div aria-hidden="true" className="pointer-events-none absolute inset-0 opacity-55">
      <div className="absolute left-[10%] top-[12%] h-[76%] border-l border-dashed border-slate-200" />
      <div className="absolute left-[22%] top-[18%] h-[64%] border-l border-dashed border-slate-200" />
      <div className="absolute left-[34%] top-[27%] h-[46%] border-l border-dashed border-slate-200" />
      <div className="absolute left-[45%] top-[39%] h-[22%] border-l border-dashed border-slate-200" />

      <div className="absolute right-[10%] top-[12%] h-[76%] border-l border-dashed border-slate-200" />
      <div className="absolute right-[22%] top-[18%] h-[64%] border-l border-dashed border-slate-200" />
      <div className="absolute right-[34%] top-[27%] h-[46%] border-l border-dashed border-slate-200" />
      <div className="absolute right-[45%] top-[39%] h-[22%] border-l border-dashed border-slate-200" />

      <div className="absolute left-[9%] right-[9%] top-1/2 border-t border-dashed border-slate-200" />
    </div>
  );
}

function FinalTeamButton({
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
      className={\`flex w-full items-center justify-center gap-2 rounded-full border px-3 py-2 text-xs font-black transition ${
        selected
          ? "border-[#06a641] bg-[#06a641] text-white shadow-[0_14px_30px_rgba(6,166,65,0.24)]"
          : "border-slate-200 bg-white text-slate-500 hover:border-[#06a641] hover:text-[#047a31]"
      }\`}
      disabled={!team}
      onClick={onClick}
      type="button"
    >
      {team ? <TeamFlag team={team} /> : null}
      <span className="truncate">{team?.name ?? "A definir"}</span>
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
            Clique nos vencedores de cada confronto para avançar os times até a final.
          </p>
        </div>

        <div className="rounded-full bg-[#06a641]/10 px-4 py-2 text-xs font-black uppercase tracking-[0.14em] text-[#047a31]">
          Layout espelhado
        </div>
      </div>

      <div className="-mx-4 overflow-x-auto px-4 pb-4">
        <div className="relative mx-auto min-h-[740px] w-[1120px] rounded-[30px] bg-white/60 px-4 py-8">
          <BracketLines />

          <div className="absolute inset-x-4 inset-y-8 grid grid-cols-[1fr_180px_1fr] gap-5">
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

              <div className="grid size-28 place-items-center rounded-full border border-slate-200 bg-white text-5xl shadow-[0_16px_44px_rgba(15,23,42,0.08)]">
                🏆
              </div>

              <div className="mt-4 rounded-full bg-[#06a641] px-5 py-2 text-center text-xs font-black uppercase tracking-[0.16em] text-white shadow-[0_14px_30px_rgba(6,166,65,0.22)]">
                Campeã
              </div>

              <div className="mt-4 flex w-full flex-col gap-2">
                {finalMatch ? (
                  <>
                    <FinalTeamButton
                      onClick={() => finalMatch.homeTeam && onPick(finalMatch.id, finalMatch.homeTeam.id)}
                      selected={bracketPicks[finalMatch.id] === finalMatch.homeTeam?.id}
                      team={finalMatch.homeTeam}
                    />
                    <FinalTeamButton
                      onClick={() => finalMatch.awayTeam && onPick(finalMatch.id, finalMatch.awayTeam.id)}
                      selected={bracketPicks[finalMatch.id] === finalMatch.awayTeam?.id}
                      team={finalMatch.awayTeam}
                    />
                  </>
                ) : null}
              </div>

              <p className="mt-4 max-w-[170px] text-center text-sm font-black text-slate-800">
                {champion ? `${champion.flag} ${champion.name}` : "A definir"}
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
  /function BracketTeamCircle[\s\S]*?function QualifiedStrip/,
  `${newBracketBlock}function QualifiedStrip`
);

// Segurança contra sobras antigas.
source = source.replaceAll("function WinnerNode", "function RemovedWinnerNode");
source = source.replaceAll("function BracketMatchNode", "function RemovedBracketMatchNode");

if (!source.includes("function BracketTeamButton")) {
  throw new Error("Novo botão moderno do mata-mata não foi aplicado.");
}

if (!source.includes("rounded-[34px] border border-slate-200")) {
  throw new Error("Novo wrapper moderno do mata-mata não foi aplicado.");
}

fs.writeFileSync(filePath, source);
NODE

cat > docs/modern-bracket-polish.md <<'EOF'
# Ajuste — Mata-mata moderno

## Entrega

- Mantém o formato espelhado do mata-mata.
- Troca círculos soltos por cards/botões arredondados.
- Diminui rótulos dos jogos.
- Reduz largura e altura do bracket.
- Melhora gaps e alinhamento para preenchimento.
- Mantém os grupos em 3 colunas com card polido.
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
echo "  git commit -m \"style: polish mirrored knockout bracket\""
echo "  git push"
