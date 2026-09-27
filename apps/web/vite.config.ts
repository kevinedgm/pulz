import vue from "@vitejs/plugin-vue"
import { defineConfig } from "vitest/config"

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  test: {
    environment: "jsdom",
    globals: true,
    // La Pages Function se prueba aparte (test:portal): necesita dist/ y wrangler
    exclude: ["**/node_modules/**", "**/dist/**", "functions/**"],
  },
})
