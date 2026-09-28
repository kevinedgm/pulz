# PULZ · Estado del proyecto

> Lo primero que se lee al retomar una sesión. Se mantiene vivo: fase actual,
> qué pasó, qué falta, qué se decidió y por qué.
>
> **Antes de leer el resto, lee `CLAUDE.md` en la raíz del repo.** Trae las
> reglas que se decidieron después de `PULZ_MAESTRO.md` y que valen para
> todas las fases: nunca Docker/Supabase local, migraciones "desde cero"
> mientras no haya lanzamiento, y que toda interfaz empieza por la skill
> `kiwi`.

## Fase actual

**Fase 3 · Portal, acceso y equipo — servidor e interfaz construidos y
verificados; falta cerrar el ciclo del squad (lima → mora).** Las tres Edge
Functions están desplegadas y probadas; la Pages Function pasa sus pruebas
reales; las cuatro pantallas (portal + inicio de sesión, cambio obligatorio,
bienvenida, equipo) y el sistema `shared/ui` están implementados con la
estructura aprobada de kiwi r01, con Vitest 33/33 (integración real contra
el proyecto alojado incluida) y evidencia Playwright en 4 anchos × 2 temas.
**Siguiente paso**: el dueño revisa la evidencia y las pantallas
(`preview` del dev server) y decide `docs/DUDAS.md` #11; luego `lima`
evalúa la compuerta Candidate con `design-hub/lab/acceso/r01/coco-declaracion.md`
y `mora-docs` documenta. Después, Fase 4.

## Qué pasó

- 2026-09-26: Fase 0 (monorepo, tooling, Fruti Squad, repo en GitHub) y
  reglas permanentes en `CLAUDE.md`.
- 2026-09-27: Fase 1 (esquema en 13 migraciones, aislamiento 18/18, saldos
  §15.1) y Fase 2 (17 RPC, semilla por RPC, pgTAP 26/26) contra el proyecto
  alojado, sin Docker.
- 2026-09-27: Fase 3, mitad de servidor:
  - `0022_acceso.sql`: vista `mis_membresias` para las guardias del router.
  - Contraseñas de desarrollo en la semilla (bcrypt vía `extensions.crypt`).
  - Edge Functions con `@supabase/server` (`withSupabase`), desplegadas con
    `--use-api`. Smoke real con `curl`: 13 casos, todos como se diseñaron
    (alta por enlace y dictada, canje de un solo uso, cambio obligatorio,
    duplicado 409, operador 403, sin sesión 401, alta de empresa, slug
    reservado).
  - Hook de intentos: **402, no está en el plan del proyecto** (§18 #9
    respondido). Queda apagado y documentado; el criterio "5 fallos
    bloquean" no es comprobable en este plan.
  - `config push` acotado: `config.toml` deja sin declarar todo lo que no
    queremos que mande (15 diferencias que el template habría empujado).
  - Pages Function copiada a `apps/web/functions/e/[slug]/[[path]].ts`,
    `wrangler.toml`, prueba e2e con `wrangler pages dev` (5/5) y pgTAP del
    portal (11/11).
  - Advisors: corregidos `search_path`, revokes a `anon`, `(select
    auth.uid())` en `profiles`. 0 errores.
  - Lint/format del repo en verde (se ignoran `.claude/`, `.agents/`,
    `design-hub/` — tooling de terceros).
- 2026-09-27: Fase 3, mitad de interfaz (squad):
  - `kiwi` r01 (`design-hub/lab/acceso/r01/`) **aprobada por el dueño**,
    junto con `equipo_miembros` (función security definer, `0023`, pgTAP
    12/12).
  - `lima`: 14 piezas `draft` en `design-hub/system/registry.json` con
    contrato; orden de construcción `orden-coco.md`.
  - `coco` (R3 + F3): `apps/web/src/shared/ui/` (10 piezas con tokens
    reales, demos en `design-hub/Components/demo` construidas desde el
    código), `modules/acceso/` (portal, cambio obligatorio, bienvenida,
    404, store y guardias), `modules/equipo/` (lista, menú por fila, alta
    por enlace o dictada). Verificado en navegador real, Vitest 33/33
    (integración real: 4 rechazos → mismo texto) y Playwright 8/8 corridas
    con 104 capturas. Siete defectos encontrados y corregidos en la
    verificación (ver `docs/DECISIONES.md`). Declaración:
    `design-hub/lab/acceso/r01/coco-declaracion.md`.

