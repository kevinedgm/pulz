// Prueba de la Pages Function del portal. Levanta `wrangler pages dev`
// (Miniflare, sin Docker) sobre dist/ con los bindings del proyecto Supabase
// alojado, y pega por HTTP: es la función real contra portal_branding real.
//   pnpm --filter @pulz/web build && pnpm --filter @pulz/web test:portal
import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    environment: "node",
    include: ["functions/__tests__/**/*.test.ts"],
    testTimeout: 60_000,
    hookTimeout: 90_000,
    fileParallelism: false,
  },
})
