# Frente único · Maguey/Horneado

Actualizado: 2026-09-28. Petición: continuar un solo frente y marcar cada
pendiente conforme se resuelva. No iniciar Inicio/hoy, concurrencia ni otras
fases. R05: autorización explícita sólo para cinco tests de acceso alojado;
sin operaciones de negocio remotas. No modificar FilaUso ni rondas evaluadas.

## Hito actual: F3 implementada localmente → aceptación parcial

Estado vigente: **r05 draft0.2.1 corregida; aceptación PARTIAL.** r06 (2026-09-28): pruebas alojadas de negocio 37/37 PASS con tenants desechables y limpieza verificada (`r06/evidence/`); bloque 15 cerrado: API (15.05–15.11, 15.14) y UI con Playwright (15.12, 15.13).
183/183 locales,34 módulo incluidos,5/5 acceso alojado; builds/lint PASS.
Matriz y límites: `design-hub/lab/maguey-horneado/r05/acceptance-matrix.md`.

Antecedente: **r04 draft implementada y evaluada; no overall PASS ni Stable.**
12/12 regresiones F2;28/28 módulo Vue;168/168 locales app. Build app/demo PASS.
Mora autorizada sólo a documentar el draft, no a promover una página como aceptada.
R03 se conserva como evidencia rechazada. Resultado: `design-hub/lab/maguey-horneado/r04/result.md`.

Objetivo vigente: cerrar los pendientes de aceptación de Maguey/Horneado sin
abrir otro frente. Los puntos 00–13 conservan el trabajo ya verificado; el
plan granular 14–17 desglosa lo que falta. `[x]` significa resuelto con
evidencia; un cambio escrito pero sin verificar permanece `[ ]`.
La aceptación F2 no certifica implementación F3 ni una publicación draft
equivale a aceptación de producto.

- [x] **00 · Delimitar el frente y criterios.** Revisados maestro, estado,
  perfil actual y devolución r02; preservar dos destinos, grupos, saldo,
  cantidades vacías, revisión del consumo y continuidad a Formulación.
- [x] **01 · Abrir r03 inmutable respecto a r02.** Brief, flujo, geometría y
  decisiones propias; aprobación histórica no reutilizada.
- [x] **02 · MH-MINIMAL-02.** Recepción sin piñas/especie/predio/proveedor
  elegidos silenciosamente; kilos y acción coherentes con lo capturado.
- [x] **03 · MH-STATE-02.** Ida a revisión y vuelta conservan cantidades,
  horno, fecha y folio; cambiar de tamaño no borra el formulario.
- [x] **04 · MH-DATA-02.** Ejemplo de cierre temporalmente coherente;
  la interfaz identifica la incoherencia sin inventar reglas de negocio.
- [x] **05 · MH-ADAPT-02.** Acciones completas y legibles en expanded;
  etiquetas completas del rail medium; tarea usable en compact.
  r04: separación de 8px, cinco targets de 54.4 × 48px a 320px;
  etiquetas completas sin crowding. MH-NAV-03 resuelto.
- [x] **06 · MH-ERROR-02.** Exceso de saldo muestra error asociado; corregir
  saldo elimina error y actualiza `aria-invalid`/`aria-describedby`.
- [x] **07 · MH-A11Y-02.** Capas con foco inicial, contención, Escape y
  devolución al disparador; el teclado completa la tarea.
  Comprobado en cierre: foco en `kc`, ciclo bidireccional y resultado 4,321 kg.
  Esto no certifica WCAG global ni todos los recorridos de producción.
- [x] **08 · MH-UNIT-02.** Total y revisión mantienen kg con cantidades
  enteras, decimales y al corregir el formulario.
- [x] **09 · Ejecutar verificación F2.** Check mecánico, recorrido real y composición
  a 1440/1024/768/390 y borde 320; estados y limitaciones registrados.
- [x] **10 · Emitir gate de Lima.** Seis dimensiones separadas, geometría congelada
  solo si procede; devolución con rule_ids si se rechaza.
  r03 REJECTED preservada; r04 **APPROVED_STRUCTURE_ONLY** para construir.

## Construcción y verificación local

- [x] **11 · Coco.** Construir únicamente lo autorizado con Foundations
  canónicas y componentes existentes; pruebas de implementación.
