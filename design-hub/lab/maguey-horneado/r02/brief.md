# Maguey y Horneado · r02 · Kiwi · 2026-09-28

Ronda nueva. r01 se usa como contexto funcional, nunca como aprobación.
Encargo: continuar Fase 5 y corregir lo encontrado al verificar maestro y planes.
Modo Operate. Admin/productor registra con señal; operador consulta. Suscripción
en solo lectura nunca permite escribir. Recepción requiere solo kilos; los
catálogos opcionales no bloquean. No se modifican roles ni reglas de negocio.

## Flujo

Maguey → Registrar recepción → kilos → detalles opcionales → registrar → lote con saldo.
Horneado → Abrir → horno + kilos por lote (vacío/0 excluye) → revisar horno,
lotes, cantidades y consumo irreversible → abrir → horneada abierta.
Horneada abierta → Cerrar → kilos obtenidos + diferencia + fecha/combustible/nota
→ confirmar → lote cocido disponible → Llenar tinas (formulación existente).
Cocido anterior → carga inicial sin historia. No obliga a reconstruir etapas.

## Corrección devuelta por Lima a Kiwi

Reglas fallidas en la reevaluación: MH-ACTION-01 (primaria desaparece en vacío
compact), MH-DATA-01 (mismo folio abierto/cerrado), MH-SELECT-01 (selección
ambigua), MH-MINIMAL-01 (opcionales sobrecargados), MH-HIERARCHY-01 (kg
subordinados), MH-A11Y-01 (labels sin asociación), MH-ADAPT-01 (rail medium
y visor real de 1024). Lima no editó F2. Kiwi corrige estas decisiones aquí.

Se conservan dos destinos, grupos abiertas/cocido/recientes, agotados plegados,
saldo frente a recibido, campos y RPC existentes, continuidad hacia tinas.
Se reconsideran exclusivamente selección, divulgación, jerarquía, navegación
por rango y continuidad de acciones. No se inventan tokens ni campos de negocio.

## Contrato de datos existente

Lecturas: solid_lot_balances, lots, maguey_receptions, operations, profiles,
roasting_runs, roasting_run_inputs, resources (horno), species, predios, suppliers.
Comandos: registrar_recepcion_maguey, abrir_horneado, cerrar_horneado,
registrar_entrada (agave_cocido; recurso null). Fuentes: migraciones 0008/0009,
0011/0015/0016, maestro §§4.1–4.3, 11.1, 12.2, 13.2 y Fase 5.

No JSON almacenado, saldos calculados por vistas. Merma informativa, nunca un
nuevo lote ni límite duro. Hora local sigue contrato existente. Todos los
comandos online deben conservar clave idempotente entre reintentos de la misma
intención y no borrar datos al fallar. Una nueva intención requiere nueva clave.

## Estados y límites

F2 permite seleccionar estados y recorrer decisiones; no escribe en Supabase.
Carga conserva huella; vacío ofrece siguiente acción; error conserva formulario;
offline muestra antigüedad y bloquea escritura; operador/solo lectura explican
permiso; conflicto de cierre ofrece ver resultado; éxito identifica nuevo lote.
En F3: focus trap/return con CapaTarea, Escape, labels únicos y error asociado,
validación blur, guard de submit por permiso/conexión, doble envío bloqueado,
confirmación al abandonar con cambios. Capturas no prueban escrituras ni WCAG.

Listas: lotes con saldo primero; agotados y horneadas cerradas últimas 10.
Más de 50 activos requiere paginación accesible, no truncar saldos en silencio.
RTL de producto no está solicitado; usar propiedades lógicas donde corresponda.

## Arquitectura prevista (todavía no autorización de F3)

- Páginas de ruta: composición, permisos y navegación; sin lógica de consultas.
- api.ts por módulo: lecturas por empresa + instantánea compartida, RPC tipada.
- useMaguey / useHorneado: carga, reintento y estado, sin estilos.
- ListaMaguey / ListaHorneadas / ListaCocido: datos por props, acciones por emits.
- FormularioRecepcion / FormularioApertura: campos, validación, revisión y submit.
- CerrarHorneadaCapa / CocidoCapa: CapaTarea existente; emits guardado/cancelar.

Reutilizar origin-allocation, number-field, datetime-field, select, button,
state-block, task-layer y shell. Ninguna primitive nueva está justificada.

## Pendiente antes de F3

Revisión nueva de r02, contrato geométrico congelado y autorización explícita
de Lima. Resolver consumo real de Manrope/Instrument Serif/Lucide en primitives
existentes, sin alterar sus bases aprobadas. No promover al registro por existir
un HTML. Las recomendaciones de r01 no certifican esta ronda.
