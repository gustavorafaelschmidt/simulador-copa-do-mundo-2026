type StatusPillProps = {
  label: string;
  tone?: "neutral" | "success" | "warning" | "danger";
};

const toneClasses = {
  neutral: "border-app-border bg-app-surface text-app-muted",
  success: "border-green-200 bg-green-100 text-green-800",
  warning: "border-yellow-200 bg-yellow-100 text-yellow-800",
  danger: "border-red-200 bg-red-100 text-red-800"
} as const;

export function StatusPill({ label, tone = "neutral" }: StatusPillProps) {
  return (
    <span
      className={`inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold ${toneClasses[tone]}`}
    >
      {label}
    </span>
  );
}
