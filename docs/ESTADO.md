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

**Frente único vigente · 2026-09-28: Maguey/Horneado r05 corregida, aceptación parcial.**
R05 cierra el corte de navegación y corrige identidad concurrente, intención
corrupta, origen de cocido y timestamp offline.183/183 locales (34 módulo),
5/5 acceso alojado autorizado; tipos/build/demo/lint PASS. Siete anchos revisados.
No operaciones de negocio remotas: requieren fixtures aislados autorizados.
Accesibilidad física/nativa pendiente; draft0.2.1, sin Candidate/Stable/release.
[Resultado r05](../design-hub/lab/maguey-horneado/r05/result.md).

**Antecedente r04 (no aprobación vigente):**
[Checklist vivo](plan/CHECKLIST-MAGUEY-HORNEADO.md): F2 nueva aprobada sólo en
estructura; Coco implementó recepción/apertura/cierre/entrada y adaptador RPC.
28 pruebas del módulo y168 locales app PASS; build app/demo PASS. Dos revisores
independientes y confirmación runtime. Corregidos intención idempotente persistida,
reconexión, insets/rail, foco y contraste. Mora sólo documenta draft con límites.
Pendientes corte de etiqueta medium, E2E alojado y accesibilidad física/nativa.
No overall PASS, Candidate/Stable ni release. [Resultado r04](../design-hub/lab/maguey-horneado/r04/result.md).
Cinco tests alojados fallaron por RED; excluirlos del conjunto local no los aprueba.
No escrituras DB, cambios de Foundations ni FilaUso en esta continuación.

**Actualización 2026-09-28: Fase 5 abierta; aceptación global NO certificada.**
Ver [continuación y evidencia vigente](plan/CONTINUACION-2026-09-28.md) y
[primera verificación de todos los planes](plan/VERIFICACION-2026-09-28.md).
Corregidos capacidad flexible, instantáneas/errores offline, aislamiento de
fixtures y selección del grado declarado vigente. Aplicación **145/145**;
runner **10/10**; seis suites DB aisladas **163 aserciones hoja PASS**.
Concurrencia real **NO certificada**: tres intentos fallidos, limpieza de sus
fixtures confirmada. No se reseteó la base. Manrope, Instrument Serif y Lucide
se entregan localmente en app/demo. Maguey/Horneado **r02 rechazada** tras
revisión nueva: antecedente de r03, cuyo estado vigente se indica arriba. Siguen
Inicio/hoy real, E2E completo/offline y QA global. Evidencia histórica no
certifica las Foundations actuales.

### Antecedentes de implementación (2026-09-27, no resultados de hoy)

**Fase 5 · Captura por etapa y offline — plan escrito
(`docs/plan/FASE-5.md`, decidido en automático per `CLAUDE.md` §4); empieza
por el servidor (`0026_vistas_proceso.sql`, `0027_evidencias.sql`, pgTAP
`proceso.test.sql`) y la cola offline, luego cinco rondas de kiwi
(fermentación → destilación → granel → maguey-horneado → inicio-hoy).**
Servidor **hecho** (2026-09-27): `0026` (5 vistas) y `0027` (bucket
`evidencias` + insert de `attachments`), pgTAP `proceso.test.sql` 57/57,
configuración 37/37, advisors 0 errores. **Cola offline hecha**
(`shared/offline/`, Vitest). **Ronda fermentacion/r01 hecha** (ciclo
completo del squad): usos de tinas, detalle, medición por pasos en dos
modos con aviso de Brix, formulación, tina que ya fermentaba; 5 piezas
nuevas del sistema + 3 extensiones; 35 piezas `candidate`; Vitest 90/90;
Playwright 8/8 (61 capturas) y **e2e offline de aceptación en verde**
(3 mediciones en modo avión llegan una sola vez y en orden). **Ronda
destilacion/r01 hecha** (corridas, cortes por la cola, `origin-allocation`
extraído) y **e2e offline completo de §16 en verde** (3 mediciones y 2
cortes en modo avión: una sola vez y en orden). **Ronda granel/r01 hecha**
(tanques con grado declarado vigente, movimiento armado por concepto con la
diferencia conocida antes, transferir). 38 piezas `candidate`; Vitest
107/107. **Sigue:** ronda maguey-horneado/r01 (kiwi y orden de lima
escritos; falta coco) → inicio-hoy/r01 → e2e del proceso completo.

