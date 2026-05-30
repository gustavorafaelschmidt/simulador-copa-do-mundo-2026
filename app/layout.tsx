import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Simulador Copa 2026",
  description: "Simulador gamificado da Copa do Mundo 2026"
};

type RootLayoutProps = Readonly<{
  children: React.ReactNode;
}>;

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}