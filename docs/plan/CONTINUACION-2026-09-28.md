# Continuación y correcciones · 2026-09-28

**Fase 5 sigue abierta. No está todo corregido ni se certifica la aceptación
global de los planes.** Este informe continúa la primera
[verificación](VERIFICACION-2026-09-28.md), sin borrar sus resultados.

## Corregido y verificado

1. **Fixtures DB aislados.** Cada suite recibe dos empresas y sus identidades
   nuevas; clona la semilla por RPC dentro de la misma transacción, conserva
   catálogos globales y termina en rollback. Se validan forma transaccional,
   unicidad, slugs ≤40 caracteres y caso de mayúsculas. Ya no depende de los
   saldos de la empresa usada en demos. No hubo reset ni Docker.
2. **Defecto real del grado vigente.** Una unión declaraba 44.9, pero el aporte
   de la misma operación podía ganar con 47 en `lot_declared_abv`. La vista
   prioriza el resultado declarado de esa operación y desempata de forma
   determinista. No calcula grados ni cambia roles/reglas comerciales.
   Primero se verificó el candidato en rollback, después se aplicó solo
   `CREATE OR REPLACE VIEW` al proyecto `ypgeiyorgktshgbzhgfh` y se repitieron
   las seis suites. `security_invoker` preservado. Migración fuente alineada
   con la regla del repositorio de mantener la definición desde cero.
3. **Concurrencia histórica insegura desactivada.** El archivo dblink ahora
   aborta con `PRUEBA_REEMPLAZADA` antes de su cuerpo histórico. Se retiró de
   DUDAS el procedimiento de transferir 250 L de la demo y resetear después.
4. **Foundations entregadas realmente.** Lucide reemplaza el sprite de UI;
   la marca conserva su geometría. Manrope e Instrument Serif se empaquetan
   localmente en app y demo, verificadas en navegador. No se cambiaron bases
   aprobadas. [Contrato, implementación y alcance](../../design-hub/lab/foundations-binding/r01/result.md).
5. **Nueva evaluación Maguey/Horneado.** Dos revisores autorizados, sin tomar
   r01 como aprobación. Kiwi generó r02 con CTA compact recuperada, revisión
   antes del consumo, cantidades vacías y jerarquía revisada. **Lima rechaza
   r02**, no autoriza Coco ni Mora: [resultado de seis dimensiones y devolución](../../design-hub/lab/maguey-horneado/r02/result.md).

Se conservan las correcciones de la primera revisión: capacidad flexible de
Formulación, recuperación offline sin ocultar errores de permisos y extracción
compartida de `conInstantanea`. No se editó `FilaUso.vue` ni se alteraron
`.fruti/tests/current`, `.fruti/tests/r01` o aprobaciones históricas en esta
continuación. El árbol ya tenía cambios ajenos; no se resetearon ni se mezcló
todo en un commit.

## Evidencia nueva

| Verificación | Resultado |
| --- | --- |
| `pnpm test` | **145/145**, 19 archivos; incluye 17 casos nuevos del helper Icono. La primera ejecución sin red no acredita integración; la repetición con acceso pasó. |
| `pnpm test:db:runner` | **10/10**, parser TAP y fixture transaccional. |
| `pnpm build` | **PASS**, vue-tsc, Vite, PWA: 92 entradas de precache. |
| `pnpm --filter @pulz/web build:hub` | **PASS**, fuentes locales y Lucide en la demo. |
| Suites DB candidato en rollback | **6 PASS**, [evidencia](evidence/2026-09-28T20-03-23.150Z/database.json). |
| Suites DB después de aplicar vista | **163 aserciones hoja PASS**: aislamiento 18, RPC 26, portal 11, equipo 12, configuración 37, proceso 59. [Evidencia](evidence/2026-09-28T20-04-14.388Z/database.json). El parser cuenta además seis resúmenes de subtest; no se suman como casos de negocio. |
| Advisors security (`warn`, fail-on error) | Salida 0, sin ERROR. WARN por funciones SECURITY DEFINER y protección de contraseñas filtradas desactivada; no se eliminan permisos ni se cambia plan contratado. |
| Recursos de fuentes en navegador | Los cinco WOFF2 observados: Manrope 400/500/600/700, Instrument Serif 400; estilos computados correctos. [Evidencia](../../design-hub/lab/foundations-binding/r01/runtime-evidence.json). |
| Iconos en navegador | Cinco SVG de navegación Lucide, viewBox 24 y stroke 2, decorativos ocultos. La prueba no certifica WCAG global. |
| F2 Maguey/Horneado r02 | `check_artifact.py`: 0 errores/0 warnings; composición y accesibilidad **FAIL**, no convertir el check mecánico en aprobación visual. |

Build del sitio, lint, formato y enlaces se registran al terminar en la sección
«Cierre mecánico» de este mismo informe. Portal E2E 5/5 pertenece a la primera
verificación; no se presenta como una nueva ejecución aquí.

### Concurrencia: no certificada

Nuevo `pnpm test:db:concurrency` prepara empresa/usuario/recursos desechables
con UUID propios y limpieza exacta. Tres intentos quedaron **FAIL** porque no
se observó a la primera sesión reteniendo locks; CLI quedó en inicialización
de login hasta finalizar/timeout. Diagnósticos de solo lectura sí mostraron
sesiones distintas, pero no acreditan exclusión mutua de la RPC.