- [x] **12 · Lima QA.** Evaluadas las seis dimensiones de F3; PARTIAL no significa aprobado.
- [x] **13 · Mora.** Referencia draft nueva y preview Vue según alcance permitido
  por Lima; no página aceptada/Stable. Hub48 fichas,120 enlaces/recursos sin
  rotos ni IDs duplicados; vista HTTP comprobada.

## Aceptación pendiente (no confundir con código terminado)

Plan preparado y ejecutado parcialmente el2026-09-28 en r05. Marcas nuevas
respaldadas por el registro al final; lo bloqueado sigue abierto.

### Cómo ejecutar y marcar

Una sola tarea activa. Orden recomendado: **14 → 15 → 16 → 17**. Si un paso
requiere un recurso externo no disponible, registrar el bloqueo y continuar
con el siguiente paso local del mismo frente; no abrir Inicio/hoy ni concurrencia.

Cada marca debe registrar fecha, evidencia y resultado. Un intento fallido,
una prueba omitida o un bloqueo siguen como `[ ]`. Los resultados de r04 son
antecedentes: las verificaciones afectadas por nuevos cambios se repiten.
La ronda siguiente propuesta es **r05**, previa comprobación de que esté libre;
no sobrescribir rondas evaluadas. Las correcciones geométricas siguen siendo
propiedad de Kiwi; Lima no las rediseña.

### 14 · Cerrar el pulido visual local

Responsables: Coco implementa; Lima evalúa; Kiwi interviene si cambia geometría.
Dependencia: ninguna escritura remota. Prioridad inmediata.

- [x] **14.01 · Abrir la siguiente ronda disponible.** Crear brief y registro de
  evidencia nueva; enlazar r04 como antecedente, no como aprobación.
- [x] **14.02 · Congelar lo que debe conservarse.** Registrar rail 160/240 px,
  insets 16/24 px, cinco destinos compactos, etiquetas completas, targets y
  Foundations vigentes; conservar hashes de r04.
- [ ] **14.03 · Reproducir MH-F3-VIS-01.** Capturar «Fermentación» a 768 px y
  comprobar los bordes de medium (600 y 1023 px) tanto en demo como en el
  componente de navegación usado por la app.
- [x] **14.04 · Resolver el corte de palabra.** Mantener nombre completo y tamaño
  legible, sin clipping, abreviación silenciosa ni ensanchar el rail por cuenta
  de Coco. Si hace falta cambiar geometría, devolver a Kiwi y obtener contrato
  nuevo de Lima antes de implementar.
- [x] **14.05 · Comprobar regresión adaptativa.** Revisar 320, 390, 600, 768,
  1023, 1024 y 1440 px con texto normal y largo; guardar capturas y medidas.
- [x] **14.06 · Evaluar composición, no sólo overflow.** Registrar collision,
  crowding, hierarchy, grouping, alignment, density, action dominance,
  responsive composition y adherence to PULZ Foundations por modo.
- [x] **14.07 · Repetir checks locales.** Tipos, lint del alcance, pruebas del
  módulo y batería local, build de app y demo. Informar totales reales y
  exclusiones; no exigir que el número histórico de pruebas siga siendo 168.
- [x] **14.08 · Emitir dictamen visual nuevo.** Lima cierra MH-F3-VIS-01 sólo
  con evidencia. Si queda otro hallazgo, anotar ID, severidad, propietario y
  criterio de cierre; no marcar el bloque como aprobado.

Cierre del bloque: etiqueta legible sin corte residual problemático, geometría
preservada o aprobada nuevamente y regresiones afectadas verificadas.

### 15 · Validar acceso y proceso alojado

Responsables: Coco prepara y prueba; Lima consume resultados. **R05: conectividad
diagnosticada y cinco tests de acceso autorizados PASS.** El bloqueo restante es
autorizar fixtures persistentes aislados y operaciones de negocio. Este plan
no sustituye esa autorización específica ni permite tocar demos existentes.

- [x] **15.01 · Diagnosticar conectividad sin mutar datos.** Distinguir falta
  de red/permisos de ejecución, endpoint no disponible y rechazo funcional;
  registrar causa sin exponer credenciales ni eludir controles de seguridad.
- [ ] **15.02 · Identificar el entorno de prueba.** Documentar proyecto,
  empresa/tenant, usuarios por rol y datos que pueden usarse. No asumir que
  una demo existente es desechable.
