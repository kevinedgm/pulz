# Fase 4 · Interfaz base y configuración

> Sigue `PULZ_MAESTRO.md` §16 (Fase 4), §13 (interfaz), §11.1 (roles), §7.3
> (slug), §8.1 (Storage `branding`), §10.3 (catálogos e infraestructura) y
> `CLAUDE.md` (nunca Docker; migraciones "desde cero"; **toda pantalla empieza
> por `kiwi`**). Objetivo de la fase, literal de §16: *"un dueño nuevo, desde
> cero, configura su palenque y registra una carga inicial en un tanque sin
> ayuda; cada pantalla tiene su ronda de kiwi aprobada y su auditoría de
> coco; mora las documentó en el Design Hub; capturas en 390/1024/1440 px,
> claro y oscuro, sin desbordes."*
>
> **Estado (2026-09-27): aprobado por el dueño** — plan y orden (servidor →
> shell → configuración → arranque); `docs/DUDAS.md` #11 resuelto con
> **sesión automática tras la bienvenida** (entra en el bloque de servidor);
> la ronda del Design Hub HTML (tarea 7, encargo de mora a kiwi) **entra en
> esta fase** y se repite hasta que el resultado pase el estándar documental
> y mora lo publique. #12 (`--pend` en claro) sigue abierto: no bloquea.

## Qué entra y qué no

**Entra (§16 Fase 4):** shell de la app y navegación, tema claro/oscuro,
Configuración completa — recursos, catálogos, ajustes, portal y marca con
subida de logo — (Equipo ya existe: se integra al menú), y el **primer
arranque** "¿qué tienes hoy en tanques y tinas?". Más lo mínimo de PWA para
que el shell sea instalable (manifest, iconos, color de tema): la cola
offline **no** — es Fase 5.

**No entra:** Inicio/hoy con datos reales (tinas por medir, corridas
abiertas: Fase 5), captura por etapa, trazabilidad, cobro. Predios,
proveedores e insumos entran como parte de "catálogos" porque el esquema ya
los tiene y el productor los necesita en Fase 5.

## Lo que el esquema ya resuelve (no se inventa nada en la interfaz)

| Pantalla | Lee | Escribe | Quién (RLS real, 0013) |
|---|---|---|---|
| Recursos | `resources` (kind, code, type_item_id, capacity, capacity_policy, liquid_class solo colector, location, active) | PostgREST directo bajo RLS; el trigger `resources_check_type` valida el tipo | admin |
| Catálogos | `catalog_items` (por `catalog`), `movement_concepts`, `species` — copiados de plantillas al crear la empresa (§10.2) | insert/update bajo RLS; **nunca borrar**: `active = false` | admin |
| Predios · Proveedores · Insumos | `predios`, `suppliers` (tipo_proveedor), `supplies` (unidad_insumo) | PostgREST bajo RLS | admin y productor |
| Ajustes | `organization_settings` (record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision, rangos abv/brix) | update bajo RLS | admin |
| Portal y marca | `organizations` (name, state, brand_color, logo_path, welcome_message ≤140, slug) | update bajo RLS (`org_update`); cambio de slug → historial y 301 (§7.3, trigger de 0002) | admin |
| Primer arranque | recursos tipo tanque/tina/colector | `registrar_entrada(p_origen => 'carga_inicial', …)` (0015): crea lote y saldo con `idempotency_key` | admin y productor |

Configuración no es ledger: escribir catálogos y recursos por PostgREST con
RLS es exactamente lo que §8.2 permite ("captura simple… con políticas");
la carga inicial sí pasa por RPC porque crea lotes y saldos.

## Servidor primero (no depende de la compuerta de interfaz)

1. **`…0024_marca.sql`** — bucket público `branding` en `storage.buckets` y
   políticas de `storage.objects`: lectura pública; insert/update/delete solo
   al admin de la empresa y solo bajo el prefijo `<organization_id>/`. Límite
   de tamaño y tipos (`png`, `jpg`, `webp`, `svg` no: riesgo de script) en la
   política del bucket. Hoy el bucket **no existe** en las migraciones aunque
   `organizations.logo_path` y `portal_branding` ya lo asumen.
