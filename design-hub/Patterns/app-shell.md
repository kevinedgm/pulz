# Shell de la app · `app-shell`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/shell/r01` |
| Código | `apps/web/src/app/AppShell.vue` (+ `CapaMas.vue`, `CapaCuenta.vue`, `destinos.ts`, `tema.ts`, `App.vue`) |
| Demo real | las pantallas reales (dev server) — el Hub muestra sus piezas: `#page-header`, `#side-nav`, `#bottom-nav`, `#fab` |
| Pruebas | `shared/ui/__tests__/shell.test.ts` (piezas y tema) · `qa/evidencia-shell.mjs` |
| Evidencia | `qa/evidence/shell-r01/*` (inicio, mas, configuración, fermentación, cuenta, equipo, sin permiso × 4 anchos × 2 temas) |

## Para qué

Que cualquier persona llegue a la etapa que le toca en ≤2 toques y sepa
siempre en qué empresa y con qué permisos está. El menú sigue al proceso
(§13.1): Inicio · Maguey · Horneado · Fermentación · Destilación · Granel ·
Trazabilidad · Configuración (solo admin).

## Anatomía

`CabeceraPagina` (línea de acento de la empresa + botón de empresa → Cuenta +
título del destino) · `Aviso` (sin conexión / solo lectura) · `main` con
`router-view` · navegación: `NavLateral` (≥600) o `NavInferior` (<600) ·
hueco de `BotonFlotante` por destino · capas `Más` y `Tu cuenta` (`CapaTarea`).

## Modos

| | compact (<600) | medium (600–1023) | expanded (≥1024) |
|---|---|---|---|
| Navegación | barra inferior: Inicio · Fermentación · Destilación · Granel + **Más** (Maguey · Horneado · Trazabilidad · Configuración*) | menú lateral 200 con los 8 | menú lateral 240 con empresa arriba y cuenta al pie |
| Cabecera | empresa (→ Cuenta) + título | empresa + título | **solo título** |
| Cuenta | hoja inferior | drawer | drawer |
| FAB | 56 px, abajo a la derecha; oculto con capas, solo lectura y en Inicio/Configuración | no existe | no existe |

\* solo `role = admin`; nunca se muestra deshabilitada. Por URL sin admin →
`state-block denied` "Solo el administrador puede ver la configuración".

## Comportamiento

- Una sola lista de destinos (`app/destinos.ts`) con dos presentaciones; la
  ruta se conserva al cambiar de tamaño (misma instancia).
- Tema: `data-theme` en `<html>` (claro/oscuro) o sin atributo (sistema);
  se guarda en `localStorage pulz:tema` y se aplica **antes** de montar.
- Teclado virtual (compact): la barra se oculta mientras un campo tiene foco
  o `visualViewport` se encoge al 75 %.
- Al elegir un destino desde una capa se espera el `popstate` del cierre y
  luego se navega (evita volver a la ruta anterior).
- Cambiar de empresa: enlace en Cuenta → `/e/<slug>/inicio` de la otra
  (las canceladas no aparecen; las vencidas llevan chip "solo lectura").
- Sin shell en portal, bienvenida, cambio obligatorio y 404 (`meta.shell`).

## Accesibilidad

Una sola `nav[aria-label="Navegación principal"]` por modo; destino actual
por `aria-current="page"` (borde + negrita); targets 44/48/56 px; capas con
`role=dialog`, foco atrapado y devuelto; `main#contenido` enfocable.

## API real

`meta` de ruta: `shell: true`, `destino`, `titulo`, `fab?: { etiqueta, icono? }`.
`destinosVisibles(esAdmin)`, `itemsNav(slug, destinos)`, `destinoDeRuta(nombre)`.
`useTema()` → `{ tema, aplicarTema }`; `aplicarTemaGuardado()`.

## QA y ciclo de vida

viewports runtime-verified (4 anchos × 2 temas, 3 roles) · teclado
runtime-verified (Esc en capas, navegación por enlaces) · touch emulado ·
zoom 200 % aproximado · contraste heredado de tokens. **Pendiente para
Stable:** teclado virtual real (iOS/Android), lector de pantalla, cambio de
empresa con dos membresías reales (la semilla no tiene), harden/audit.