- [ ] **15.03 · Resolver autorización de escrituras y limpieza.** Precisar
  operaciones, fixtures aislados y cómo retirarlos o conservarlos. Solicitar
  autoridad específica si falta; no hacer reset ni borrar datos ajenos.
- [x] **15.04 · Repetir los cinco tests de acceso alojado.** Empresa inexistente,
  usuario inexistente, contraseña incorrecta, usuario de otra empresa y entrada
  válida del titular. Guardar resultado individual; RED no equivale a rechazo
  correcto. Los intentos de login requieren cuentas de prueba y evitar bloqueos.
- [x] **15.05 · Verificar permisos reales.** Admin y productor pueden las cuatro
  operaciones; operador y modo lectura no pueden mutar, tanto en UI como ante
  la API. Comprobar aislamiento con un segundo tenant de prueba autorizado.
- [x] **15.06 · Probar recepción mínima.** Registrar sólo kilos y verificar lote,
  saldo, fecha, autor y opcionales vacíos; después probar una recepción con
  opcionales explícitos sin inventar valores.
- [x] **15.07 · Probar apertura con revisión.** Elegir horno y kilos de dos lotes;
  volver y revisar sin perder datos; confirmar y contrastar consumos y saldos
  del servidor con la captura. Un exceso debe rechazarse sin consumo parcial.
- [x] **15.08 · Probar cierre.** Registrar kilos cocidos, comprobar estado cerrado,
  lote resultante y linaje, y que la cantidad del resultado coincida con la
  persistida. Verificar el aviso temporal sin inventar una regla nueva.
- [x] **15.09 · Probar entrada de cocido existente.** Verificar carga inicial sin
  historia supuesta, unidad kg y ausencia de una horneada ficticia.
- [x] **15.10 · Verificar continuidad a Formulación.** Desde cocido con saldo,
  abrir la ruta real y comprobar que el lote esté disponible. Si se prueba
  consumo, incluirlo antes en la autorización de fixtures. No rediseñar Tina
  ni modificar FilaUso.
- [x] **15.11 · Probar respuesta incierta con servidor real.** En entorno aislado,
  simular pérdida de respuesta después del commit; reintentar y comprobar una
  sola operación. Mantener cantidad, fecha y clave, incluso tras navegar y
  recargar. No confundir dos llamadas con dos registros.
- [x] **15.12 · Probar recuperación de señal.** Abrir desde instantánea, comprobar
  captura bloqueada y etiqueta de antigüedad; reconectar, refrescar y validar
  que sólo los datos frescos habiliten escritura. No debe reenviar solo.
- [x] **15.13 · Revisar partición de intenciones.** Cambiar de empresa/persona
  sin mostrar ni reenviar la intención ajena; recuperar la original al volver.
  Verificar rechazo confirmado frente a resultado incierto.
- [x] **15.14 · Cerrar fixtures y evidencias.** Aplicar únicamente la limpieza
  autorizada y verificarla; guardar IDs de ejecución y resultados sanitizados,
  nunca contraseñas/tokens. Si quedan datos de prueba, identificarlos.
- [x] **15.15 · Emitir resultado técnico alojado.** Consolidar PASS/FAIL/BLOCKED
  por caso y separar el estado local del remoto. No cerrar el bloque con casos
  obligatorios omitidos.

Cierre del bloque: flujo real consistente, permisos/aislamiento demostrados,
idempotencia confirmada y fixtures reconciliados. Requiere completar 15.01–15.03
antes de cualquier prueba mutante.

### 16 · Completar accesibilidad y uso real

Responsables: Coco verifica y corrige; Lima evalúa. Dependencia: versión visual
fijada en 14. Puede adelantarse en demo con datos simulados si 15 está bloqueado;
se debe declarar ese alcance y repetir lo que cambie en el shell autenticado.

- [x] **16.01 · Preparar matriz de dispositivos.** Registrar navegador, sistema,
  tamaño CSS, dispositivo táctil y tecnología de asistencia disponibles;
  identificar explícitamente recursos faltantes.
- [ ] **16.02 · Completar todos los recorridos por teclado.** Recepción, revisión
  y vuelta, apertura, cierre, cocido existente, Más y detalle; verificar orden,
  foco visible, ausencia de trampas, Escape y retorno al disparador o resultado.
