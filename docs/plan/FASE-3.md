# Fase 3 · Portal, acceso y equipo

> Sigue `PULZ_MAESTRO.md` §7, §8.1 (Edge Functions, no Worker), §13.2 #1,
> §15 y §16, más `CLAUDE.md` (nunca Docker; migraciones "desde cero";
> **toda interfaz empieza por `kiwi`**). Objetivo: que una empresa entre por
> `pulz.mx/e/<slug>` con su marca, que el titular entre con correo y el
> colaborador con usuario simple, que el administrador dé de alta
> colaboradores (contraseña dictada o enlace de bienvenida), y que el freno
> de intentos, las guardias del router y la Pages Function del portal
> funcionen — todo probado contra el proyecto alojado.
>
> **Estado (2026-09-27): aprobado. Servidor (tareas 1–8) implementado y
> verificado contra el proyecto alojado; interfaz detenida en la compuerta
> de `kiwi` esperando al dueño.** Resultados reales al final del documento.
> Es la **primera fase con interfaz**: las pantallas no se construyen hasta
> que el dueño apruebe la ronda de `kiwi` (compuerta explícita abajo).

## Cómo se hace sin Docker: confirmado con el CLI real

| Necesidad | Confirmado en `supabase --help` (2.118.0) |
|---|---|
| Desplegar Edge Functions | `supabase functions deploy --use-api` — "Bundle functions server-side without using Docker" |
| Habilitar el hook de intentos (§7.5) | `supabase config push` — "Pushes the properties your local config.toml declares to the linked project"; `supabase config diff` para ver el cambio antes |
| Secretos de las funciones | `supabase secrets set NAME=VALUE` (o `--env-file`) |
| Probar las funciones | No hay `functions serve` sin Docker: las pruebas de integración pegan a las funciones **desplegadas** en el proyecto alojado |
| Pages Function del portal | `wrangler` ya está instalado (Fase 0); se prueba con Vitest + `unstable_dev`/Miniflare de wrangler, en local, sin Docker |

## Compuerta de interfaz (CLAUDE.md §3)

Las tres pantallas de §13.2 #1 — **portal + inicio de sesión**, **cambio
obligatorio de contraseña**, **bienvenida por enlace** — pasan por
`kiwi` → `lima` → `coco` → `mora-docs`. Orden real:

1. `kiwi`: brief funcional, user flow (titular vs. colaborador, dictada vs.
   enlace, rechazos idénticos, solo lectura, 404), wireframes F0–F2 en
   `design-hub/lab/acceso/rNN/`. **Se muestra al dueño y se espera su
   aprobación.** Ninguna pantalla se toca antes.
2. `lima`: clasifica piezas (qué es del sistema: campo de texto, botón
   primario, aviso, cabecera de marca), registra el contrato en el registry.
3. `coco`: alta fidelidad con `tokens.css` y el sprite real, implementación
   en Vue en `apps/web/src/modules/acceso/`, auditoría.
4. `mora-docs`: documenta en el Design Hub solo lo implementado y verificado.

El dominio de esas pantallas sale de §7 y del esquema (`portal_branding`,
`organization_members.must_change_password`, `member_invitations`), nunca
de suposiciones para que un layout se vea completo (§13.4).

## Tareas, en orden

**Servidor primero (no depende de la compuerta de interfaz):**

1. **Contraseñas en la semilla** para poder probar login: `encrypted_password
   = crypt('…', gen_salt('bf'))` (pgcrypto, formato bcrypt que usa GoTrue)
   para los cuatro usuarios de Cuatro Vientos y la dueña de B. Contraseñas de
   prueba fijas, documentadas en `seed.sql` (es un proyecto de desarrollo que
   se resetea; no son secretos).
2. **`…0022_acceso.sql`**: RPC `bajar_must_change_password()` (la baja el
   servidor, §7.6: security definer, solo para el propio `auth.uid()` y solo
   si Auth confirma que ya cambió — se llama desde la Edge Function
   `set-password`, no desde el navegador); vista mínima `mis_membresias`
   (slug + rol de las empresas de `auth.uid()`) para la guardia del router.
3. **Edge Function `signup-company`**: crea la cuenta del titular en Auth
   (con confirmación de correo), llama `provision_organization` con
   `service_role`, devuelve el slug. Valida slug contra `reserved_slugs` y
   formato de §7.3 (el trigger ya lo impone; aquí solo para dar mensaje
   claro).
4. **Edge Function `manage-member`** (solo admin de la empresa, verificado
   con el JWT del que llama + `has_role`): crea la cuenta con
   `member_login_email(org, username)` y `email_confirm: true`, la membresía
   y, según el modo: (a) `must_change_password = true` con la contraseña
   dictada, o (b) fila en `member_invitations` con `sha256(token)` y devuelve
   el enlace `…/e/<slug>/bienvenida#<token>` (72 h, un solo uso). También:
   cambiar rol/estado, reenviar enlace, y `desbloquear_miembro`.
