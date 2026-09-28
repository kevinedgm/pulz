# Configuración · `configuracion`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/configuracion/r01` |
| Código | `apps/web/src/modules/configuracion/{routes.ts, api.ts, components/SoloAdmin.vue, pages/*}`; base: `supabase/migrations/20260927000025_recurso_en_uso.sql` |
| Rutas | `/e/:slug/configuracion` (índice) · `/recursos` · `/catalogos` · `/ajustes` · `/portal` — todas en el shell, destino `configuracion`, solo admin |
| Pruebas | `supabase/tests/configuracion.test.sql` (37/37) · `qa/evidencia-configuracion.mjs` |
| Evidencia | `qa/evidence/configuracion-r01/*` |

## Propósito

Que el administrador defina con qué trabaja el palenque (recursos, catálogos),
cómo mide y avisa (ajustes) y cómo se ve su portal (marca, logo, enlace) —
sin manual y sin borrar nunca nada (`active = false`).

## Secciones

| Sección | Lee / escribe (PostgREST bajo RLS 0013) | Capas |
|---|---|---|
| **Recursos** | `resources` + `recurso_en_uso` (0025) + `catalog_items` (tipos) | Agregar/Editar recurso (tipo de recurso solo al crear; código, tipo del catálogo, capacidad con unidad por kind, política estricta/flexible/libre, clase de líquido solo colector, ubicación) · ¿Desactivar? (avisa litros dentro y ciclos abiertos) |
| **Catálogos** | `catalog_items` (9 catálogos de tipo/unidad), `movement_concepts`, `species`, `predios`, `suppliers`, `supplies` | Una capa por tabla real (nombre; concepto: dirección, contraparte y, solo entrada, lote de origen / crea lote / pide resultado; especie: científico; predio: municipio, dueño, notas; proveedor: tipo, teléfono, notas; insumo: unidad) · ¿Ocultar? |
| **Ajustes** | `organization_settings` (10 campos en 3 grupos) | — (formulario; salir con cambios pregunta) |
| **Portal y marca** | `organizations` (name, state, brand_color, welcome_message, logo_path, slug) + Storage `branding` | Recortar el logo (canvas, cuadrado 512) · Cambiar el enlace del portal (slug; el viejo redirige) |

## Componentes usados

`app-shell` · `list-stack` · `row-menu` · `task-layer` · `button` ·
`text-field` · `number-field` · `select` · `switch` · `color-field` ·
`file-picker` · `segmented-choice` · `status-chip` · `state-block` · `banner`
· `brand-block` (vista previa = la misma marca que ve la gente).

## Estados

Carga (esqueleto) · vacío por sección/catálogo · error de carga con
Reintentar · error de guardado bajo el campo (duplicado, CHECK, trigger de
tipo, slug tomado/reservado, logo tipo/tamaño) · sin permiso (no admin por
URL) · sin conexión / solo lectura (primaria deshabilitada con motivo, sin
menú de fila) · confirmación (desactivar con aviso de uso; ocultar; cambiar
enlace) · guardado (`role=status`).

## Criterios verificados

Capturas en 4 anchos × 2 temas; en 1440/claro **escrituras reales y
deshechas**: alta de «Tanque QA» y desactivación; aviso «tiene N L dentro»
en Tanque 2; especie propia creada y ocultada; ajustes guardados dos veces
(ida y vuelta); logo real subido a `branding/<org>/logo.png` y retirado;
enlace cambiado a `cuatro-vientos-qa` y vuelto a `cuatro-vientos`.

## No verificado

Fotos de teléfono con orientación EXIF (el recorte usa el centro; una foto
rotada saldría rotada); selects nativos en iOS/Android; reordenar catálogos
(no entra); productor editando predios/proveedores (solo admin en esta
ronda).
