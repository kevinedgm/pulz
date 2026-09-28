# Maguey/Horneado r04 · Kiwi · 2026-09-28

Ruta R1 · Fidelidad F2 · Modo Operate. Corrección estructural acotada de los
siete rule_ids devueltos por Lima r02. R02 se conserva sin cambios; su rechazo
es insumo, nunca aprobación. Sin producción, RPC, dependencias o tokens nuevos.

## Tarea y decisión

Admin/productor necesita registrar recepción, abrir una horneada y cerrar su
resultado sin consumir lotes por accidente ni perder lo capturado al revisar.
Operador y suscripción vencida consultan; registrar requiere señal.
La pregunta: ¿se puede completar y corregir esta tarea en cada rango, con datos
explícitos, cantidades legibles y teclado completo?

Datos dominantes: kilos restantes y lote; después estado, origen, cuándo/quién.
Preservar dos destinos, abiertas/cocido/recientes, agotados plegados, saldo
restante frente a recibido, cantidades inicialmente vacías, revisión previa al
consumo y continuidad hacia Formulación. No rediseñar otros módulos.

## Flujo

1. Maguey → recepción → kilos (sin valor inicial) → detalles opcionales vacíos
   → registrar → resultado con los kilos realmente capturados.
2. Horneado → apertura → horno + kg por lote + fecha/folio → revisión explícita
   del consumo → volver conserva todo / confirmar simula resultado.
3. Horneada abierta → capa de cierre → kilos, fecha y detalles → resultado AC.
   Escape/cancelar devuelve foco al disparador; cantidades se conservan al
   ocultar y reabrir la capa durante esta sesión del prototipo.
4. Cocido anterior → capa de entrada directa → kilos → resultado sin historia.

Abrir/cerrar consume o crea material: consecuencia explícita antes de confirmar.
El prototipo no escribe. El ejemplo usa 28 sep 2026 y se identifica como ejemplo.
Fecha de cierre inicial 12:00 posterior a inicio 09:00. Si se edita a una hora
anterior se advierte; no se introduce un bloqueo duro de negocio no aprobado.

## Hechos / decisiones / límites

Hechos: maestro §§4.1–4.3, 11.1, 12.2; RPC existentes y datos citados en r02.
Inferencias estructurales: rail de 160 px para etiquetas completas; listas
expanded estrechas (1024–1199) pasan acciones a fila propia; drawer mediante
dialog nativo para contención de foco y Escape. Ninguna es una regla visual F3.

Continuidad: borradores en memoria compartidos entre revisión y formulario;
redimensionar cambia CSS, no reconstruye la tarea. Recargar el prototipo borra
la simulación; persistencia entre sesiones/idempotencia real son contrato F3.
Estados: carga, vacío, error, sin conexión, operador, solo lectura, contenido
largo, sin catálogo/horno/saldo, exceso, revisión, conflicto y éxito. Los links
a destinos fuera del frente explican el handoff sin implementar otra pantalla.

## Criterio de salida

Los siete hallazgos tienen pruebas nuevas y revisión de composición; Lima
emite gate F2 explícito y seis dimensiones sin confundirlo con F3/WCAG global.
Checklist vivo: `docs/plan/CHECKLIST-MAGUEY-HORNEADO.md`.

## Continuación autónoma

Corrección exclusiva de MH-NAV-03 y MH-DOC-03, sin reutilizar aprobación.
Cinco destinos preservados: grid con tracks minmax(0,1fr), gap 8px,
inset 8px y guiones discrecionales en etiquetas largas. Dos líneas donde
haga falta sin bajar tamaño de texto ni target. Nota de primaria sincronizada.
Autonomía autorizada por el usuario y CLAUDE.md §4; decidir gates con evidencia.