5. **Edge Function `set-password`**: dos entradas — (a) usuario con sesión y
   `must_change_password`: fija la nueva contraseña y baja la bandera;
   (b) `token` de bienvenida: verifica hash + vigencia + no usado, fija la
   contraseña, marca `used_at`, activa la membresía. Nunca revela si el
   token existía: mismo mensaje.
6. **Hook de intentos**: `[auth.hook.password_verification_attempt]` en
   `config.toml` apuntando a `auth_password_attempt` (ya existe desde Fase 1);
   `supabase config diff` → `supabase config push`. **§18 #9**: si el plan
   del proyecto no lo permite, se anota en `docs/DUDAS.md` y se sigue con el
   límite por IP de Supabase — no se finge.
7. **Desplegar**: `supabase functions deploy --use-api` + `supabase secrets
   set` de lo que haga falta (el `SUPABASE_SERVICE_ROLE_KEY` lo inyecta la
   plataforma; `PULZ_PUBLIC_URL` para armar enlaces).
8. **Pages Function del portal**: copiar `docs/referencia/pulz_portal_function.ts`
   a `apps/web/functions/e/[slug]/[[path]].ts` (las etiquetas genéricas de
   `index.html` ya están desde Fase 0), `wrangler.toml` mínimo en `apps/web`,
   y su prueba (Vitest + Miniflare): reescribe título y marca, redirige slug
   viejo con 301, 404 idéntico para inexistente y cancelada, manifiesto por
   empresa.

**Interfaz (después de la compuerta):**

9. **Ronda de `kiwi`** para las tres pantallas → aprobación del dueño.
10. `lima` → `coco` → `mora-docs` (ver compuerta). Cliente de acceso en
    `apps/web/src/modules/acceso/`: `portal_branding(slug)` al cargar; si el
    campo trae `@` es correo real, si no se arma el correo sintético y se
    llama **directo** `supabase.auth.signInWithPassword` (§7.5, sin función
    intermedia); **los cuatro rechazos** (empresa inexistente, usuario
    inexistente, contraseña mala, cuenta suspendida) muestran exactamente
    "Usuario o contraseña incorrectos".
11. **Guardias del router** (`apps/web/src/app/`): tras entrar, compara el
    slug de la URL con `mis_membresias`; si no pertenece, el mismo 404; si
    `must_change_password`, obliga a cambiarla; si `read_only`, la app
    entra en solo lectura (esconde acciones de escritura; la base ya las
    rechaza por `has_role`).
12. **Pantalla de Equipo (solo admin)**: alta con dictada o enlace, cambiar
    rol/estado, desbloquear. También pasa por `kiwi` (misma ronda o una
    segunda, según decida el dueño).

**Pruebas y cierre:**

13. **Vitest de integración** contra el proyecto alojado
    (`apps/web/src/modules/acceso/__tests__/`): login por usuario y por
    correo con los usuarios de la semilla; los cuatro rechazos dan el mismo
    mensaje; 5 fallos bloquean y `desbloquear_miembro` libera (si el hook
    está activo; si no, se marca `skip` con la razón); alta de miembro por
    `manage-member` en los dos modos; canje de enlace de bienvenida; empresa
    vencida entra en solo lectura; cancelada da 404.
14. **`supabase db reset --linked`** entre corridas (las pruebas de alta crean
    usuarios; el reset los borra).
15. Criterios de aceptación de §16 comprobados con comandos reales.

## Archivos que se tocan

- `supabase/seed.sql` (contraseñas), `supabase/config.toml` (hook),
  `supabase/migrations/…0022_acceso.sql`,
  `supabase/functions/{signup-company,manage-member,set-password}/index.ts`
  (+ `_shared/` para el cliente admin y errores).
- `apps/web/functions/e/[slug]/[[path]].ts`, `apps/web/wrangler.toml`,
  `apps/web/functions/__tests__/portal.test.ts`.
- `apps/web/src/modules/acceso/` (pages, components, api.ts, routes.ts,
  store.ts, `__tests__/`), `apps/web/src/app/router.ts` (guardias),
  `apps/web/src/shared/supabase/` (errores tipados, mapeo de rechazos).
