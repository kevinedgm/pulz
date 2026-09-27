// Segunda entrada de Vite: el Design Hub. Construye las piezas REALES de
// src/shared/ui hacia design-hub/Components/demo/ (la misma fuente que
// producción; nunca una copia). `pnpm --filter @pulz/web build:hub`
import vue from "@vitejs/plugin-vue"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"

export default defineConfig({
  plugins: [vue()],
  root: fileURLToPath(new URL("./hub", import.meta.url)),
  base: "./",
  build: {
    outDir: fileURLToPath(new URL("../../design-hub/Components/demo", import.meta.url)),
    emptyOutDir: true,
  },
})
