# Encargo documental para kiwi · Design Hub de PULZ (estructura HTML) · 2026-09-27

> Mora lo redacta; kiwi lo convierte en su ronda F0–F2 (`brief.md` · `index.html` · `declaracion.md`) en `design-hub/lab/hub/r01/`.
> No es un brief de diseño: define **qué debe poder encontrarse y con qué fuentes**, no cómo se ve.
> Mientras esta ronda no exista y se apruebe, el Hub vive en Markdown (`design-hub/README.md` y fichas) — contenido ya verificado que el shell HTML mostrará.

## Necesidad documental

Quien construye o revisa interfaz en PULZ (el dueño, coco, lima, mora, o
alguien nuevo en el repo) necesita encontrar en un solo sitio **qué piezas
existen, en qué estado están, cómo se usan y cómo se ven funcionando**, para
reutilizar antes de inventar y para aprobar o pedir cambios con evidencia.

## Criterios de éxito observables

1. Desde el inicio se llega a cualquier ficha (componente, patrón, pantalla, tokens) en ≤ 2 clics.
2. Cada ficha muestra su estado (`draft` / `candidate` / `stable`) y versión **leídos del registry**, por texto y por una señal no cromática.
3. La demo real de una pieza (`Components/demo/#id`, construida desde el código) se abre desde su ficha sin copiar CSS ni duplicar el componente.
4. La evidencia (capturas por ancho y tema) se abre desde la ficha.
5. «En esta página» deriva de las secciones reales de la ficha; una sola navegación global (sidebar persistente ≥1024, drawer en compact — misma jerarquía).
6. Una pieza `deprecated` sale de la navegación principal y conserva su ruta de migración.

## Superficies a estructurar

- **Inicio del Hub**: propósito y alcance, convenciones de madurez, accesos directos (Foundations, Components, Patterns, Screens, Evidencia), «lo que NO está hecho».
- **Ficha de componente/patrón** (10 hoy): Header/metadata → Overview → Usage → Preview (demo real) → Anatomy → variantes/estados → Behavior → Responsive → Accessibility → API real → Implementation → QA/Lifecycle.
- **Ficha de pantalla** (4 hoy): Header/metadata → Propósito → Ruta/entradas/salidas → Componentes usados → Estructura por dispositivo → Estados → Eventos → Criterios de aceptación → No verificado.
- **Foundations**: Tokens (con contraste medido), Iconos. Color/Type como secciones de Tokens salvo que crezcan.
- **Responsive**: no es sección propia hoy; cada ficha trae su rango. kiwi decide si un índice cruzado (Mobile/Tablet/Desktop) aporta algo o es decorativo.

**Fuera de alcance:** documentar piezas `draft`; navegación del producto (bottom nav) dentro del shell del Hub; KPIs o miniaturas.

## Fuentes de verdad disponibles

| Dato | Fuente propietaria | Ruta |
|---|---|---|
| Rutas y taxonomía | perfil de lima (`hub_layout`) | `.claude/skills/lima/profiles/pulz.md` |
| Estado, versión, owner, QA | registry | `design-hub/system/registry.json` |
| API y comportamiento | código | `apps/web/src/shared/ui/*.vue`, `apps/web/src/modules/{acceso,equipo}/` |
| Contenido verificado de cada ficha | mora | `design-hub/README.md`, `Foundations/*.md`, `Components/*.md`, `Patterns/*.md`, `Screens/*.md` |
| Demo real | build desde el código | `design-hub/Components/demo/index.html#<id>` |
| Evidencia | Playwright | `design-hub/qa/evidence/acceso-r01/` |
| Orden de secciones | `mora.doc_standard` (mínimo interno) | perfil, bloque `mora:` |
| Shell activo | **no existe** — lo produce esta ronda | `mora.doc_shell` quedará apuntando a lo que kiwi/coco entreguen |
| Tokens | `tokens.css` | `apps/web/src/shared/ui/tokens.css` |

## Restricciones del estándar

- Contratos de ficha y metadata según `.claude/skills/mora-docs/documentation-round-standard.md`.
- Una sola navegación global; «En esta página» deriva de secciones reales; breadcrumb para ubicación.
- Madurez por texto + señal no cromática.
- El shell del Hub usa los tokens de PULZ pero **no** es una pantalla del producto: no adopta su navegación.
- Sin segundo shell, hoja o árbol paralelo; la demo existente (`Components/demo`) se embebe o se enlaza, no se reescribe.

## Incógnitas que kiwi no debe resolver inventando

1. Taxonomía de las pantallas: mora las puso en `design-hub/Screens/` (no está en `hub_layout`); lima confirma o renombra.
2. Si `Responsive/{Mobile,Tablet,Desktop}` del perfil se mantiene como sección o se retira (hoy vacía).
3. Cómo se embebe la demo real en la Preview (iframe por anchor vs. enlace): depende de si el Hub se sirve estático (`python3 -m http.server 4321`) o dentro de Vite.
