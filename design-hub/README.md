# PULZ · Design Hub

Referencia operativa del sistema de interfaz de PULZ. Documenta **solo lo que
existe en el código y pasó una compuerta de lima**; el estado de cada pieza
sale de [`system/registry.json`](system/registry.json), nunca de esta página.

> Las fichas se escriben en Markdown (esta carpeta) y el **sitio** se genera
> con `pnpm build:hub-site` en `site/` (ronda `lab/hub/r01`, pieza
> `hub-shell`): `python3 -m http.server 4321` en la raíz del repo →
> `http://localhost:4321/design-hub/site/`. El HTML de `site/` no se edita a
> mano: cambia la ficha y vuelve a generar.

## Cómo se usa

- **Ver una pieza funcionando:** `pnpm --filter @pulz/web build:hub` construye
  [`Components/demo/`](Components/demo/index.html) desde el código real
  (`apps/web/src/shared/ui/`); en el sitio cada ficha de componente o patrón
  la embebe (`?pieza=<id>&solo=1`) y enlaza
  `http://localhost:4321/design-hub/Components/demo/#<id>`.
- **Ver las pantallas reales:** dev server (`.claude/launch.json` → `web`) con
  los usuarios de `supabase/seed.sql`. En el sitio, cada ficha de pantalla
  trae la galería de sus capturas.
- **Evidencia (1440/1024/768/390 × claro/oscuro):**
  [`qa/evidence/acceso-r01/`](qa/evidence/acceso-r01/) 104 ·
  [`qa/evidence/shell-r01/`](qa/evidence/shell-r01/) 50 ·
  [`qa/evidence/configuracion-r01/`](qa/evidence/configuracion-r01/) 67 ·
  [`qa/evidence/arranque-r01/`](qa/evidence/arranque-r01/) 13 ·
  [`qa/evidence/hub-r01/`](qa/evidence/hub-r01/) 36 (el sitio mismo) ·
  [`qa/evidence/fase4-e2e/`](qa/evidence/fase4-e2e/) 9 ·
  [`qa/evidence/fermentacion-r01/`](qa/evidence/fermentacion-r01/) 61 ·
  [`qa/evidence/fase5-offline/`](qa/evidence/fase5-offline/) 4 (e2e en modo avión); generadas por
  `qa/evidencia-*.mjs`; zoom 200 % aproximado por `qa/zoom-acceso.mjs`;
  enlaces del sitio por `qa/enlaces-hub.mjs`.

## Madurez (registry, 2026-09-27)

| Estado | Significa | Señal en las fichas |
|---|---|---|
| draft | en exploración | «Estado: draft» |
| **candidate** | pasó la compuerta Candidate de lima; el dueño puede pedir cambios o estabilizar | «Estado: candidate 0.2.0» |
| stable | contrato aprobado explícitamente por el dueño | — (ninguna todavía) |

Ninguna pieza es `stable`. Todo lo de abajo es **candidate** (0.2.0; 0.3.0
las extendidas en fermentación: `status-chip`, `banner`, `app-shell`),
rondas [`lab/acceso/r01`](lab/acceso/r01/), [`lab/shell/r01`](lab/shell/r01/),
[`lab/configuracion/r01`](lab/configuracion/r01/), [`lab/arranque/r01`](lab/arranque/r01/),
[`lab/hub/r01`](lab/hub/r01/) (el shell de este sitio, `hub-shell`) y
[`lab/fermentacion/r01`](lab/fermentacion/r01/).

## Foundations

- [Tokens](Foundations/Tokens.md) — variables reales de `tokens.css`, claro y oscuro, con el contraste medido.
- [Iconos](Foundations/Icons.md) — los 16 símbolos del sprite y qué no existe.

## Components (sistema, `apps/web/src/shared/ui/`)

