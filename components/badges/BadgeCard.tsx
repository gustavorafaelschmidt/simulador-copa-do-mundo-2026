import type { BadgeDTO } from "../../lib/contracts/badge.ts";

type BadgeCardProps = {
  badge: BadgeDTO;
  awardedAt?: string;
};

const rarityClassName = {
  COMMON: "border-app-border",
  RARE: "border-blue-200",
  EPIC: "border-purple-200",
  LEGENDARY: "border-yellow-300"
} as const;

export function BadgeCard({ badge, awardedAt }: BadgeCardProps) {
  return (
    <article className={`rounded-app border bg-app-surface p-4 shadow-app ${rarityClassName[badge.rarity]}`}>
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-app-primary">
            {badge.rarity}
          </p>
          <h3 className="mt-2 font-bold">{badge.name}</h3>
        </div>

        <span className="rounded-xl bg-app-bg px-3 py-2 text-lg" aria-hidden="true">
          {badge.iconKey ?? "🏆"}
        </span>
      </div>

      <p className="mt-3 text-sm leading-6 text-app-muted">{badge.description}</p>

      {awardedAt ? (
        <p className="mt-3 text-xs text-app-muted">
          Conquistada em{" "}
          {new Intl.DateTimeFormat("pt-BR", {
            dateStyle: "short",
            timeStyle: "short"
          }).format(new Date(awardedAt))}
        </p>
      ) : null}
    </article>
  );
}
