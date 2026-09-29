# Verificación del maestro y planes · 2026-09-28

> Primera evaluación conservada como historial. Los nuevos resultados y
> correcciones están en [CONTINUACION-2026-09-28.md](CONTINUACION-2026-09-28.md).
> Sus fallos no se borran ni se reutilizan como aprobación de otra ronda.

## Resultado

**Fase 5 sigue incompleta. No se certifica el cierre correcto de todas las fases.**
Se contrastaron `PULZ_MAESTRO.md`, `CLAUDE.md`, los seis planes existentes
(`FASE-0`–`FASE-5`), código, migraciones, pruebas y documentación del Hub.
Se encontraron un bloqueo incorrecto de formulación, problemas de recuperación
de instantáneas y pruebas de DB acopladas a la semilla después de usar la demo.

No se reseteó Supabase, ni se cambiaron migraciones, reglas de negocio,
precios, roles o Foundations. No se modificaron rondas Fruti evaluadas ni se
tomaron sus resultados históricos como aprobación actual. Los cambios de
`FilaUso.vue` ya estaban en el árbol al empezar y se preservaron sin editarlo.

## Plan por plan

| Plan | Implementación encontrada | Verificación nueva y pendiente de aceptación |
| --- | --- | --- |
| Fase 0 · Arranque | Monorepo, Vue/TS/PWA, tooling, CI, perfiles Fruti, Hub y documentos existen. | Build, lint, format y pruebas pasan. Node del shell es 20 y no satisface `engines`; se usó Node 24.19. No se comprobó un run real de GitHub Actions en PR ni instalación limpia. Supabase local está descartado por `CLAUDE.md`. |
| Fase 1 · Base de datos | Migraciones, catálogos por empresa, RLS, FK y semilla existen. | Aislamiento **17/18** después del ajuste de JSON. RLS activa, sin políticas `ALL`, sin JSON en tablas. Saldos de §15.1 no coinciden con la empresa actualmente utilizada. Reconstrucción desde cero no reejecutada. |
| Fase 2 · Comandos | 17 RPC de negocio, helpers, provisión y semilla por RPC en `0014`–`0021`. | La suite RPC **aborta** por `DES-004` ya cerrada: no hay resultado actual válido por RPC. Concurrencia con dos sesiones sin verificar. Existencia del SQL no equivale a aceptación. |
| Fase 3 · Acceso/equipo | Portal, acceso, guardias, equipo, Edge Functions y páginas del Hub existen. La espera de Kiwi en el encabezado era obsoleta. | Aplicación 128/128 (incluye integración de rechazos), pgTAP portal 11/11, equipo 12/12, Pages Function 5/5 tras repetir un arranque fallido. Altas/canjes reales no repetidos. Hook de cinco intentos conserva la limitación documentada del plan contratado: no se certifica ni se contrata un plan nuevo. |
| Fase 4 · Base/configuración | Shell, configuración, marca/logo, arranque, Hub y rondas documentadas existen. | pgTAP configuración 37/37; Hub compila y enlaza. No se repitieron E2E de empresa nueva, Storage ni QA visual completa. Capturas anteriores a las Foundations actuales no prueban conformidad visual actual. |
| Fase 5 · Proceso/offline | Vistas `0026`, evidencias `0027`, cola/fotos/instantáneas, Fermentación, Destilación y Granel existen. | Correcciones y extracción compartida implementadas aquí, con 15 pruebas nuevas. Proceso pgTAP 46/57 sobre datos mutables. **Faltan Maguey/Horneado, Inicio/hoy real y E2E completo**. E2E offline contra servidor y uso físico sin señal no reejecutados. |

Fases 6–8 del maestro (trazabilidad, cobro y lanzamiento) aún no tienen planes
detallados en `docs/plan`. La infraestructura/RPC anticipada no equivale a sus
pantallas o aceptación. No se abrieron Stripe, staging ni producción.

## Correcciones y pendiente implementado

1. **Formulación, §2.1:** se leía `capacity` sin `capacity_policy` y se
   bloqueaba cualquier exceso, incluso flexible. Ahora `limiteDeTina` solo
   aplica límite duro a `estricta`. Flexible permite llegar a la RPC, que
   exige nota mediante `REQUIERE_NOTA`; los datos se conservan al reintentar.
   El saldo de cocido sigue siendo duro. Submit comprueba rol y conexión.
   Sin cambios de geometría ni estilo.
2. **Orden de Lima de Maguey/Horneado, paso 1:** `conInstantanea` pasó de tres
   copias en APIs a `shared/offline/instantanea.ts`, conservando el contrato
   de los consumidores. Se espera guardar la copia antes de resolver; un
   fallo de IndexedDB no impide devolver datos frescos.
3. **Errores offline:** se reconocen `ErrorAcceso("RED")` y objetos planos
   de PostgREST. Los errores tipados de permisos/dominio no se sustituyen
   por datos antiguos aunque el teléfono pierda señal. Las pruebas verifican
   separación por empresa y clave.
4. **Runner pgTAP:** `pnpm test:db` comprueba el proyecto enlazado, ejecuta
   seis suites transaccionales conocidas e interpreta TAP, no el código 0
   del CLI. Rechaza planes incompletos/numeración inválida y distingue
   `FAIL`, `ERROR`, `PARTIAL`, `PASS`; `SKIP`/`TODO` no certifican. Guarda
   evidencia nueva por fecha. Sus seis pruebas entran en CI, pero el job
   aún no ejecuta la DB remota.
