# Declaración de cumplimiento · HUB · r01

| Campo | Valor |
|---|---|
| Ruta | R1 |
| Fidelidad | F2 (estructura del Hub; sin F3: la presentación final es el shell que coco construye y mora reutiliza) |
| Pregunta de diseño | ¿Se llega desde el inicio a cualquier ficha en ≤2 clics, y cada ficha deja ver estado (registry), demo real y evidencia sin duplicar contenido? |
| Artefactos | `brief.md` (brief + flujo) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

`mora-docs/documentation-round-standard.md` (shell: una navegación; inicio: bloques; fichas: orden; metadata; madurez texto + forma; responsive; fidelidad F0–F2) · encargo de mora · `wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md` · WCAG 2.2 AA (targets 24 mínimo en documentación densa, declarado; 44 en controles principales: Menú, Cerrar, botones) · perfil (`hub_layout`, breakpoints).

## Desviaciones del protocolo

- Objetivos táctiles: los enlaces del sidebar del Hub son de 36 px (documentación densa, uso de escritorio); cumple el mínimo WCAG 2.2 de 24×24 y se declara como excepción; los controles principales (Menú, Cerrar, botones) van a 44.
- `Responsive/{Mobile,Tablet,Desktop}` del perfil se retira de la navegación (hallazgo medio): el rango vive en cada ficha.

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 0 avisos.
- Chromium (Playwright): **84 combinaciones** (3 espacios × 4 páginas × 7 estados): sin desborde, 0 controles <24 px, siempre una navegación con nombre accesible (sidebar o drawer), 0 errores JS.
- Estados: default · drawer (<1024) · pieza deprecated (banner «Reemplazada por…», fuera de la navegación) · sección sin piezas · 404 del sitio · contenido largo (ruta de archivo larga) · demo no disponible (enlace directo).

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Navegación global | barra superior + «Menú» → drawer con la misma jerarquía | igual | sidebar persistente 260 px | una jerarquía, dos presentaciones | CSS + `hub-navigation.js` (drawer, `aria-current`) | Esc cierra el drawer; foco vuelve a «Menú»; la página no cambia |
| «En esta página» | bloque al inicio del contenido | igual | columna derecha sticky 200 px | contexto local derivado de los `h2` reales | generado en build | anchors |
| Preview de componente | iframe a ancho completo | igual | igual | demo real, sin CSS copiado | `iframe` `?pieza=<id>&solo=1` | si no carga: enlace directo |
| Galería de capturas (pantallas) | 2 columnas | 2 | 4 | comparación por ancho/tema | grid | — |
| Mapa de piezas (inicio) | 1 columna | 1 | 2 | — | grid | — |
| Metadata | apilada | en línea | en línea | — | flex-wrap | — |

## Comprobaciones NO ejecutadas

- Lector de pantalla; zoom nativo.
- Generación real desde Markdown (coco): se valida al publicar (mora), con el check de enlaces existente.

## Hallazgos

Ver `hallazgos.md`: 2 altos (generar el sitio desde Markdown + registry; preview = demo real), 2 medios (retirar Responsive/*; hoja propia del shell), 1 bajo.

## Traspaso

- **→ mora** (dueña del encargo): valida esta ronda contra el estándar y, aprobada, coordina la construcción del shell con coco y publica.
- **→ lima:** registrar `hub-shell` como `template` (draft) con contrato: una navegación, breadcrumb, madurez por texto+forma, TOC derivado, preview por iframe, galería por evidencia, 404; `doc_shell` del perfil = `design-hub/assets/hub-shell.css` + `design-hub/assets/hub-navigation.js`; retirar `Responsive/*` de `hub_layout`.
- **→ coco:** `design-hub/assets/hub-shell.css` (consume `tokens.css`), `design-hub/assets/hub-navigation.js` (drawer accesible, `aria-current`, Esc), `design-hub/scripts/build-hub.mjs` (`marked` + registry → `design-hub/site/` con `index.html`, `<grupo>/<id>.html`, `qa.html`, `404.html`), `pnpm build:hub-site`; README y fichas siguen siendo la fuente.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) → mora valida → lima registra → coco construye → mora publica.
