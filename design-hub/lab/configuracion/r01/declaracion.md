# Declaración de cumplimiento · CONFIGURACIÓN · r01

| Campo | Valor |
|---|---|
| Ruta | R1 (una dirección estructural) |
| Fidelidad | F2 (contenido real de la semilla, estados, responsive; sin sistema visual) |
| Pregunta de diseño | ¿Puede un dueño nuevo dejar listo su palenque en su primera sesión sin manual, y cambiar una cosa después en ≤3 toques desde Inicio? |
| Artefactos | `brief.md` (brief + 3 flujos) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

- `references/wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md` (formularios: etiqueta arriba, validación al salir, una primaria; capas para tareas acotadas).
- WCAG 2.2 AA: targets ≥44 (select, switch, color, fila de menú), 1.4.4 texto 200 %, 3.3.1/3.3.3 errores con causa y solución bajo el campo, 2.4.3 foco en capas.
- Esquema real (0002, 0004, 0005, 0006, 0013, 0024) y `configuracion.test.sql`: cada campo del wireframe existe en una tabla; los CHECK y triggers son los mensajes de error.
- shell/r01 (índice de Configuración, capas con `task-layer`), acceso/r01 (`MarcaPortal` para la vista previa).

## Desviaciones del protocolo

- Ninguna. Kit inline (copia en `vendor/`).

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 0 avisos.
- Chromium (Playwright): **156 combinaciones** (3 espacios × 4 secciones × 13 estados): sin desborde del marco, ≤1 primaria por vista (la capa abierta define su propia vista), 0 controles <44 px, 0 errores JS. Dos defectos corregidos en la ronda: la cabecera conservaba su primaria en el estado de error (dos primarias) y la vista previa del portal fijaba 360 px en el marco de 390.
- Estados representados: default · carga · vacío · error (carga y guardado) · sin permiso · sin conexión · solo lectura · contenido largo · alta/edición · acciones de fila · confirmación · cambiar enlace · recorte de logo.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Lista de sección (recursos, catálogos) | apilada: una tarjeta por fila con rótulos | apilada (con menú lateral 200 no caben 5 columnas) | tabla | legibilidad; cero desborde | `list-stack` existente (≤1023 apila) | menú de fila bajo la fila en todos |
| Cabecera de sección (primaria + buscar + filtro select) | primaria a la barra inferior; buscar y select a ancho completo | en línea | en línea | alcance del pulgar; una primaria | `button adapt=page-primary` | — |
| Capa de alta/edición/confirmación/slug/logo | hoja inferior ≤92 % | drawer 440 | drawer 440 | contexto visible detrás | `task-layer` (misma instancia) | Esc/atrás cierra; con cambios pregunta; foco vuelve |
| Formularios (ajustes, portal) | una columna; pares min/máx apilados | una columna; pares en dos columnas | dos columnas en los pares | campos numéricos cortos | grid `cf-fila` | conserva valores al cambiar de tamaño |
| Select (catálogo, tipo, filtro) | nativo a ancho completo, 44 px | ≤320 px | ≤320 px | >3 opciones no es segmento | select nativo estilizado con tokens | — |
| Switch | fila texto + interruptor 44 px | igual | igual | estado por forma + texto | `role=switch` | — |
| Vista previa del portal | ancho completo | 360 px | 360 px | la misma marca que ve la gente | reutiliza `MarcaPortal` | — |
| Logo | caja 96 + botones apilados | en línea | en línea | — | `file-picker` + recorte canvas | — |

## Comprobaciones NO ejecutadas

- Recorte real de imágenes (canvas, EXIF): se decide en coco con fotos de teléfono.
- Selects nativos en iOS/Android (la hoja del sistema): no hay dispositivo.
- Zoom nativo 200 %; lectores de pantalla.
- Comprobación de "recurso en uso" antes de desactivar: no existe la función (hallazgo alto 1 → lima/coco).

## Hallazgos

Ver `hallazgos.md`: 2 altos (función `recurso_en_uso` para avisar antes de desactivar — Claude decide que entra en esta fase; capa por tabla real, no formulario dinámico), 3 medios (productor y Configuración; 5 piezas candidatas al sistema; recorte del logo), 2 bajos.

## Traspaso

- **→ lima:** piezas candidatas al **sistema**: `select` (nativo estilizado, 44 px, etiqueta arriba, ayuda/error como text-field), `number-field` (inputmode decimal/numeric, unidad opcional a la derecha, min/máx validados al salir), `switch` (role=switch, texto a la izquierda, ayuda), `color-field` (input type=color 44 px + hex visible y editable), `file-picker` (botón "Subir…" + nombre/preview + quitar; el recorte es local del portal). **Reutiliza:** `list-stack`, `row-menu`, `task-layer`, `button`, `text-field`, `segmented-choice` (política 3, dirección 2, modo 2, folio 2), `status-chip` (activo/inactivo, visible/oculto), `state-block`, `banner`, `MarcaPortal` (local de acceso: se vuelve pieza compartida entre acceso y configuración → lima decide si sube al sistema como `brand-block`). **Local (product-application `configuracion`):** las 4 páginas, las capas por tabla (`RecursoCapa`, `CatalogoCapa` por tabla, `SlugCapa`, `LogoCapa`), el recorte. **Base:** función `recurso_en_uso(p_org)` (solo lectura: por recurso, saldo actual y ciclos abiertos) — migración "desde cero" nueva `0025`.
- **Datos (para `coco.data_contract`):** `Recurso = resources` (id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class?, location?, active); `ElementoCatalogo = catalog_items` (catalog, name, active, template_id? — plantilla = no editable el nombre? **no**: editable; solo se distingue por `template_id` para "viene de plantilla"); `Concepto = movement_concepts`; `Especie = species`; `Predio`, `Proveedor`, `Insumo`; `Ajustes = organization_settings` (10 campos); `Marca = organizations` (name, state, brand_color, logo_path, welcome_message, slug) + `organization_slug_history`; `RecursoEnUso = {resource_id, saldo_l, ciclos_abiertos}` (propuesta).
- **→ coco:** `apps/web/src/modules/configuracion/{pages,components,api.ts}`; rutas `/e/:slug/configuracion/{recursos,catalogos,ajustes,portal}` con `meta.shell`, destino `configuracion`; Storage con `supabase.storage.from('branding').upload(\`${org}/logo.${ext}\`, blob, {upsert:true})`; slug por `update organizations set slug` (trigger) + `router.replace` al slug nuevo.
- **→ mora:** nada hasta que coco implemente.

## Criterios observables para la aprobación

Sin desborde en 1440/768/390; una primaria por vista; targets ≥44; cada campo del wireframe mapea a una columna real; los errores del wireframe son los CHECK/unique/trigger reales; la misma tarea (dar de alta un tanque) se completa en cada modo.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) con las decisiones de `hallazgos.md` anotadas en `docs/DECISIONES.md` → lima → coco → mora.