**Fase 4 cerrada el 2026-09-27**: servidor, shell, configuración, primer
arranque, prueba e2e con empresa nueva y Design Hub con sitio HTML propio,
todo con ciclo completo del squad; 29 piezas `candidate` 0.2.0; Vitest 52/52;
Playwright 8/8 en cinco superficies (acceso 104 · shell 50 · configuración
67 · arranque 13 · hub 36 capturas) más e2e (9). `supabase db reset --linked
--yes` de cierre ejecutado: el proyecto de desarrollo vuelve a la semilla
(solo `cuatro-vientos` y `prueba-b`); pgTAP de configuración en verde después.

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
- 2026-09-27: Fase 3 cerrada por lima (14 candidate) y mora (Hub en
  Markdown). Fase 4 completa: ver «Próxima fase» abajo (servidor, shell,
  configuración, arranque, e2e y sitio del Hub) y `docs/plan/FASE-4.md`
  («Resultados reales»). Cerrada con `db reset --linked` el mismo día.

## Criterios de aceptación de la Fase 3 (§16) — estado

Ver tabla completa en `docs/plan/FASE-3.md` ("Resultados reales"). Resumen:
login por usuario y por correo **OK**; rechazos idénticos **OK** en GoTrue
(el texto único lo pone la pantalla); slug 301 **OK**; vencida/cancelada
**OK** (pgTAP); función del portal **5/5**; título "Mezcal Cuatro Vientos ·
PULZ" **OK**; altas/canje/cambio obligatorio **OK**; **5 fallos bloquean: no
comprobable en este plan**; **pantallas: construidas y verificadas** (texto
único en los cuatro rechazos probado contra el proyecto alojado; guardias y
adaptación probadas con Playwright). Lima y Mora se completaron después
(ver historial); esa compuerta ya no está pendiente. Los resultados nuevos
y sus limitaciones están en la verificación del 2026-09-28.

## Qué falta

1. Resolver y verificar concurrencia real con dos sesiones; suites normales
   ya aisladas y en verde. No reejecutar SQL histórico sobre datos de demo.
2. Cerrar aceptación de Maguey/Horneado r05: fixtures persistentes aislados
   autorizados para E2E de negocio y accesibilidad física/nativa. Implementación
   y correcciones locales terminadas; no reutilizar gates de rondas anteriores.
3. Implementar Inicio/hoy real y E2E completo; repetir aceptación offline.
4. Revalidar composición, accesibilidad y consumo real de Foundations.
5. Comprobar CI en PR real; siguen las limitaciones del hook de intentos y
   demás decisiones abiertas en `DUDAS.md`.

### Lista histórica al cerrar Fase 3 (no pendientes actuales)

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
| Proyecto Supabase | 27 migraciones + semilla por RPC; 3 Edge Functions desplegadas; hook de intentos no disponible (plan); **cada `db reset --linked` lo reconstruye** |
| Cloudflare | `apps/web/wrangler.toml` (Pages, `dist/`); la Pages Function se prueba con `pnpm --filter @pulz/web test:portal` (requiere `pnpm build` antes) |
| Docker / Colima / Podman | desinstalados a propósito, regla permanente |
| Dev server / Hub | `.claude/launch.json`: `web` (Vite 5173) y `hub` (`python3 -m http.server 4321` → `http://localhost:4321/design-hub/site/`); demos con `pnpm --filter @pulz/web build:hub`, sitio con `pnpm build:hub-site` (versionado; regenerar con cada cambio de ficha o registry) |
| Playwright | `@playwright/test` 1.63 en la raíz, instalado **sin** descargar navegadores (usa el Chromium 1243 ya en `~/Library/Caches/ms-playwright`). Evidencia: `node design-hub/qa/evidencia-{acceso,shell,configuracion,arranque,hub}.mjs`, e2e `e2e-fase4.mjs`, zoom 200 % aprox. `zoom-acceso.mjs`, enlaces del sitio `enlaces-hub.mjs`, con `web` y `hub` corriendo |
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

## Historial de transición a Fase 4 (2026-09-27)

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
**Prueba de punta a punta hecha** (`qa/e2e-fase4.mjs`: empresa nueva real →
arranque → logo → portal, OK a la primera). **Hub HTML hecho (ronda
`hub/r01`)**: sitio generado en `design-hub/site/` con `pnpm build:hub-site`,
`hub-shell` candidate 0.2.0, 33 páginas / 0 enlaces rotos, evidencia 8/8.
**Cerrada** con `db reset --linked` (2026-09-27). Sigue `docs/plan/FASE-5.md`.