2. **Verificar con pgTAP** (`supabase/tests/configuracion.test.sql`): el
   admin crea/edita recursos y catálogos, el productor solo predios/
   proveedores/insumos, el operador nada; `active=false` en vez de borrar; el
   cambio de slug deja historial y el viejo redirige (`portal_branding`
   devuelve `redirect_to`); `registrar_entrada` con `carga_inicial` en tanque
   y en tina deja el saldo esperado.
3. **Storage smoke real** (`curl` con el JWT de Benito): subir un logo a
   `branding/<org>/logo.png`, verlo público, y que la dueña de Prueba B no
   pueda escribir en la carpeta de Cuatro Vientos.
4. **PWA mínima**: `vite-plugin-pwa` (ya instalado, sin configurar) con
   manifest (nombre, `theme_color` = `--ink-900`, `background_color` =
   `--canvas`, iconos desde `pulz-mark`), `display: standalone`, sin service
   worker de cacheo de datos todavía (Fase 5). `apps/web/wrangler.toml` sirve
   el manifest.

## Compuerta de interfaz (CLAUDE.md §3) — tres rondas de kiwi

Cada ronda: `kiwi` → **aprobación del dueño** → `lima` → `coco` → `mora-docs`,
igual que acceso/r01. Ninguna pantalla se toca antes de su aprobación.

**Ronda 1 · `design-hub/lab/shell/r01` — shell, navegación y tema.**
Brief: §13.1 (el menú sigue al proceso: Inicio · Maguey · Horneado ·
Fermentación · Destilación · Granel · Trazabilidad · Configuración solo
admin); móvil <640: navegación inferior, acción principal como botón
flotante, una columna; tablet/escritorio: menú lateral; tema claro/oscuro
siguiendo el sistema con opción manual; indicador de empresa y de "solo
lectura"; dónde vive "Cerrar sesión". Las secciones de proceso quedan como
**destinos vacíos con su estado "próximamente en tu palenque"**: la ronda
decide el shell, no las pantallas de Fase 5. Piezas candidatas al sistema:
`app-shell`, `bottom-nav`, `side-nav`, `page-header`, `fab`.

**Ronda 2 · `design-hub/lab/configuracion/r01` — Configuración.**
Cinco secciones sobre una misma estructura (lista + capa de tarea, reutilizando
`list-stack`, `task-layer`, `row-menu`, `segmented-choice`, `text-field`):
- Recursos: por tipo (hornos, molinos, tinas, alambiques, colectores,
  tanques); alta/edición con código, tipo (catálogo), capacidad y política,
  clase de líquido solo en colectores, ubicación; desactivar, no borrar.
- Catálogos: tipos de recurso, conceptos de movimiento (con su comportamiento
  visible: crea lote, pide resultado, pide contraparte), especies; predios,
  proveedores e insumos.
