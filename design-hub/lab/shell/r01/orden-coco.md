# Orden de construcción para coco · shell/r01 · lima · 2026-09-27

Estructura congelada: `brief.md`, `index.html` (F2), `declaracion.md`
(matriz de adaptación), `hallazgos.md`. Decisiones del dueño/Claude en
`docs/DECISIONES.md` (fijos de compact; 4 símbolos nuevos; cambiar de
empresa solo en Cuenta).

## 1. Clasificación y reutilización

| Pieza | Tipo | Reuso | Registry | Dónde vive |
|---|---|---|---|---|
| app-shell | pattern | **new** | `app-shell` draft 0.1.0 | `apps/web/src/app/AppShell.vue` (+ `router-view` anidado) |
| bottom-nav | component | **new** | `bottom-nav` draft | `apps/web/src/shared/ui/NavInferior.vue` |
| side-nav | component | **new** | `side-nav` draft | `apps/web/src/shared/ui/NavLateral.vue` |
| page-header | component | **new** | `page-header` draft | `apps/web/src/shared/ui/CabeceraPagina.vue` |
| fab | component | **new** | `fab` draft | `apps/web/src/shared/ui/BotonFlotante.vue` |
| theme-switch | — | **reuse** de `segmented-choice` (3 opciones: sistema/claro/oscuro) | sin entrada | dentro de la capa Cuenta |
| Más (hoja) · Cuenta (hoja/popover) | — | **reuse** de `task-layer` | — | `apps/web/src/app/CapaMas.vue`, `CapaCuenta.vue` (locales del shell) |
| banner, state-block, button, status-chip | — | **reuse** | candidate | — |
| Inicio ("Hoy", "¿Qué tienes hoy?") | product-application | **new** | `inicio` draft | `apps/web/src/modules/inicio/pages/InicioEmpresaPage.vue` (reemplaza el placeholder) |
| Destinos de proceso vacíos | product-application (local, sin registry) | local | — | `apps/web/src/modules/proceso/pages/ProximamentePage.vue` (una página parametrizada por destino) |
| Índice de Configuración | product-application | otra ronda (`configuracion/r01`) | — | por ahora ruta `/configuracion` → el mismo "próximamente" para admin; sin admin → denied |

## 2. Contratos (registry, campo `contract`)

Ver `design-hub/system/registry.json`: `app-shell`, `bottom-nav`, `side-nav`,
`page-header`, `fab`, `inicio`. Puntos duros:

- **Una lista de destinos**, `Destino[]`, con dos presentaciones (barra /
  lateral). `Configuración` solo con `esAdmin`; nunca deshabilitada.
- `aria-current="page"` por borde + negrita (no solo color). Targets: barra
  ≥48px, lateral ≥44px, FAB 56px, botón de empresa ≥44px.
- Compact: `bottom-nav` oculta con teclado virtual (`visualViewport.height`
  < `innerHeight * 0.75` o foco en input/textarea); cuerpo con
  `padding-bottom` ≥ barra + FAB + área segura.
- Tema: `data-theme="light|dark"` en `<html>` cuando es manual; sin
  atributo = sistema (`tokens.css` ya trae ambos). Persistir en
  `localStorage pulz:tema`. Sin parpadeo: leer antes de montar (script
  inline en `index.html` o en `main.ts` antes de `mount`).
- Capas Más y Cuenta = `task-layer` (hoja en compact; en medium/expanded la
  Cuenta como drawer derecho de `task-layer` — no inventar un popover
  nuevo; kiwi lo dibujó como popover pero el contrato de `task-layer` ya
  cubre la tarea acotada y evita una pieza más). **Excepción declarada
  respecto al wireframe**, registrada aquí; si el dueño quiere popover, es
  una pieza nueva (`popover`) en r02.
- Sin shell en rutas de acceso (`portal`, `bienvenida`, `cambiar-contrasena`,
  `no-encontrado`): el router decide con `meta.publica` / layout.

## 3. Datos (para `coco.data_contract`)

```
Destino      = { id: 'inicio'|'maguey'|'horneado'|'fermentacion'|'destilacion'|'granel'|'trazabilidad'|'configuracion',
                 titulo, icono: IconoNombre, soloAdmin: boolean, fijoEnCompact: boolean, ruta: '/e/:slug/<id>' }
Cuenta       = { persona: MiMembresia.username ?? 'titular', rol: MiMembresia.role,
                 empresas: MiMembresia[] (excluye cancelled; read_only marca "solo lectura"),
                 tema: 'sistema'|'claro'|'oscuro' (localStorage) }
Inicio.sinLotes = (select count(*) from lots where organization_id = ...) = 0  → consulta PostgREST `lots?select=id&limit=1` bajo RLS (is_member)
```
No hay campos nuevos en la base.

## 4. Sprite: 4 símbolos nuevos (decisión 2026-09-27)

Agregar a `apps/web/src/shared/ui/iconos.svg` con el mismo trazo (viewBox
24, `stroke-width` 2, `stroke-linecap: round`, `fill: none`):
`i-tanque` (Granel), `i-traza` (Trazabilidad), `i-ajustes` (Configuración),
`i-menu` (Más). Actualizar `IconoNombre` en `tipos.ts` y `Icons.md` del Hub
(mora). Granel usa `i-tanque`; `i-lote` queda para lotes/trazabilidad de
lote.

## 5. Rutas y guardias

- `/e/:slug/inicio` → Inicio (shell). `/e/:slug/{maguey,horneado,fermentacion,destilacion,granel,trazabilidad}` → `ProximamentePage` (shell). `/e/:slug/configuracion` → admin: índice provisional "próximamente" (ronda `configuracion/r01` lo reemplaza); no admin: `state-block denied`. `/e/:slug/equipo` sigue igual, dentro del shell, enlazado desde Cuenta.
- El guardia existente no cambia (sesión, membresía, must_change_password).
- Cambiar de empresa: `router.push('/e/<slug2>/inicio')` + `cargarPortal(slug2)`.

## 6. Orden de construcción

1. Sprite (4 símbolos) + `tipos.ts`.
2. `shared/ui`: `CabeceraPagina`, `NavLateral`, `NavInferior`, `BotonFlotante` (+ demos en el Hub).
3. `app/AppShell.vue` (+ `CapaMas`, `CapaCuenta`, tema, visualViewport) y rutas anidadas.
4. `modules/inicio` (Hoy / ¿Qué tienes hoy?) y `modules/proceso/ProximamentePage`.
5. Vitest (contratos: aria-current, admin-only, tema persistido, Más/Cuenta con task-layer) + Playwright evidencia (`qa/evidencia-shell.mjs`: 4 anchos × 2 temas × 3 roles) + zoom 200 %.
6. Declaración de cumplimiento → lima (compuerta Candidate).
