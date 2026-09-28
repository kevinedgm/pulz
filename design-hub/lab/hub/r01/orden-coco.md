# Orden de construcción para coco · hub/r01 · lima · 2026-09-27

Estructura congelada en `brief.md`, `index.html`, `declaracion.md`,
`hallazgos.md`. Pieza del sistema: `hub-shell` (template, draft). El
contenido lo posee mora (Markdown); coco construye el shell y el generador.

1. `design-hub/assets/hub-shell.css`: importa `../../apps/web/src/shared/ui/tokens.css`
   (ruta relativa desde `design-hub/site/`: se copia `tokens.css` a
   `design-hub/assets/` en el build para no depender de `apps/`). Clases
   `hub-*` mínimas: shell (sidebar 260 ≥1024 / barra + drawer <1024),
   breadcrumb, meta, chip de madurez (`hub-mad--draft|candidate|stable|deprecated`
   por texto + forma), TOC sticky, preview (iframe 16:10 + barra con enlace
   directo), galería, tablas, `pre`, 404. Modo oscuro por tokens. Foco
   visible 3px. `prefers-reduced-motion`.
2. `design-hub/assets/hub-navigation.js`: botón «Menú» (`aria-expanded`,
   `aria-controls`) abre el drawer (`role=dialog`, `aria-modal`, foco
   atrapado, Esc y scrim cierran, foco vuelve); marca `aria-current="page"`
   por URL; sin dependencias.
3. `design-hub/scripts/build-hub.mjs` (Node, `marked`): lee `README.md`,
   `Foundations/*.md`, `Components/*.md`, `Patterns/*.md`, `Screens/*.md` y
   `system/registry.json`; escribe `design-hub/site/index.html`,
   `site/<grupo>/<id>.html`, `site/qa.html`, `site/404.html`. Header de
   ficha desde el registry (tipo, estado, versión, owner, ronda, actualización)
   + tabla de facetas QA al final; TOC desde los `h2`; sección «Preview»
   insertada tras «Para qué»/«Propósito»: iframe `../Components/demo/index.html?pieza=<id>&solo=1`
   para componentes/patrones con `demo`, galería de `qa/evidence/<ronda>/`
   (ficheros `*-1440-light.png` etc.) para pantallas. Enlaces relativos
   reescritos (`.md` → `.html`, rutas al repo → enlaces a GitHub `main`).
   Deprecated fuera de la navegación con banner. `pnpm build:hub-site` en
   la raíz. El sitio se sirve con el mismo `python3 -m http.server 4321`
   → `http://localhost:4321/design-hub/site/`.
4. Verificación: enlaces internos del sitio (script), 0 errores JS,
   Playwright capturas de inicio + una ficha de componente + una de pantalla
   en 4 anchos × 2 temas (`qa/evidencia-hub.mjs`), drawer con Esc, zoom 200 %.
5. Entrega a mora: mora valida el sitio contra su estándar, ajusta el bloque
   `mora:` del perfil (`doc_shell`, `serve_command`, `hub_preview`) y publica.
