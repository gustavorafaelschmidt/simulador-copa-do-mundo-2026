import type { Config } from "tailwindcss";

const config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./actions/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
    "./services/**/*.{ts,tsx}"
  ],
  theme: {
    extend: {
      screens: {
        xs: "360px"
      },
      borderRadius: {
        app: "1rem"
      },
      boxShadow: {
        app: "0 12px 30px rgba(15, 23, 42, 0.08)"
      },
      colors: {
        app: {
          background: "var(--color-app-background)",
          foreground: "var(--color-app-foreground)",
          surface: "var(--color-app-surface)",
          muted: "var(--color-app-muted)",
          border: "var(--color-app-border)",
          primary: "var(--color-app-primary)",
          success: "var(--color-app-success)",
          danger: "var(--color-app-danger)"
        }
      }
    }
  }
} satisfies Config;

export default config;