- Ajustes: los campos de `organization_settings` con su ayuda en lenguaje
  del palenque ("¿capturas puntas?", "modo de medición", "días esperados de
  fermentación", "hora del recordatorio", rangos de aviso).
- Portal y marca: nombre, estado, mensaje ≤140, color (solo acento; la
  regla del contraste la impone la interfaz), **logo** (subida con recorte
  cuadrado y reducción a 512 px en el navegador), **cambio de slug** con
  confirmación ("el enlace viejo seguirá funcionando; nadie más podrá
  usarlo") y vista previa del portal.
- Equipo: ya construido; solo se enlaza desde aquí.
Piezas candidatas: `select` (catálogo nativo estilizado), `number-field`
(capacidad, rangos), `switch`, `file-picker` (logo), `color-field`.

**Ronda 3 · `design-hub/lab/arranque/r01` — Primer arranque "¿Qué tienes hoy?"**
Flujo para el dueño nuevo, el día uno: por cada tanque, tina y colector
que tenga (o que cree ahí mismo), cuántos litros hay y a qué grado; un paso
por recurso, se puede saltar y retomar; al final, el resumen de saldos y
"listo, ya puedes registrar". Cada carga es `registrar_entrada` con
`carga_inicial` e `idempotency_key` propia (reintentar no duplica). Se
dispara solo cuando la empresa no tiene lotes; después vive en Granel como
"Carga inicial". Dominio: §4.6, §5.1, 0015 y `docs/DUDAS.md` #7 (tina que
ya fermentaba: entrada `fermentado` sin formulación).

Orden: Ronda 1 primero (las otras dos viven dentro del shell). Rondas 2 y 3
pueden ir en paralelo en kiwi, pero coco construye 2 antes que 3 (el
arranque usa las piezas de Configuración).

## Tareas, en orden

1. Servidor 1–4 de arriba (migración `0024`, pgTAP, smoke de Storage, PWA
   mínima). `supabase db reset --linked --yes` + `db query --linked -f` +
   `db advisors --linked` con 0 errores.
2. `kiwi` ronda **shell/r01** → aprobación → `lima` → `coco` (shell en
   `apps/web/src/app/` + piezas en `shared/ui/`, guardias por rol en el
   menú, tema) → `mora-docs`.
3. `kiwi` ronda **configuracion/r01** → aprobación → `lima` → `coco`
   (`apps/web/src/modules/configuracion/` con `api.ts` por sección; subida
   de logo a Storage; cambio de slug) → `mora-docs`.
4. `kiwi` ronda **arranque/r01** → aprobación → `lima` → `coco`
   (`apps/web/src/modules/arranque/`, `registrar_entrada`) → `mora-docs`.
5. Prueba de aceptación de punta a punta (Playwright, real contra el
   proyecto alojado): `signup-company` crea una empresa nueva (`prueba-d`),
   el titular entra, crea un tanque, sube un logo, registra una carga
   inicial de 300 L a 47 % y ve el saldo. `db reset --linked` la borra.
6. Evidencia en 1440/1024/768/390 × claro/oscuro para cada pantalla
   (`qa/evidencia-*.mjs`) y zoom 200 % aproximado; actualizar `ESTADO.md`,
   `DECISIONES.md`, `DUDAS.md`.
7. (Si el dueño quiere en esta fase) ronda `lab/hub/r01` de kiwi con el
   encargo de mora para darle shell HTML al Design Hub. No bloquea.

## Archivos que se tocan

- `supabase/migrations/20260927000024_marca.sql`, `supabase/tests/configuracion.test.sql`.
- `apps/web/vite.config.ts` (PWA), `apps/web/public/` (iconos, manifest),
  `apps/web/src/app/` (shell, router con menú por rol),
  `apps/web/src/shared/ui/` (piezas nuevas que lima registre),
  `apps/web/src/modules/{configuracion,arranque}/`, `apps/web/src/modules/inicio/`
  (Inicio como destino del shell, aún sin datos de proceso).
- `design-hub/lab/{shell,configuracion,arranque}/r01/`, `design-hub/system/registry.json`,
  fichas nuevas en `design-hub/`.
- `.claude/skills/lima/profiles/pulz.md` (`coco.data_contract` crece con
  Recurso, ElementoCatalogo, Ajustes, Marca, CargaInicial).

## Cómo se comprueban los criterios de aceptación de §16 (Fase 4)

| Criterio | Comando / evidencia |
|---|---|
| Un dueño nuevo configura su palenque y registra una carga inicial sin ayuda | Playwright de punta a punta (tarea 5) desde `signup-company` hasta el saldo del tanque, con una empresa creada en la prueba |
| Cada pantalla con ronda de kiwi aprobada y auditoría de coco | `design-hub/lab/*/r01/{declaracion,orden-coco,coco-declaracion,lima-compuerta}.md` + aprobación del dueño en el chat |
| mora documentó en el Design Hub | fichas en `design-hub/` con estado del registry |
| Capturas 390/1024/1440 claro y oscuro sin desbordes | `qa/evidence/<ronda>/` (más 768 por el perfil) + `zoom-*.mjs` |
| Aislamiento de la marca y Storage | pgTAP `configuracion.test.sql` + smoke de Storage con dos empresas |

## Riesgos y dudas que esta fase va a abrir

- **Storage en el plan del proyecto**: si el bucket público o las políticas
  de `storage.objects` no se pueden crear por migración en el plan actual,
  se crean desde el panel y se documenta (como el hook de intentos).
- **Recorte de logo en el navegador**: sin librería nueva si se puede con
  `canvas`; si hace falta una, se decide en la ronda (peso de la PWA).
- **Cambio de slug**: `portal_branding` ya redirige, pero la PWA instalada
  con el slug viejo debe seguir funcionando (la Pages Function da 301 —
  verificar que el `start_url` del manifest lo tolera).
- **Roles §11.1 "propuesta inicial"**: la interfaz la respeta tal cual está
  en la RLS (admin para recursos/catálogos/ajustes/marca; admin y productor
  para predios/proveedores/insumos y carga inicial). Si el dueño quiere otra
  asignación, es cambiar 0013, no la interfaz.
- **Piezas nuevas del sistema** (select, number-field, switch, file-picker,
  color-field): lima decide qué es sistema y qué es local; no se adelanta.

## Decisiones que necesito del dueño antes de arrancar

1. Aprobar este plan (orden: servidor → shell → configuración → arranque).
2. `docs/DUDAS.md` #11 (bienvenida con sesión automática) y #12 (`--pend` en
   claro): no bloquean, pero si se deciden ahora entran en la ronda del shell.
