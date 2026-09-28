# Orden de construcción para coco · configuracion/r01 · lima · 2026-09-27

Estructura congelada: `brief.md`, `index.html` (F2), `declaracion.md`,
`hallazgos.md`. Decisiones en `docs/DECISIONES.md` (recurso_en_uso entra;
capa por tabla; solo admin; 6 piezas nuevas; recorte con canvas).

## 1. Base primero (migración "desde cero" nueva)

`supabase/migrations/20260927000025_recurso_en_uso.sql`: función
`recurso_en_uso(p_org uuid) returns table (resource_id uuid, saldo_l numeric,
ciclos_abiertos int)` — security definer, solo miembros de la empresa
(`is_member`), lee `liquid_movements` (saldo por recurso = suma dest −
suma origen, como `resource_balance`) y `fermentation_cycles` con
`status <> 'cerrado'`. pgTAP en `configuracion.test.sql` (3 casos: tanque con
saldo, tina con ciclo abierto, recurso limpio; operador de otra empresa no).

## 2. Piezas del sistema (shared/ui) — registry draft

| Pieza | Archivo | Reutiliza |
|---|---|---|
| `select` | `Selector.vue` | contrato de etiqueta/ayuda/error de text-field |
| `number-field` | `CampoNumero.vue` | text-field (inputmode, unidad a la derecha) |
| `switch` | `Interruptor.vue` | — |
| `color-field` | `CampoColor.vue` | text-field (hex) |
| `file-picker` | `SelectorArchivo.vue` | button |
| `brand-block` | `BloqueMarca.vue` (mover `modules/acceso/components/MarcaPortal.vue`; acceso lo importa de shared/ui) | — |

Demos en el Hub (`DemoHub.vue`) para las 6. Vitest de contrato.

## 3. Product-application `configuracion` (`apps/web/src/modules/configuracion/`)

- `routes.ts`: `/e/:slug/configuracion/{recursos,catalogos,ajustes,portal}` con `meta: { shell: true, destino: "configuracion", titulo: "<Sección>" }`. El índice (`ConfiguracionIndicePage.vue`, hoy en `modules/proceso`) se mueve aquí y enlaza las cuatro secciones + Equipo.
- `api.ts`: PostgREST directo bajo RLS (`from('resources')`, `catalog_items`, `movement_concepts`, `species`, `predios`, `suppliers`, `supplies`, `organization_settings`, `organizations`), `rpc('recurso_en_uso')`, Storage `branding`. Errores: `unique` → "Ya hay … con ese nombre/código"; CHECK/trigger → texto bajo el campo; slug: `organizations_slug_guard` → "Ese enlace ya está en uso" / reservado.
- Páginas: `RecursosPage.vue` (filtro select por kind, `ListaApilada` + `MenuFila`: Editar…, Desactivar…/Reactivar; capa `RecursoCapa.vue`; confirmación con `recurso_en_uso`), `CatalogosPage.vue` (select de 14 catálogos; capas `CatalogoTipoCapa`, `ConceptoCapa`, `EspecieCapa`, `PredioCapa`, `ProveedorCapa`, `InsumoCapa`; Ocultar/Mostrar con confirmación corta), `AjustesPage.vue` (formulario 3 grupos; Guardar; salir con cambios pregunta), `PortalMarcaPage.vue` (formulario + `SelectorArchivo` + `LogoCapa` con recorte canvas + `SlugCapa` + vista previa con `BloqueMarca`).
- Guardias: no admin → `state-block denied` en cada página (mismo patrón).
- Primaria `page-primary` en compact; sin conexión y solo lectura: primaria deshabilitada con motivo, sin menú de fila.

## 4. Datos (`coco.data_contract`)

Ver `declaracion.md` → Traspaso. Reglas de presentación: capacidad con
unidad según kind (kg horno/molino, L resto); `liquid_class` solo colector;
"viene de plantilla" = `template_id != null` (se puede ocultar, no borrar;
el nombre sí se edita); contador `n/140` en el mensaje.

## 5. Verificación exigida

- pgTAP configuración (33 + 4 nuevos) · Vitest de las 6 piezas · Playwright
  `qa/evidencia-configuracion.mjs` (4 secciones × 4 anchos × 2 temas; alta
  de un tanque REAL `Tanque QA` y su desactivación, edición de un catálogo
  propio, guardado de ajustes y de marca con logo real a Storage, cambio de
  slug y vuelta al original — todo dejando la semilla como estaba o
  reseteando después) · zoom 200 %.
- Declaración de cumplimiento → compuerta Candidate.