| Pieza | id | Archivo |
|---|---|---|
| [Botón](Components/button.md) | `button` | `Boton.vue` |
| [Campo de texto](Components/text-field.md) | `text-field` | `CampoTexto.vue` |
| [Campo de contraseña](Components/password-field.md) | `password-field` | `CampoContrasena.vue` |
| [Segmento de opciones](Components/segmented-choice.md) | `segmented-choice` | `SegmentoOpciones.vue` |
| [Chip de estado](Components/status-chip.md) | `status-chip` | `ChipEstado.vue` |
| [Menú de fila](Components/row-menu.md) | `row-menu` | `MenuFila.vue` |
| [Cabecera de página](Components/page-header.md) | `page-header` | `CabeceraPagina.vue` |
| [Menú lateral](Components/side-nav.md) | `side-nav` | `NavLateral.vue` |
| [Navegación inferior](Components/bottom-nav.md) | `bottom-nav` | `NavInferior.vue` |
| [Botón flotante](Components/fab.md) | `fab` | `BotonFlotante.vue` |
| [Select](Components/select.md) | `select` | `Selector.vue` |
| [Campo numérico](Components/number-field.md) | `number-field` | `CampoNumero.vue` |
| [Interruptor](Components/switch.md) | `switch` | `Interruptor.vue` |
| [Campo de color](Components/color-field.md) | `color-field` | `CampoColor.vue` |
| [Selector de archivo](Components/file-picker.md) | `file-picker` | `SelectorArchivo.vue` |
| [Bloque de marca](Components/brand-block.md) | `brand-block` | `BloqueMarca.vue` |
| [Campo grande](Components/big-number-field.md) | `big-number-field` | `CampoGrande.vue` |
| [Escala de opciones](Components/scale-choice.md) | `scale-choice` | `EscalaOpciones.vue` |
| [¿Cuándo pasó?](Components/datetime-field.md) | `datetime-field` | `CampoCuando.vue` |

## Patterns (sistema)

| Pieza | id | Archivo |
|---|---|---|
| [Aviso](Patterns/banner.md) | `banner` | `Aviso.vue` |
| [Bloque de estado](Patterns/state-block.md) | `state-block` | `BloqueEstado.vue` |
| [Capa de tarea](Patterns/task-layer.md) | `task-layer` | `CapaTarea.vue` |
| [Lista apilada](Patterns/list-stack.md) | `list-stack` | `ListaApilada.vue` |
| [Shell de la app](Patterns/app-shell.md) | `app-shell` | `app/AppShell.vue` |
| [Flujo por pasos](Patterns/step-flow.md) | `step-flow` | `FlujoPasos.vue` |
| [Aviso con nota](Patterns/soft-warning-note.md) | `soft-warning-note` | `AvisoNota.vue` |

## Screens (product-application, `apps/web/src/modules/`)

| Pantalla | id | Ruta |
|---|---|---|
| [Portal e inicio de sesión (+404)](Screens/acceso-portal.md) | `acceso-portal` | `/e/:slug`, `/e/:slug/no-encontrado` |
| [Cambio obligatorio de contraseña](Screens/acceso-cambio-contrasena.md) | `acceso-cambio-contrasena` | `/e/:slug/cambiar-contrasena` |
| [Bienvenida por enlace](Screens/acceso-bienvenida.md) | `acceso-bienvenida` | `/e/:slug/bienvenida#token` |
| [Equipo](Screens/equipo.md) | `equipo` | `/e/:slug/equipo` |
| [Inicio](Screens/inicio.md) | `inicio` | `/e/:slug/inicio` |
| [Configuración](Screens/configuracion.md) | `configuracion` | `/e/:slug/configuracion/{recursos,catalogos,ajustes,portal}` |
| [Primer arranque](Screens/arranque.md) | `arranque` | `/e/:slug/arranque` |
| [Fermentación](Screens/fermentacion.md) | `fermentacion` | `/e/:slug/fermentacion`, `/…/formular`, `/…/:ciclo`, `/…/:ciclo/medir` |

## Lo que NO está hecho (no lo busques aquí como hecho)

- Bloqueo por 5 intentos fallidos — hook fuera del plan, `docs/DUDAS.md` #9.
- Ámbar (`--pend`) como color de texto en claro — `docs/DUDAS.md` #12.
- Responsive/{Mobile,Tablet,Desktop} como secciones propias: el
  comportamiento por rango está en cada ficha (sección «Responsive»).
