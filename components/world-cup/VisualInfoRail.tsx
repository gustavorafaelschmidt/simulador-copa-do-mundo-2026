type VisualInfoRailProps = {
  title?: string;
};

const cards = [
  {
    eyebrow: "1",
    title: "Escolha os grupos",
    description: "Defina 1º, 2º e 3º colocados de cada grupo em poucos toques."
  },
  {
    eyebrow: "2",
    title: "Veja os terceiros",
    description: "A interface mostra oito terceiros classificados em modo demo."
  },
  {
    eyebrow: "3",
    title: "Monte o mata-mata",
    description: "Os vencedores avançam automaticamente até a grande final."
  }
];

export function VisualInfoRail({ title = "Como funciona" }: VisualInfoRailProps) {
  return (
    <section className="mx-auto max-w-7xl px-4 pb-8">
      <div className="rounded-[32px] border border-slate-200 bg-white p-4 shadow-[0_18px_60px_rgba(15,23,42,0.08)] md:p-6">
        <div className="mb-4 flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-[11px] font-black uppercase tracking-[0.24em] text-emerald-700">
              Guia rápido
            </p>
            <h2 className="text-2xl font-black text-slate-950">{title}</h2>
          </div>

          <p className="max-w-xl text-sm leading-6 text-slate-500">
            Este visual é inspirado na experiência de simuladores esportivos, com layout,
            fluxo e interações próprias do projeto.
          </p>
        </div>

        <div className="grid gap-3 md:grid-cols-3">
          {cards.map((card) => (
            <article
              className="rounded-3xl border border-slate-200 bg-slate-50 p-4"
              key={card.eyebrow}
            >
              <span className="grid size-9 place-items-center rounded-full bg-emerald-600 text-sm font-black text-white">
                {card.eyebrow}
              </span>
              <h3 className="mt-4 text-lg font-black text-slate-950">{card.title}</h3>
              <p className="mt-2 text-sm leading-6 text-slate-500">{card.description}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