- [ ] **16.03 · Probar touch físico.** Medir targets mínimos de 44 px y comprobar
  taps, desplazamiento, apertura/cierre de capas y acciones sin pulsaciones
  accidentales. Una medición DOM sola no cierra la prueba física.
- [ ] **16.04 · Probar teclado virtual.** Capturar kilos y fechas en móvil real;
  comprobar que campos, error y confirmación no queden tapados por teclado,
  navegación inferior ni áreas seguras.
- [ ] **16.05 · Probar texto al 200% de forma nativa.** Usar ampliación real del
  navegador/sistema, no el selector aproximado del arnés; comprobar todos los
  formularios, listas, navegación y capas sin pérdida de contenido o funciones.
- [ ] **16.06 · Probar forced-colors.** Usar un entorno que lo soporte; verificar
  foco, bordes, estado activo, errores y botones. CSS presente no equivale a
  prueba ejecutada.
- [ ] **16.07 · Probar lector de pantalla.** Comprobar nombres, headings, regiones,
  unidad kg, estado deshabilitado, descripción de errores, diálogo y anuncio
  de éxito, sin lectura del fondo inactivo ni avisos duplicados/confusos.
- [ ] **16.08 · Medir contraste y movimiento.** Texto normal/secundario/error,
  controles y foco con colores computados; verificar reduced-motion en las
  transiciones aplicables y justificar N/A si no hay movimiento.
- [ ] **16.09 · Probar contenido extremo.** Folios/contextos largos, listas
  paginadas, cantidades decimales/grandes y mensajes de error largos con texto
  ampliado; comprobar comprensión y agrupación, no sólo desborde.
- [x] **16.10 · Corregir y volver a comprobar hallazgos.** Cada defecto tiene
  reproducción, propietario y evidencia posterior. Si cambia geometría,
  devolver a Kiwi; respetar el ciclo acotado de revisión de Impeccable.
- [x] **16.11 · Emitir matriz a11y final.** Registrar resultado y evidencia por
  criterio, dispositivo y recorrido. No declarar WCAG 2.2 AA global si sólo
  se verificó una parte; mantener PARTIAL ante cualquier prueba exigible pendiente.

Cierre del bloque: pruebas requeridas ejecutadas en el medio apropiado, sin
hallazgos bloqueantes y con limitaciones expresas. «No disponible» no es PASS.

### 17 · Reevaluar gates y sincronizar el cierre

Responsables: Lima gobierna; Mora documenta lo permitido. Dependencia: 14–16
con evidencia vigente o un dictamen explícito que mantenga el estado parcial.

- [x] **17.01 · Consolidar la matriz de evidencia.** Para cada requisito enlazar
  implementación, prueba, resultado, fecha y limitación; separar evidencia de
  la demo, app autenticada y dispositivo físico.
- [x] **17.02 · Revalidar regresiones finales.** Ejecutar tipos, lint, pruebas y
  builds después del último cambio; registrar totales, exclusiones y fallos.
  Comprobar que Foundations, FilaUso y rondas cerradas no tengan cambios ajenos
  a lo autorizado en la nueva ronda.
- [x] **17.03 · Evaluar las seis dimensiones por separado.** Technical,
  structural, visual, accessibility, design_system y documentation; cada PASS
  requiere evidencia propia. Un build correcto no aprueba composición.
- [x] **17.04 · Evaluar Candidate Gate con reglas actuales.** Registrar cada
  criterio, incluidas revisiones prescritas; no asumir que «implementado»
  convierte automáticamente el draft en candidate.
- [x] **17.05 · Evaluar Stable Gate sólo si procede.** Verificar prerequisites,
  uso realista, auditoría y aprobación exigida por el protocolo. Si falta una
  autoridad específica, pedirla; autonomía de detalle no reemplaza cualquier
  gate ni autoriza despliegue.
- [x] **17.06 · Sincronizar documentación permitida.** Mora actualiza ficha,
  preview, registry, seis dimensiones, warnings y enlaces con el estado que
  Lima haya decidido; una aceptación parcial debe seguir visible como tal.
- [x] **17.07 · Verificar el Hub final.** Build, carga HTTP, preview real,
  navegación, anchors, IDs, enlaces y coherencia de metadata/API; guardar captura.
