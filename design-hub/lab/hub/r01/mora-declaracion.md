# Declaración documental · PULZ Design Hub · ronda hub/r01 (shell del Hub)

| Campo | Valor |
|---|---|
| Superficie | el sitio del Hub: `design-hub/site/` generado desde las fichas Markdown + `system/registry.json` con el shell `hub-shell` |
| Modo | **M1 Estructura** (shell, navegación, inicio, 404) + **M3 Sincronización** (bloque `mora:` del perfil, README) |
| Ronda de kiwi | `design-hub/lab/hub/r01/` (brief, wireframe F2, hallazgos, declaración) nacida del encargo `lab/hub/encargo-mora.md` |
| Construcción | coco: `assets/hub-shell.css`, `assets/hub-navigation.js`, `scripts/build-hub.mjs` (`coco-declaracion.md`) |
| Estado en registry | `hub-shell` (template) → `candidate` 0.2.0 tras esta validación (lima, `lima-compuerta.md`) |
| Modifica producción | No |

## Validación de la ronda contra `documentation-round-standard.md`

| Criterio del estándar | Resultado | Evidencia |
|---|---|---|
| Una sola navegación global (sin drawers ni árboles paralelos) | Cumple | sidebar ≥1024 y drawer <1024 comparten la misma lista generada; el TOC «En esta página» es contextual, no un segundo menú |
| Inicio por bloques: cómo se usa, madurez, mapa de piezas, lo que no está hecho | Cumple | `site/index.html` desde `README.md` (h2 → TOC) |
| Ficha: Header → Overview → Preview → Anatomía → estados → Comportamiento → Responsive → Accesibilidad → API real → Implementación → QA/Lifecycle | Cumple | orden de las fichas Markdown (ya validado en acceso/r01); el build inserta «Preview» tras «Para qué»/«Propósito» y «Facetas de QA (registry)» al final |
| Header y lifecycle desde el registry | Cumple | tipo, estado, versión, owner, ronda, actualización y la tabla de facetas se leen de `registry.json` en el build; ninguna ficha declara su estado a mano |
| Madurez por texto + forma | Cumple | chip `hub-mad--*` (texto siempre; borde discontinuo draft, relleno candidate, ✓ stable, tachado deprecated) |
| Preview con el componente real, sin CSS copiado | Cumple | iframe a `Components/demo/index.html?pieza=<id>&solo=1` (construida desde el código) para las 21 piezas con demo; galería de capturas para las 7 pantallas y `app-shell`; «Abrir aparte» en todos |
| Deprecated fuera de la navegación con ruta de migración | Cumple (sin caso real) | rama `replacedBy` del build; probada en el wireframe (estado) — no hay pieza deprecated en el registry hoy |
| Responsive 1440/1024/768/390, claro/oscuro, sin desborde | Cumple | `qa/evidencia-hub.mjs` 8/8, 36 capturas; tablas anchas con scroll propio en 390 |
| Enlaces internos y recursos resuelven | Cumple | `qa/enlaces-hub.mjs`: 33 páginas, 0 rotos |
| Accesibilidad: nombre accesible de la navegación, `aria-current`, drawer `role=dialog` con foco, Esc, targets | Cumple | `hub-navigation.js` + evidencia (foco entra, Esc cierra, foco vuelve a «Menú»); sidebar 36 px declarado como excepción sobre 44 (mínimo 24) |

## Corregido en la validación (autocorregible, documental)

- `README.md`: el aviso «Hub en Markdown / shell pendiente» pasa a explicar
  cómo se genera y sirve el sitio; la lista de evidencia incluye las seis
  carpetas reales (acceso 104, shell 50, configuración 67, arranque 13, hub
  36, fase4-e2e 9) y el script de enlaces.
- Perfil, bloque `mora:`: `doc_shell` = `design-hub/assets/hub-shell.css` +
  `hub-navigation.js`; `hub_preview` con la URL del sitio; `serve_command`
  sin cambio. `hub_layout` ya traía Screens y QA (lima).

## Requiere revisión (lima)

- Ninguna. La taxonomía `Screens/` y el retiro de `Responsive/*` quedaron
  registrados en el perfil en esta ronda.

## Derivado fuera de mora

- Búsqueda global del Hub (Could): r02 si el dueño la pide.
- Alto del iframe de la demo fijo por rango (coco, LOW, sin acción).

## Verificado

- `pnpm build:hub-site` ✔ (30 fichas + inicio + qa + 404) · `node
  design-hub/qa/enlaces-hub.mjs` ✔ 0 rotos · `node design-hub/qa/evidencia-hub.mjs`
  8/8 ✔ · JSON del registry válido tras la transición de lima.

## No ejecutado / evidencia faltante

- Lector de pantalla y zoom nativo (no hay forma automatizada aquí; queda
  para la compuerta Stable del `hub-shell`).
- Censo automático de cobertura: no existe (`coverage_script` vacío); el
  registry es el censo y las 29 entradas tienen ficha (30 páginas contando
  Tokens e Iconos).

## Deriva pendiente

- Ninguna conocida. Regla operativa: al cambiar una ficha o el registry se
  vuelve a ejecutar `pnpm build:hub-site` y se versiona `site/` junto con el
  cambio; si se olvida, `qa/enlaces-hub.mjs` y la fecha «Actualizado» del
  header lo delatan.