3. Si el Design Hub HTML (tarea 7) entra en esta fase o se pospone.

## Resultados reales (2026-09-27) — servidor, tareas 1–4

| Qué | Comando real | Resultado |
|---|---|---|
| `0024_marca.sql` (bucket `branding` + 4 políticas en `storage.objects`) | `supabase db reset --linked --yes` | **OK**: se crea por migración; no hizo falta el panel |
| pgTAP de configuración | `supabase db query --linked -f supabase/tests/configuracion.test.sql` | **33/33**: RLS por rol (admin / productor / operador / otra empresa), `active=false` en vez de borrar (`DELETE` ni siquiera está concedido), slug viejo → historial + `redirect_to`, carga inicial idempotente con saldo 300 L, bucket y políticas |
| Storage real | `curl` con JWT de Benito y de la dueña de B | **OK**: sube png (200) · lectura pública (200, 9.8 KB) · otra empresa → 403 `row-level security` · SVG → 415 `invalid_mime_type` · sin sesión → 400 · borrar propio → 200 |
| DUDAS #11 sesión automática | `manage-member` alta enlace → `set-password` con token → `auth/v1/token` con `login_email` | **OK**: `{ok, slug, login_email}` y sesión 200. `BienvenidaPage` entra sola; si falla, «Ir a entrar» |
| PWA mínima | `pnpm build` | **OK**: `manifest.webmanifest`, `sw.js` (precache de la app, 34 entradas), iconos 192/512/maskable/apple desde la marca PULZ; `favicon.svg` ya no es el de Vite |
| Advisors | `supabase db advisors --linked` | 0 errores; WARN esperados (RPC `security definer` por diseño §12; contraseñas filtradas #10) |
| Tipos · lint · Vitest | `vue-tsc -b` · `pnpm lint` · `vitest run` | ✔ · 0/0 · 33/33 |

Nota: el smoke dejó a `prueba.auto` en Cuatro Vientos del proyecto de
desarrollo; el siguiente `db reset --linked` lo borra.

## Resultados reales (2026-09-27) — interfaz, tareas 2–6

| Criterio (§16 Fase 4) | Comando real | Resultado |
|---|---|---|
| Un dueño nuevo, desde cero, configura su palenque y registra una carga inicial en un tanque sin ayuda | `node design-hub/qa/e2e-fase4.mjs` (signup-company real → portal → Inicio «¿Qué tienes hoy?» → arranque: Tanque 1 creado → 300 L @ 47 guardados → Listo → Inicio «Hoy» → logo a Storage → Recursos «300 L dentro» → portal público con logo) | **OK** a la primera. `prueba-d-<sufijo>` queda en el proyecto de desarrollo hasta el `db reset`. **Nota:** Auth exige confirmar el correo; la prueba lo simula por SQL con el CLI (en producción llega por correo): se declara, no se finge |
| Cada pantalla con ronda de kiwi aprobada y auditoría de coco | `lab/{shell,configuracion,arranque}/r01/` con brief, wireframe, declaración, orden de lima, declaración de coco y compuerta de lima (aprobaciones automáticas per CLAUDE.md §4, anotadas en DECISIONES) | **OK** |
| mora documentó en el Design Hub | `design-hub/README.md` + 15 fichas nuevas (6 shell, 7 configuración, 2 pantallas) | **OK** (Markdown; el shell HTML del Hub es la ronda `lab/hub/r01`) |
| Capturas 390/1024/1440 claro y oscuro sin desbordes | `qa/evidence/{shell,configuracion,arranque}-r01/` = 50 + 67 + 13; `zoom-acceso.mjs` 18/18 | **OK** (más 768 por el perfil) |
| pgTAP · Vitest · lint · tipos | `configuracion.test.sql` 37/37 · `vitest` 52/52 · eslint 0/0 · `vue-tsc` ✔ | **OK** |
