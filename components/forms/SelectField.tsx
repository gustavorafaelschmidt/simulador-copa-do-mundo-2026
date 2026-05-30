import type { ReactNode } from "react";

type SelectFieldProps = {
  label: string;
  name: string;
  defaultValue?: string;
  required?: boolean;
  children: ReactNode;
};

export function SelectField({
  label,
  name,
  defaultValue = "",
  required = false,
  children
}: SelectFieldProps) {
  return (
    <label className="block">
      <span className="text-sm font-medium">{label}</span>
      <select
        className="mt-1 w-full rounded-xl border border-app-border bg-white px-3 py-2 text-sm outline-none transition focus:border-app-primary focus:ring-2 focus:ring-app-primary/20"
        defaultValue={defaultValue}
        name={name}
        required={required}
      >
        {children}
      </select>
    </label>
  );
}
