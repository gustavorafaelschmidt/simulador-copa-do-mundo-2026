import type { VisualSimulatorDataSource } from "../../lib/fifa/visualOfficialDataAdapter.ts";

type VisualDataSourceBannerProps = {
  source: VisualSimulatorDataSource;
  message: string;
};

export function VisualDataSourceBanner({ source, message }: VisualDataSourceBannerProps) {
  const isDatabase = source === "database";

  return (
    <section
      className={`mb-5 rounded-[24px] border px-4 py-3 text-sm shadow-sm ${
        isDatabase
          ? "border-emerald-200 bg-emerald-50 text-emerald-900"
          : "border-amber-200 bg-amber-50 text-amber-900"
      }`}
    >
      <div className="flex flex-col gap-1 md:flex-row md:items-center md:justify-between">
        <strong className="font-black">
          {isDatabase ? "Dados conectados ao banco" : "Modo demo ativo"}
        </strong>
        <span className="font-medium">{message}</span>
      </div>
    </section>
  );
}