## Criterios de aceptación de la Fase 3 (§16) — estado

Ver tabla completa en `docs/plan/FASE-3.md` ("Resultados reales"). Resumen:
login por usuario y por correo **OK**; rechazos idénticos **OK** en GoTrue
(el texto único lo pone la pantalla); slug 301 **OK**; vencida/cancelada
**OK** (pgTAP); función del portal **5/5**; título "Mezcal Cuatro Vientos ·
PULZ" **OK**; altas/canje/cambio obligatorio **OK**; **5 fallos bloquean: no
comprobable en este plan**; **pantallas: construidas y verificadas** (texto
único en los cuatro rechazos probado contra el proyecto alojado; guardias y
adaptación probadas con Playwright); falta la compuerta de lima y mora.

## Qué falta

1. **Cerrar el ciclo del squad para acceso/r01.** `lima` ya evaluó la
   compuerta Candidate (2026-09-27, `design-hub/lab/acceso/r01/lima-compuerta.md`):
   **las 14 piezas están en `candidate` 0.2.0** en el registry, con QA por
   faceta (viewports, teclado, touch emulado, zoom 200 % aproximado,
   contraste medido) y hallazgos devueltos a coco ya corregidos.
   **`mora-docs` hecho (2026-09-27)**: Hub en Markdown —
   `design-hub/README.md` (inicio), `Foundations/{Tokens,Icons}.md`, 10
   fichas en `Components/` y `Patterns/`, 4 en `Screens/`, todo contrastado
   con el código y el registry; declaración en
   `design-hub/lab/acceso/r01/mora-declaracion.md`. El Hub **no tiene shell
   HTML**: mora dejó el encargo de estructura para kiwi en
   `design-hub/lab/hub/encargo-mora.md` (ronda `lab/hub/r01`, cuando el
   dueño la pida). Tres revisiones pequeñas para lima (texto del contrato de
   `row-menu`, `registry.documentation` → ficha, taxonomía `Screens/`). La
   compuerta Stable (harden + audit + zoom nativo a mano + aprobación
   explícita) queda para cuando el dueño pida estabilizar; no antes.
   **Con esto la Fase 3 queda cerrada salvo decisiones pendientes** (DUDAS
   #11, #12); sigue `docs/plan/FASE-4.md`, pendiente de aprobación.
2. Decidir `docs/DUDAS.md` #11 (que `set-password` devuelva el correo de
   acceso para que la bienvenida deje a la persona dentro). Es un cambio
   pequeño en la Edge Function + `BienvenidaPage.vue`.
3. Que el dueño decida sobre `docs/DUDAS.md` #9 (subir de plan para el hook)
   y #10 (protección de contraseñas filtradas). No bloquean.
