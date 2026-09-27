# Orden de construcción para 🥥 coco · Acceso · r01

**De:** lima (gobernanza) · **Fecha:** 2026-09-27 · **Ronda aprobada por el dueño:** `design-hub/lab/acceso/r01/` (estructura congelada: anatomía, orden, jerarquía, densidad, acciones visibles, estados y comportamiento responsive **no se rediseñan**; coco aplica el sistema PULZ).
**Perfil:** `.claude/skills/lima/profiles/pulz.md` · **Registry:** `design-hub/system/registry.json` (14 entradas `draft`, owner lima, ronda `lab/acceso/r01`).
**Decisión de producto ya tomada por el dueño:** crear la vista solo-admin `equipo_miembros` (hallazgo alto #1 de `hallazgos.md`).

## 1. Clasificación y reutilización

El registry estaba vacío: todo lo del sistema nace `new`/`draft`. Nada se marcó `reuse`/`extend` porque no existía nada.

| Pieza (id registry) | Tipo | Decisión | Vive en | Se usa en |
|---|---|---|---|---|
| `button` | component | new · sistema | `apps/web/src/shared/ui/` | todas |
| `text-field` | component | new · sistema | shared/ui | portal, equipo (alta, buscar) |
| `password-field` | component (compone `text-field` + `button`) | new · sistema | shared/ui | portal, cambio, bienvenida, alta dictada |
| `segmented-choice` | component | new · sistema | shared/ui | equipo (rol, entrega) |
| `status-chip` | component | new · sistema | shared/ui | equipo |
| `row-menu` | component (compone `button`) | new · sistema | shared/ui | equipo |
| `banner` | pattern | new · sistema | shared/ui | portal, cambio, bienvenida, equipo |
| `state-block` | pattern (compone `button`) | new · sistema | shared/ui | portal (red), bienvenida (enlace), equipo (vacío/error/sin permiso) |
| `task-layer` | pattern (drawer ⇄ hoja) | new · sistema | shared/ui | equipo (alta, acceso creado) |
| `list-stack` | pattern (tabla ⇄ tarjetas) | new · sistema | shared/ui | equipo |
| **bloque de marca del portal** | product-application | **local** | `modules/acceso/` | portal, cambio, bienvenida |
| **formulario de acceso** | product-application | local | modules/acceso | portal |
| `acceso-portal`, `acceso-cambio-contrasena`, `acceso-bienvenida`, `equipo` | product-application (pantallas) | local, registradas para ciclo de vida | modules/acceso, modules/equipo | — |

Extracción con moderación (source-of-truth.md): `banner`, `state-block`, `task-layer`, `list-stack` y `row-menu` se registran como patrones porque **ya aparecen en ≥2 contextos dentro de esta ronda** y son agnósticos del dominio. El bloque de marca y el formulario de acceso se quedan locales: solo existen en el portal.

## 2. Contratos (derivados de la estructura congelada; el detalle está en `registry.json → contract`)

Reglas transversales de todos los contratos:
- **Tokens: únicamente `apps/web/src/shared/ui/tokens.css`** (`--ink-900/700/100`, `--clay-300/100`, `--canvas`, `--surface`, `--text`, `--muted`, `--border`, `--ok/--pend/--late/--info` y sus `-bg`, `--shadow`, `--font`, `--r-sm…--r-2xl`, `--r-pill`, `--tap` (44px), `--sp-1…--sp-10`, `--brand-*`). Ningún valor nuevo. Si falta un token, coco lo propone como candidato, no lo hardcodea.
- **Ley de color del perfil**: tinta `--ink-900` solo para acciones primarias, títulos y barras; barro `--clay-300` para acentos y fondos de icono; semánticos solo en estados y **nunca solos** (forma + texto). El `brand_color` de cada empresa (`portal_branding`) entra únicamente como acento (logo/franja fina) sobre `--canvas`/`--surface`: **nunca como fondo de texto ni de botón** (contraste no garantizable, uso bajo el sol).
- **Tipografía**: `--font` (Atkinson Hyperlegible Next → sistema), base 16px; campos de acceso en compact 18px.
- **A11y (WCAG 2.2 AA + campo)**: contraste alto, foco visible (`outline` 3px en `--ink-900`), targets `--tap`, teclado completo, sin depender del color, texto ampliable 200%, textos cortos.
- **API (component-api.md)**: props por intención (`intent`, `size`, `adapt`, `loading`, `disabled`), nunca props de estilo; uniones cerradas en TS; `href`/`to` → enlace, si no → botón; estado controlado por la página (el componente no decide cuándo cargar).

Contratos por pieza:

| Pieza | Anatomía | Variantes / tamaños | Estados | Adaptativo | A11y y contenido |
|---|---|---|---|---|---|
| `button` | texto (+ icono opcional con nombre) | intent primary·secondary·quiet·danger; adapt default·page-primary | default·hover·focus·pressed·loading·disabled(con motivo) | page-primary = barra inferior persistente en compact (`env(safe-area-inset-bottom)`, teclado virtual), en línea en ≥600 | 1 primaria por vista; danger separada + confirmación; nunca button para navegar |
| `text-field` | label visible · control · ayuda · error | size md(44)·lg(52) | default·focus·disabled·error | — | `aria-describedby` a ayuda/error; inputmode/autocapitalize/autocomplete por intención; texto largo con scroll |
| `password-field` | text-field type=password + mostrar/ocultar (aria-pressed) | igual a text-field | + revealed | — | autocomplete current-/new-password; mínimo 8 lo valida el formulario |
| `segmented-choice` | radiogroup de 2–3 opciones con texto | — | default·selected·focus·disabled | ancho completo en compact | flechas de teclado; selección por forma + peso |
| `status-chip` | punto de forma + texto | on·draft·off·partial | — | — | nunca color solo |
| `row-menu` | botón "⋯ Acciones" con nombre por fila + menú ≤4 | — | closed·open·focus | popover en ≥600; hoja inferior en compact | Esc/atrás cierra y devuelve el foco; acciones condicionales |
| `banner` | franja role=status: negrita + frase | offline·readonly | — | igual en todos | un solo banner; `--pend-bg`/`--info-bg` + `--text` |
| `state-block` | título + frase + ≤1 acción, máx 520 | empty·error·denied | — | — | error con role=alert + Reintentar |
| `task-layer` | dialog aria-modal: título, cuerpo, acciones; scrim | — | open·closed | drawer derecho 420 en ≥600; hoja ≤92% con `--r-2xl` arriba en compact; **misma instancia** | foco entra/queda/vuelve; Esc y atrás cierran; Cancelar con cambios pregunta |
| `list-stack` | table semántica | — | — | tabla en ≥1024; tarjetas apiladas con rótulo en ≤1023 | filas ≥48; acciones al final; búsqueda + paginación por 50 declaradas |

Pantallas (product-application): la anatomía exacta está en `index.html` (r01) y las reglas en `registry.json`. Resumen de lo no negociable:
- **Portal**: marca (logo 56, nombre 2 líneas con elipsis, mensaje ≤140 completo) → un campo "Usuario o correo" (lg en compact) → contraseña → "Entrar" (page-primary) → "¿No puedes entrar?" (quiet; con `@` → recuperación por correo de Auth; sin `@` → "Pídele a tu encargado que te la restablezca"). Rechazo: **siempre** "Usuario o contraseña incorrectos" bajo el formulario, usuario conservado, foco a contraseña. `read_only` → banner readonly. Sin fila de `portal_branding` → **404 idéntico sin marca**.
- **Cambio obligatorio**: "Elige tu contraseña" + 2 password-field + "Guardar contraseña" (page-primary) + "Cerrar sesión" (quiet). Sin Cancelar/Volver.
- **Bienvenida**: "Te dieron acceso a {empresa}" + 2 password-field + "Crear contraseña y entrar". Enlace inválido/usado/vencido → state-block con "El enlace no es válido o ya se usó" + "Pídele a tu encargado que te mande uno nuevo" + enlace al inicio de sesión.
- **Equipo**: cabecera "Equipo" + una frase; primaria "Agregar persona" (page-primary); buscar; list-stack (Nombre · Usuario · Rol · Estado · Acciones) con status-chip; row-menu (Cambiar rol… · Reenviar enlace [invitado] · Desbloquear [bloqueado] · Suspender… [danger, confirmación corta] / Reactivar). Alta en task-layer: Nombre · Usuario para entrar (ayuda: minúsculas, números, punto o guion, 3–30; "solo se usa para entrar, no es un correo") · Rol (segmented 3) · ¿Cómo le entregas el acceso? (segmented 2: Enlace por WhatsApp / Contraseña dictada → password-field temporal) · "Crear acceso" + Cancelar. Acceso creado: enlace en bloque monoespaciado + "Copiar enlace" (primaria) + "Compartir…" (secundaria, solo si Web Share existe) + feedback "Copiado ✓" ≥3 s; dictada: "Dile su usuario y la contraseña; la primera vez tendrá que cambiarla" + Entendido. Vacío: "Solo estás tú" con la primaria dentro (la de cabecera baja a secundaria). Sin permiso: "Solo el administrador puede ver el equipo. Pídele a {titular}…" sin botón.

## 3. Contrato de datos (propuesta de kiwi, aprobada; coco lo registra en `coco.data_contract` del perfil)

- `portal_branding(p_slug)` → `{organization_id, slug, name, logo_path, brand_color, welcome_message, read_only, redirect_to}` (anon). Logo público en `storage/v1/object/public/branding/<logo_path>`.
- `mis_membresias` (vista, authenticated) → `{organization_id, slug, name, brand_color, logo_path, role, status, username, must_change_password, read_only, cancelled}` para `auth.uid()`.
- **`equipo_miembros` (NUEVA, aprobada)**: vista solo-admin con `{organization_id, user_id, full_name, username, role, status, must_change_password, locked_until, invitation_expires_at, invitation_used}`; `security_invoker` + política/función que solo devuelva filas si `has_role(organization_id, {admin})`. Implementación: migración "desde cero" nueva `…0023_equipo_miembros.sql` (CLAUDE.md §2), grant select a authenticated, pgTAP: el productor no ve nada, el admin de B no ve A.
- Auth: `supabase.auth.signInWithPassword({ email })` con correo real si trae `@`, si no `${usuario}@${organization_id}.usuarios.pulz.mx` (`member_login_email`, 0012). **Directo**, sin función intermedia (§7.5).
- Edge Functions: `manage-member` {accion: alta(username, nombre, rol, modo, contrasena?) → {user_id, username, enlace?} · rol · estado · desbloquear · reenviar} · `set-password` {contrasena, token?} → {ok, slug?}. Errores del servidor: `{error:{codigo, mensaje}}`; el cliente muestra `mensaje` tal cual salvo login (texto único).
- Guardias del router (`apps/web/src/app/router.ts`): sin sesión → portal del slug; sesión y slug ∉ `mis_membresias` → 404 idéntico; `must_change_password` → cambio obligatorio antes que nada; `read_only` → modo lectura (ocultar escritura; la base rechaza igual); Equipo solo `role = admin`.

## 4. Orden de trabajo (R3 en producción + F3 en el Hub)

1. **Base primero**: migración `equipo_miembros` + pgTAP (aislamiento y solo-admin) + `db reset --linked` + correr los tests como en Fase 1–2.
2. **Sistema** (`apps/web/src/shared/ui/`): `button`, `text-field`, `password-field`, `segmented-choice`, `status-chip`, `banner`, `state-block`, `task-layer`, `list-stack`, `row-menu` — Vue 3 `<script setup lang="ts">`, CSS con variables de `tokens.css`, tipos cerrados. Cada uno con su demo F3 en `design-hub/Components/<pieza>/index.html` (+ `Patterns/` para los patrones) que muestre estados y los tres espacios — es requisito del Candidate Gate ("interactive demo in the Hub").
3. **Pantallas** (`apps/web/src/modules/acceso/{pages,components,api.ts,routes.ts,store.ts,__tests__}` y `modules/equipo/`): portal, cambio obligatorio, bienvenida, equipo. Cliente Supabase de `shared/supabase/`; mapeo de rechazos al texto único en `shared/supabase/errores.ts`.
4. **Guardias** en `router.ts` (arriba).
5. **Pruebas**: Vitest de integración contra el proyecto alojado (login por usuario y por correo con la semilla; los cuatro rechazos → mismo texto; guardias), Vitest de componentes (estados, a11y básica), y evidencia en `design-hub/qa/evidence/` a 1440 / 1024 / 768 / 390 (claro y oscuro) para la auditoría.
6. **Auditoría de coco** (R0 sobre lo construido) y **declaración de cumplimiento** con lo verificado y lo no verificado → vuelve a lima para el Candidate Gate.

## 5. Criterios que lima va a revisar en el Candidate Gate

Anatomía = la de r01 (sin rediseño) · variantes justificadas (ninguna extra) · todos los estados del panel de r01 · contrato responsive cumplido (page-primary, hoja/drawer, lista apilada) · a11y base (teclado, foco, contraste con tokens, 44px, 200%, texto largo) · demo interactiva en el Hub por pieza · pasadas critique → distill → adapt → polish registradas con su provenance real (`executed` / `degraded` / `manual-playbook`, nunca un ✓ inflado).

## 6. Fuera de alcance de esta orden

Registro de empresa (`signup-company` tiene servidor, no pantalla: otra ronda de kiwi) · recuperación de contraseña del titular (flujo estándar de Auth) · Portal y marca en Configuración · navegación inferior de la app · instalación de la PWA.