- [x] **17.08 · Sellar la ronda.** Escribir result.md, compliance, dictamen y
  manifest de hashes nuevos; enlazar desde este checklist, ESTADO y DECISIONES.
  No reescribir evidencia histórica para que parezca aprobada.
- [x] **17.09 · Cerrar o devolver explícitamente el frente.** Enumerar lo resuelto,
  lo pendiente y el criterio fallido, si existe. Sólo marcar aceptación completa
  cuando no quede un requisito obligatorio abierto. No cerrar Fase 5 completa
  ni iniciar otro frente por terminar Maguey/Horneado.

Cierre del bloque: estado final trazable, sin PASS heredados ni pendientes
ocultos. **Despliegue de producción y apertura de otros frentes no forman parte
de este plan.**

### Registro de ejecución de los pendientes

Usar una fila por ítem que se trabaje; añadir la evidencia al marcarlo.

| Ítem | Estado | Fecha | Evidencia | Resultado o bloqueo |
|---|---|---|---|---|
| 14.01 | DONE | 2026-09-28 | r05/brief.md | Ronda nueva, aprobación propia |
| 14.02 | DONE | 2026-09-28 | r05/evidence/preserved-baseline.json | Geometría y archivos protegidos |
| 14.03 | PARTIAL | 2026-09-28 | r05/evidence/before-768.png | Defecto reproducido768; bordes verificados después; falta shell autenticado |
| 14.04 | DONE | 2026-09-28 | NavEtiquetas.test.ts | Corte explícito + nombre accesible |
| 14.05 | DONE local | 2026-09-28 | r05/evidence/visual-runtime.json |14 observaciones con ancho real correcto |
| 14.06 | DONE local | 2026-09-28 | r05/acceptance-matrix.md |9 criterios de composición |
| 14.07 | DONE | 2026-09-28 | r05/evidence/vitest-final.json |183 locales, build/tipos/lint PASS |
| 14.08 | DONE local | 2026-09-28 | r05/lima-f3-verdict.yaml | MH-F3-VIS-01 cerrado; no promoción |
| 15.01 | DONE | 2026-09-28 | r05/acceptance-matrix.md | DNS sandbox; HTTPS fuera401 |
| 15.02–15.03 | BLOCKED parcial | 2026-09-28 | r05/acceptance-matrix.md | Proyecto/cuentas identificados, faltan fixtures aislados autorizados |
| 15.04 | DONE | 2026-09-28 | r05/evidence/hosted-access.json |5/5 PASS tras autorización explícita |
| 15.05–15.14 | BLOCKED | 2026-09-28 | r05/acceptance-matrix.md | Sin operaciones de negocio remotas; mocks no sustituyen servidor |
| 15.05–15.11, 15.14 | DONE (API) | 2026-09-28 | r06/evidence/hosted-api.json | `node scripts/test-mh-hosted-r06.mjs` contra `ypgeiyorgktshgbzhgfh` (CLAUDE.md §1): 37/37 PASS en dos tenants desechables `qa-mh-r06-*`: permisos admin/productor/operador/otro tenant/solo lectura, recepción mínima y con opcionales, exceso atómico, apertura con dos lotes, cierre con linaje, cocido sin horneada, formulación real, lote ajeno rechazado sin consumo, respuesta perdida post-commit con reintento; limpieza exacta `cleanup.json` = 0 restantes; huella de datos existentes idéntica antes/después. Nivel API autenticada, no navegador |
| 15.12, 15.13 | DONE (UI) | 2026-09-28 | r06/evidence/ui-15-12-15-13.json + 6 capturas | `node design-hub/qa/e2e-mh-r06.mjs` (Playwright, shell autenticado, proyecto alojado): 19/19. 15.12: sin señal la página de Maguey se monta desde la instantánea con «Mostrando datos guardados el <fecha>», primaria y reintento bloqueados; al volver la señal solo los datos frescos habilitan la escritura y no se reenvía nada. 15.13: una petición abortada deja la intención (123 kg) sin confirmar; la dueña de Prueba B no la ve ni la reenvía; al volver Aurelia la recupera; recargar no reenvía; el reintento del original escribe exactamente una recepción; un rechazo P0001 confirmado libera la intención sin escribir. Defecto encontrado y corregido: sin señal la página pedía «vuelve a entrar» en vez de mostrar la instantánea (ProcesoSolidoPage) |
| 15.15 | DONE dictamen | 2026-09-28 | r05/acceptance-matrix.md | Resultado remoto PARTIAL, no bloque15 cerrado |
| 16.01 | DONE | 2026-09-28 | r05/acceptance-matrix.md | Capacidades y ausencias identificadas |
| 16.02 | PARTIAL | 2026-09-28 | r05/evidence/keyboard.json | Cuatro capturas demo, Más/detalle/revisión/foco; falta barrido completo |
| 16.03–16.07 | BLOCKED | 2026-09-28 | r05/acceptance-matrix.md | Hardware/AT/zoom nativo no disponibles |
| 16.08–16.09 | PARTIAL | 2026-09-28 | r05/evidence/computed-colors.json | Muestreo + folios/decimales; no matriz completa |
| 16.10 | DONE local | 2026-09-28 | r05/declaracion.md | Hallazgos reparados y regresiones nuevas |
| 16.11 | DONE dictamen | 2026-09-28 | r05/acceptance-matrix.md | Accessibility PARTIAL |
| 17.01–17.06 | DONE evaluación | 2026-09-28 | r05/lima-f3-verdict.yaml | Draft0.2.1; Candidate y Stable no elegibles |
| 17.07 | DONE | 2026-09-28 | r05/evidence/documentation-check.json | Hub48 fichas;121 referencias,0 ausentes/IDs duplicados |
| 17.08 | DONE | 2026-09-28 | r05/evidence/artifact-hashes.json | Ronda sellada,36 archivos protegidos sin cambios |
| 17.09 | DEVUELTO PARTIAL | 2026-09-28 | r05/result.md |22/43 ítems cerrados/evaluados;21 abiertos; no aceptación completa |