- [Intento 1](evidence/2026-09-28T20-05-21.987Z-concurrency/concurrency.json).
- [Intento 2](evidence/2026-09-28T20-08-59.121Z-concurrency/concurrency.json).
- [Intento 3](evidence/2026-09-28T20-11-26.810Z-concurrency/concurrency.json).

En los tres se eliminaron exclusivamente los fixtures creados por esos
intentos y la comprobación final devolvió cero residuos (`limpieza: true`).
Esos datos de prueba eran desechables; no se modificó ni borró la demo.
La semilla/suite SQL de cada intento se conserva en evidencia para análisis.
El runner normal usa rollback; no se hizo una consulta adicional de residuos
para sus doce IDs de empresas.

El control de seguridad rechazó una repetición directa del SQL remoto de
escritura durante el diagnóstico. No se ejecutó por otra vía. Para continuar
esa prueba se requiere aprobar el alcance concreto: crear un tenant de prueba,
registrar/transferir su litro de prueba y eliminar exclusivamente esos UUID al
terminar; no reset, no demo, no proyecto heredado. Antes de ejecutarla hay que
resolver por qué no se observa la primera sesión. El nuevo runner no debe
tratarse como un gate ya validado.

## Plan por plan después de las correcciones

| Plan | Estado actual y pendiente |
| --- | --- |
| Fase 0 | Tooling/build/tests verificados; CI en PR real **hecho** (kevinedgm/pulz#1 verde); instalación limpia pendiente. |
| Fase 1 | Aislamiento y saldos 18/18 con fixture propio; reconstrucción desde cero no repetida. |
| Fase 2 | RPC 26/26; **concurrencia real pendiente**, no aceptación completa. |
| Fase 3 | Portal 11/11, equipo 12/12; altas/canjes reales no repetidos. Hook de cinco intentos sigue limitado por plan. |
| Fase 4 | Configuración 37/37, assets canónicos entregados; E2E nueva empresa/Storage y QA global pendientes. |
| Fase 5 | Proceso 59/59, instantáneas y correcciones hechas; **Maguey/Horneado r02 bloqueada**, Inicio/hoy y E2E completo/offline pendientes. |
| Fases 6–8 | Maestro las prevé, todavía no hay planes detallados ni aceptación. No se iniciaron cobros, staging o despliegue. |

## Archivos de esta continuación

- DB: `scripts/db-fixture.mjs`, `db-fixture.test.mjs`, `test-db.mjs`,
  `test-db-concurrency.mjs`; `package.json`; `supabase/tests/proceso.test.sql`,
  `rpc_concurrencia.test.sql`; `supabase/migrations/20260927000011_vistas.sql`.
  El parser TAP y sus pruebas proceden de la primera revisión.
- Entrega de UI: `apps/web/package.json`, `pnpm-lock.yaml`, `src/main.ts`,
  `hub/main.ts`, `src/App.vue`, `hub/DemoHub.vue`; `shared/ui/fonts.css`,
  `Icono.vue`, `__tests__/Icono.test.ts`, `tipos.ts`, `index.ts`,
  `NavInferior.vue`, `NavLateral.vue`, `BotonFlotante.vue`, `app/CapaMas.vue`.
- Rondas/evidencia: `design-hub/lab/maguey-horneado/r02/`,
  `design-hub/lab/foundations-binding/r01/`, `docs/plan/evidence/` (fechas de
  esta ejecución y capturas de revisores).
- Documentación: `Foundations/Typography.md`, `Foundations/Icons.md`, demo y
  sitio generados; `docs/ESTADO.md`, `DECISIONES.md`, `DUDAS.md`, encabezados
  de `plan/FASE-0`–`FASE-5` y los dos informes de verificación/continuación.

## Siguiente paso y límites

Kiwi abre **r03** conservando decisiones válidas y resolviendo los siete
rule_ids de la devolución. Lima no rediseña el F2. Impeccable alcanzó el límite
de dos pasadas del ciclo; no se continúa puliendo r02 ni se disfraza el rechazo
como éxito. Después: Lima → Coco si contrato aprobado → Lima QA por seis
dimensiones → Mora si elegible. Inicio/hoy y E2E no se declaran terminados.

Gap adicional de configuración detectado: `production.known_stack` del perfil
incluye Tailwind, pero esta app utiliza CSS; no se modificó el perfil protegido
ni las leyes visuales. Requiere sincronización acotada posterior. Otros gaps
de negocio/plan contratado siguen en `DUDAS.md`.

## Cierre mecánico

Ejecutados al final: `pnpm test:db:runner` **10/10**, `pnpm lint` **PASS**,
`pnpm format` **PASS**, `pnpm build:hub-site` **PASS** (47 fichas + inicio +
QA + 404), `node design-hub/qa/enlaces-hub.mjs` **50 páginas / 0 enlaces o
recursos internos rotos**, `git diff --check` sin errores. No equivalen a
aprobación visual ni aceptación E2E. Las dos fichas actualizadas conservan
shell, rutas y lifecycle; Mora no publica Maguey/Horneado como implementado.

Comprobación adicional: tokens JSON parseables, siete colores base y dos
familias iguales a los aprobados; ambos `truth_sources` del perfil existen;
los dos `compliance-current.json` nuevos son parseables. Repetición del check
de Kiwi sobre `r02/index.html`: **0 errores / 0 avisos**. Una invocación previa
apuntó por error al directorio y no evaluó el HTML; no se contó como resultado.