4. Sigue abierto de fases anteriores: concurrencia a mano (#5), escala 1–6
   (#4), folios/entrada de tina/corregir_operacion (#6–#8). No bloquean.
5. Abrir un PR real y confirmar `ci.yml` (no bloquea).

## Entorno (actualizado 2026-09-27)

| Herramienta | Estado |
|---|---|
| Node / pnpm | 22.23.3 vía `nvm` · pnpm 9.15.9 vía Corepack |
| git | `github.com/kevinedgm/pulz`, rama `main` |
| Supabase CLI | 2.118.0, enlazado a `ypgeiyorgktshgbzhgfh`. Nunca `supabase start` ni `test db` (Docker); pgTAP por `db query --linked -f`; funciones con `deploy --use-api`; **`config diff` antes de cualquier `config push`** |
| Proyecto Supabase | 22 migraciones + semilla por RPC; 3 Edge Functions desplegadas; hook de intentos no disponible (plan); **cada `db reset --linked` lo reconstruye** |
| Cloudflare | `apps/web/wrangler.toml` (Pages, `dist/`); la Pages Function se prueba con `pnpm --filter @pulz/web test:portal` (requiere `pnpm build` antes) |
| Docker / Colima / Podman | desinstalados a propósito, regla permanente |
| Dev server / Hub | `.claude/launch.json`: `web` (Vite 5173) y `hub` (`python3 -m http.server 4321` → `/design-hub/Components/demo/`); el Hub se reconstruye con `pnpm --filter @pulz/web build:hub` |
| Playwright | `@playwright/test` 1.63 en la raíz, instalado **sin** descargar navegadores (usa el Chromium 1243 ya en `~/Library/Caches/ms-playwright`). Evidencia: `node design-hub/qa/evidencia-acceso.mjs` y zoom 200 % aprox. `node design-hub/qa/zoom-acceso.mjs`, con `web` y `hub` corriendo |
| Fruti Squad | `.claude/skills/{kiwi,lima,coco,mora-docs}`, perfil `.claude/skills/lima/profiles/pulz.md` |

## Regla de seguridad que hay que recordar

`supabase projects list` muestra también **TRAKER-PALENQUE**
(`thpoahtohyofjndauvix`): es el sistema heredado de Istmeño. **Nunca se
enlaza ni se toca** (`PULZ_MAESTRO.md` §0.3). Solo `ypgeiyorgktshgbzhgfh`.

## Decisiones y por qué

Ver `docs/DECISIONES.md` (historial completo) y `CLAUDE.md` (las que rigen
hacia adelante).

## Pendiente de decidir (ver `docs/DUDAS.md`)

- #11 bienvenida sin sesión automática · #9 hook de intentos (plan) · #10
  contraseñas filtradas · #5 concurrencia a mano · #4 escala 1–6 · #6–#8
  supuestos de negocio de la Fase 2.

## Próxima fase

**Fase 4 · Interfaz base y configuración — plan aprobado (2026-09-27);
servidor hecho y verificado.** `0024_marca.sql` (bucket `branding` +
políticas por empresa, por migración), pgTAP `configuracion.test.sql`
33/33, smoke real de Storage, DUDAS #11 resuelto (sesión automática tras la
bienvenida, probado contra las funciones desplegadas), PWA mínima (manifest,
service worker de precache, iconos desde la marca). **Shell hecho
(ronda `shell/r01`, ciclo completo kiwi → lima → coco → mora, decidido en
automático per `CLAUDE.md` §4):** navegación por proceso (barra 4+Más en
compact, lateral 200/240), cabecera con empresa → Cuenta (empresas, tema,
Equipo, salir), banners, hueco de FAB, Inicio con "¿Qué tienes hoy?",
destinos "próximamente", 4 símbolos nuevos; 20 piezas `candidate` en el
registry; Vitest 40/40; Playwright shell 8/8 (50 capturas) + acceso 8/8
(104) + zoom 10/10. **Configuración hecha (ronda `configuracion/r01`,
ciclo completo):** recursos, catálogos (14), ajustes, portal y marca con
logo real a Storage y cambio de enlace; `0025_recurso_en_uso.sql`; 6 piezas
nuevas del sistema (select, number-field, switch, color-field, file-picker,
brand-block); 27 piezas `candidate`; pgTAP 37/37; Vitest 47/47; Playwright
8/8 con escrituras reales deshechas (67 capturas). **Primer arranque hecho
(ronda `arranque/r01`, ciclo completo):** lista de recipientes con
vacío/tiene algo, carga inicial real por `registrar_entrada` idempotente,
`RecursoCapa` compartida con Recursos; 28 piezas `candidate`; Vitest 52/52;
Playwright 8/8 con escrituras reales en Prueba B (Tanque B1, 300 L @ 47).
**Siguiente:** prueba de punta a punta con empresa nueva (tarea 5) → ronda
del Hub HTML (`lab/hub/r01`) → cierre de la Fase 4 (`db reset --linked`).
