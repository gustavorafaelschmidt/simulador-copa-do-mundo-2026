import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

const dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"]
    }
  },
  resolve: {
    alias: {
      "@": dirname,
      "@/components": path.resolve(dirname, "components"),
      "@/lib": path.resolve(dirname, "lib"),
      "@/services": path.resolve(dirname, "services"),
      "@/actions": path.resolve(dirname, "actions"),
      "@/types": path.resolve(dirname, "types"),
      "@/contracts": path.resolve(dirname, "lib/contracts"),
      "@/prisma": path.resolve(dirname, "prisma")
    }
  }
});