5. **JSON en tablas:** la prueba contaba también vistas. El maestro §16
   dice **tablas** y la decisión del 2026-09-27 permite agregaciones JSONB
   en `corridas`/`tanques`. Se añadió `BASE TABLE`; no se cambió el esquema
   ni el criterio de saldos.

## Evidencia ejecutada

Node 24.19, pnpm 9.15.9, proyecto alojado `ypgeiyorgktshgbzhgfh`.
No se tocó el proyecto heredado.

| Comando | Resultado |
| --- | --- |
| `pnpm test` | **128/128**, 18 archivos; incluye 15 casos nuevos de instantáneas/Formulación. |
| `pnpm test:db:runner` | **6/6**; los TAP reales guardados también se reinterpretaron con el parser final. |
| `pnpm build` | **PASS**, vue-tsc + Vite + service worker. |
| `pnpm lint` / `pnpm format` | **PASS**. |
| `pnpm --filter @pulz/web test:portal` | Primero: timeout de arranque y 5 casos sin ejecutar. Repetición: **5/5** sin cambiar código/configuración. Causa exacta del primer timeout sin resolver. |
| `pnpm build:hub-site` | **PASS**, 47 fichas + inicio + QA + 404. |
| `node design-hub/qa/enlaces-hub.mjs` | **50 páginas, 0 enlaces/recursos internos rotos**; no equivale a QA visual. |
| `pnpm test:db` | **FAIL**, salida 1; [TAP antes del ajuste de JSON](evidence/2026-09-28T07-04-57.831Z/database.json). |
| `pnpm test:db aislamiento` | **FAIL**, salida 1; [TAP después del ajuste](evidence/2026-09-28T07-22-06.197Z/database.json): 17 pasan, 1 falla. |

### Fallos de DB no ocultados

- **Aislamiento:** queda la comparación de saldos con §15.1. Ejemplo:
  Colector colas tiene 28 L y la semilla espera 16 L. Las aserciones de
  separación entre empresas sí pasan.
- **RPC:** `NO_PERMITIDO: la corrida DES-004 ya está cerrada`. Usa un folio
  fijo que ya existe. No acredita un fallo de la lógica de cierre, ni
  permite afirmar que todas las RPC pasan.
- **Proceso:** 11 diferencias: Tina 1; número de corridas; colectores con
  saldo; litros/grado de colas; volumen/grado/historia de Tanque 1;
  volumen/grado/autor de Tanque 2. Los fixtures dependen de la semilla:
  **deben aislarse y repetirse para descartar regresiones de negocio**.
- **Concurrencia:** no ejecutada. `rpc_concurrencia.test.sql` usa sesiones
  `dblink` cuyos commits no se deshacen con el rollback exterior. Excluida
  del runner normal hasta tener fixture propio y dos sesiones reales.
  No se reemplazó por una prueba secuencial ni por un PASS.

## Fase 5: trabajo vigente

- [x] Reejecutar pruebas locales de infraestructura existente.
- [x] Extraer instantánea compartida (paso 1 de la orden de Lima).
- [x] Corregir capacidades flexibles y probar el flujo con nota.
- [x] Runner que falle ante TAP fallido/incompleto.
- [ ] Aislar fixtures de aislamiento/RPC/proceso de la empresa usada por demos.
- [x] Ejecutar concurrencia con dos sesiones y limpieza segura (2026-09-28, `pnpm test:rpc:concurrency` PASS 15/15 por PostgREST; residuos 0).
- [ ] Reevaluar contrato Maguey/Horneado contra Foundations vigentes;
      conservar decisiones válidas de Kiwi y abrir ronda nueva si cambia
      estructura. No reutilizar aprobación histórica como nueva.
- [ ] Construir `modules/maguey` y `modules/horneado`, pruebas y QA. Siguen
      «próximamente» en `app/destinos.ts`; el registro `draft` no significa
      que sus rutas fuente existan.
- [ ] Kiwi → Lima → Coco → Lima → Mora para Inicio/hoy real.
      `InicioEmpresaPage.vue` aún ofrece arranque y placeholders.
- [ ] E2E completo de §15.1 desde la interfaz con fixture propio.
- [ ] Repetir E2E offline (3 mediciones, 2 cortes, fotos), notas persistidas,
      idempotencia, reintentos y orden.
- [ ] QA visual, accesibilidad, Foundations y documentación por nueva ronda;
      solo después actualizar madurez/publicación de piezas afectadas.

## Límites de QA

| Dimensión | Estado de esta revisión |
| --- | --- |
| technical | Aplicación/build/lint/format PASS; aceptación DB **FAIL**. |
| structural | Inventario contrastado; Maguey/Horneado e Inicio/hoy pendientes. Sin aprobación estructural nueva. |
| visual | **No reevaluada**: sin capturas actuales completas ni revisión de composición. No-overflow no probaría jerarquía, agrupación o densidad. |
| accessibility | Sin certificación WCAG completa: faltan teclado/lector, zoom nativo y dispositivos físicos de pantallas actuales. |
| design_system | Foundations existen; migración global no certificada. Perfil declara Lucide/Manrope/Instrument Serif; sigue el sprite anterior y no se localizaron archivos de fuentes en `apps/web`. Declararlas en CSS no prueba la fuente renderizada. |
| documentation | Estado/planes reconciliados; Hub compila y enlaza. Sin promoción de piezas ni aprobación visual implícita. |

Se contrastó el arranque del portal con
[Pages Functions: desarrollo local](https://developers.cloudflare.com/pages/functions/local-development/).
No se cambió configuración de despliegue para resolver el timeout.

Se preservaron los cambios previos de Foundations, FilaUso y rondas. No se
creó un commit que mezclara esos cambios con esta revisión.
