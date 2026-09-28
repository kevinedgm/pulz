import vue from "@vitejs/plugin-vue"
import { VitePWA } from "vite-plugin-pwa"
import { defineConfig } from "vitest/config"

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    // PWA mínima (Fase 4, PULZ_MAESTRO.md §8.1): instalable con manifest e
    // iconos. Sin cacheo de datos ni cola offline todavía (Fase 5): el
    // service worker solo precachea la app para que abra sin señal.
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.svg", "icons/apple-touch-icon-180x180.png"],
      manifest: {
        name: "PULZ · Producción y trazabilidad de mezcal",
        short_name: "PULZ",
        description: "Registro de producción y trazabilidad para palenques",
        lang: "es-MX",
        display: "standalone",
        start_url: "/",
        scope: "/",
        theme_color: "#173F87",
        background_color: "#F8F6F2",
        icons: [
          { src: "icons/pwa-192x192.png", sizes: "192x192", type: "image/png" },
          { src: "icons/pwa-512x512.png", sizes: "512x512", type: "image/png" },
          {
            src: "icons/maskable-512x512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "maskable",
          },
        ],
      },
      workbox: {
        // Solo la app; nada de la API ni del portal (que es una Pages Function)
        globPatterns: ["**/*.{js,css,html,svg,png,woff2}"],
        navigateFallbackDenylist: [/^\/e\/[^/]+\/?$/],
      },
    }),
  ],
  test: {
    environment: "jsdom",
    globals: true,
    // La Pages Function se prueba aparte (test:portal): necesita dist/ y wrangler
    exclude: ["**/node_modules/**", "**/dist/**", "functions/**"],
  },
})
