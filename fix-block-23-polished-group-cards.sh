#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando ajuste — grupos em 3 colunas com visual antigo mais bonito..."

if [ ! -f "package.json" ] || [ ! -f "components/world-cup/VisualWorldCupSimulator.tsx" ]; then
  echo "ERRO: rode este script na raiz do projeto."
  exit 1
fi

mkdir -p .backup/block-23-groups-old-style
cp components/world-cup/VisualWorldCupSimulator.tsx .backup/block-23-groups-old-style/VisualWorldCupSimulator.tsx.backup

node <<'NODE'
const fs = require("node:fs");

const filePath = "components/world-cup/VisualWorldCupSimulator.tsx";
let source = fs.readFileSync(filePath, "utf8");

const prettyTeamIdentity = `function TeamIdentity({ team }: { team: VisualDemoTeam }) {
  const flagStyle = team.flagImageUrl
    ? {
        backgroundImage: \`url("\${team.flagImageUrl}")\`
      }
    : undefined;

  return (
    <span className="flex min-w-0 items-center gap-2">
      <span
        aria-hidden="true"
        className={\`grid size-8 shrink-0 place-items-center overflow-hidden rounded-full border border-white/70 bg-white text-lg shadow-sm \${team.flagImageUrl ? "bg-cover bg-center bg-no-repeat" : ""}\`}
        style={flagStyle}
      >
        {team.flagImageUrl ? null : team.flag}
      </span>
      <span className="min-w-0">
        <span className="block truncate font-semibold text-slate-900">{team.name}</span>
        <span className="block text-[11px] font-bold uppercase tracking-[0.22em] text-slate-400">
          {team.shortName}
        </span>
      </span>
    </span>
  );
}`;

source = source.replace(
  /function TeamIdentity\(\{ team \}: \{ team: VisualDemoTeam \}\) \{[\s\S]*?\n\}\n\nfunction BracketTeamCircle/,
  `${prettyTeamIdentity}\n\nfunction BracketTeamCircle`
);

const prettyGroupCard = `function GroupCard({
  group,
  pick,
  onChoose,
  onRandomize
}: {
  group: VisualDemoGroup;
  pick: Record<string, string | undefined>;
  onChoose: (position: VisualPickPosition, teamId: string) => void;
  onRandomize: () => void;
}) {
  return (
    <article className="overflow-hidden rounded-[28px] border border-slate-200 bg-white shadow-[0_18px_60px_rgba(15,23,42,0.09)]">
      <header className="flex items-center justify-between bg-[#f4f6f8] px-4 py-3">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-[#06a641]">
            Fase de grupos
          </p>
          <h3 className="text-xl font-black text-slate-950">{group.name}</h3>
        </div>
        <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-slate-500 shadow-sm">
          4 seleções
        </span>
      </header>

      <div className="grid grid-cols-[1fr_44px_44px_44px] items-center border-b border-slate-100 px-4 py-3 text-[11px] font-black uppercase tracking-[0.16em] text-slate-400">
        <span>Seleção</span>
        <span className="text-center">1º</span>
        <span className="text-center">2º</span>
        <span className="text-center">3º</span>
      </div>

      <div className="divide-y divide-slate-100">
        {group.teams.map((team) => {
          const selectedPosition = positionConfig.find(([key]) => pick[key] === team.id)?.[0];

          return (
            <div
              className={\`grid grid-cols-[1fr_44px_44px_44px] items-center gap-1 px-4 py-3 transition \${
                selectedPosition ? "bg-emerald-50/70" : "bg-white"
              }\`}
              key={team.id}
            >
              <TeamIdentity team={team} />

              {positionConfig.map(([key, label]) => {
                const selected = pick[key] === team.id;

                return (
                  <button
                    aria-label={\`\${team.name} como \${label} colocado do \${group.name}\`}
                    className={\`mx-auto grid size-9 place-items-center rounded-full border text-sm font-black transition \${
                      selected
                        ? "border-[#06a641] bg-[#06a641] text-white shadow-[0_8px_22px_rgba(6,166,65,0.3)]"
                        : "border-slate-200 bg-slate-50 text-slate-400 hover:border-[#06a641] hover:text-[#047a31]"
                    }\`}
                    key={key}
                    onClick={() => onChoose(key, team.id)}
                    title={label}
                    type="button"
                  >
                    {selected ? "✓" : label}
                  </button>
                );
              })}
            </div>
          );
        })}
      </div>

      <footer className="border-t border-slate-100 bg-slate-50/80 px-4 py-3">
        <button
          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-black uppercase text-slate-700 transition hover:border-[#06a641] hover:text-[#047a31]"
          onClick={onRandomize}
          type="button"
        >
          Sorteio aleatório
        </button>
      </footer>
    </article>
  );
}`;

source = source.replace(
  /function GroupCard\([\s\S]*?\n\}\n\nfunction MatchupLabel/,
  `${prettyGroupCard}\n\nfunction MatchupLabel`
);

// Mantém 3 grupos lado a lado no desktop, mas com espaçamento compatível com o card antigo.
source = source.replace(
  'className="grid gap-x-3 gap-y-6 md:grid-cols-2 xl:grid-cols-3"',
  'className="grid gap-5 md:grid-cols-2 xl:grid-cols-3"'
);

// Caso a classe já esteja diferente por algum ajuste local.
source = source.replace(
  'className="grid gap-5 lg:grid-cols-2"',
  'className="grid gap-5 md:grid-cols-2 xl:grid-cols-3"'
);

if (!source.includes('rounded-[28px] border border-slate-200 bg-white')) {
  throw new Error("O card antigo arredondado não foi aplicado.");
}

if (!source.includes('xl:grid-cols-3')) {
  throw new Error("A grade de 3 colunas no desktop não foi mantida.");
}

fs.writeFileSync(filePath, source);
NODE

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
echo "  git commit -m \"style: restore polished group cards with three-column layout\""
echo "  git push"