### Referencias de partida

- [Resultado r04](../../design-hub/lab/maguey-horneado/r04/result.md).
- [Dictamen F3 de Lima](../../design-hub/lab/maguey-horneado/r04/lima-f3-verdict.yaml).
- [Compliance r04](../../design-hub/lab/maguey-horneado/r04/compliance-current.json).
- [Ficha draft actual](../../design-hub/Screens/maguey-horneado.md).

### Correcciones F3 comprobadas

- [x] Respuesta HTTP incierta conserva la intención y no permite confirmar datos distintos.
- [x] Reintento tras desmontar conserva cantidad, hora y clave; partición empresa/persona/destino.
- [x] Error de almacenamiento bloquea llamada RPC; no reenvío automático.
- [x] Reconexión recarga instantánea y permite actualizar explícitamente.
- [x] Paridad de insets16/24 y rail160/240 en código app/demo; título único.
- [x] Foco al entrar, volver de revisión y mostrar resultado.
- [x] Errores de cantidad/fecha usan danger-text canónico.

## Bitácora de avance

- Inicio: 00 resuelto. R02 preservada como rechazo; revisión/corrección nueva
  en r03. Evidencia se añadirá al cerrar cada punto, no por intención.
- 01 resuelto: `design-hub/lab/maguey-horneado/r03/{brief.md,index.html,kiwi-decisions.yaml}`.
- 02, 03, 04, 06 y 08 resueltos en el simulador: `node --test
  design-hub/lab/maguey-horneado/r03/prototype.test.mjs`, **8/8 PASS**.
  Incluye también permisos, resultado con cantidades editadas y todos los
  estados sin IDs duplicados/descripciones ARIA huérfanas. JSDOM no prueba
  composición ni foco nativo: 05, 07 y 09 siguen abiertos hasta navegador.
- Confirmación: **11/11 pruebas PASS**, checker Kiwi **0 errores / 0 avisos**.
  07 resuelto con navegador; 09 y 10 ejecutados. Evidencia nueva en
  `design-hub/lab/maguey-horneado/r03/evidence/runtime-confirmation.json`.
- Un lote de revisión, una corrección y una confirmación según Impeccable.
  Resta crowding en navegación a 320 px; no confundir ausencia de overflow
  con aprobación de composición. Se devuelve a Kiwi, no se construye F3.
- r04: MH-DOC-03 resuelto en nota de la nueva ronda. Autonomía ratificada por
  el usuario; se continúa con Coco sin solicitar decisiones de detalle.