- `design-hub/lab/acceso/rNN/` (kiwi), registry (lima), Hub (mora).
- `docs/DECISIONES.md`, `docs/DUDAS.md` (hook §18 #9, lo que §7 no cierre).

## Cómo se comprueban los criterios de aceptación de §16 (Fase 3)

| Criterio | Cómo |
|---|---|
| Login por usuario y por correo | Vitest de integración contra el proyecto alojado, usuarios de la semilla |
| Mensaje idéntico en los cuatro rechazos | Vitest: las cuatro llamadas devuelven la misma cadena |
| 5 fallos bloquean y el admin desbloquea | Vitest (si el hook está activo) + `supabase db query --linked` sobre `login_throttle` |
| Slug renombrado redirige 301 | prueba de la Pages Function (`mezcal-cuatro-vientos` → `cuatro-vientos`) |
| Vencida entra en solo lectura; cancelada da 404 idéntico | `portal_branding` en pgTAP + Vitest de la Pages Function con la suscripción cambiada por `db query` |
| La función del portal pasa sus pruebas | Vitest + Miniflare |
| Título servido en `/e/cuatro-vientos` = "Mezcal Cuatro Vientos · PULZ" | la misma prueba, sobre el HTML reescrito |
| Pantallas con ronda de kiwi aprobada, auditoría de coco, documentadas por mora | evidencia en `design-hub/` + aprobación del dueño en el chat |

## Riesgos y dudas que esta fase va a abrir

- **Hook de intentos en el plan del proyecto** (§18 #9): se sabrá al hacer
  `supabase config push`.
- **Correo del titular**: `signup-company` con confirmación de correo
  necesita SMTP; el de Supabase por defecto tiene límite bajo. Para
  desarrollo basta; se anota para producción.
- **Dominio** (§18 #8): los enlaces de bienvenida usan `PULZ_PUBLIC_URL`;
  en desarrollo será la URL de Cloudflare Pages o `localhost`.
- **Pruebas que crean usuarios en Auth**: un `db reset --linked` los borra
  (auth.users se reinicia). Hay que correr las pruebas de alta en orden y
  resetear después.

## Resultados reales (2026-09-27) — servidor, tareas 1–8

| Criterio (§16) | Comando real | Resultado |
|---|---|---|
| Login por usuario y por correo | `curl …/auth/v1/token?grant_type=password` con los usuarios de la semilla | **OK**: Benito (correo real) y Tomás (`tomas.h@<org_id>.usuarios.pulz.mx`) reciben token |
| Mensaje idéntico en los rechazos | mismo `curl` con contraseña mala y con usuario inexistente | GoTrue devuelve **el mismo** `invalid_credentials` (400) en ambos; empresa inexistente y cuenta suspendida se resuelven en el cliente con el mismo texto (pendiente de la pantalla) |
| 5 fallos bloquean y el admin desbloquea | `supabase config push` del hook | **NO COMPROBABLE en este plan**: 402 `HOOK_PASSWORD_VERIFICATION_ATTEMPT` no disponible para la organización (`docs/DUDAS.md` #9). Queda el límite por IP de Supabase |
| Slug renombrado redirige 301 | `test:portal` (wrangler pages dev + portal_branding real) | **OK**: `/e/mezcal-cuatro-vientos/fermentacion` → 301 a `/e/cuatro-vientos/fermentacion` |
| Vencida en solo lectura; cancelada 404 idéntico | pgTAP `supabase/tests/portal.test.sql` | **11/11**: vencida → `read_only = true` y `has_role` rechaza escrituras; cancelada e inexistente → ninguna fila (el mismo 404) |
| La función del portal pasa sus pruebas | `pnpm --filter @pulz/web test:portal` | **5/5** en Miniflare, sin Docker |
| Título en `/e/cuatro-vientos` = "Mezcal Cuatro Vientos · PULZ" | la misma prueba | **OK** |
| Alta de miembro (dictada y enlace), canje de bienvenida, cambio obligatorio | `curl` contra las Edge Functions desplegadas | **OK**: enlace de un solo uso (segundo canje → 400), `must_change_password` pasa de `true` a `false` por el servidor, duplicado → 409, operador → 403, sin sesión → 401 |
| `signup-company` | `curl` | **OK**: crea titular + empresa (`prueba-c`), `portal_branding` la ve al instante; slug reservado → "Ese nombre de portal está reservado" |
| Advisors de seguridad | `supabase db advisors --linked` | 0 errores; los avisos que quedan son las RPC de §12 por diseño (`docs/DECISIONES.md`) |
| Pantallas con ronda de kiwi aprobada | kiwi r01 aprobada por el dueño → lima (registry 14 drafts) → coco (R3) | **Construidas y verificadas**: `vue-tsc`/lint/build ✔, Vitest 33/33 (incluida integración real: 4 rechazos → mismo texto), Playwright 8/8 corridas en 1440/1024/768/390 × claro/oscuro con 104 capturas en `design-hub/qa/evidence/acceso-r01/`. Declaración: `design-hub/lab/acceso/r01/coco-declaracion.md`. **Falta**: compuerta Candidate de lima y documentación de mora |
