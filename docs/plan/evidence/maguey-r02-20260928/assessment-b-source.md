# Confirmación B de r02 — 2026-09-28

Target: `design-hub/lab/maguey-horneado/r02/index.html`. Estado: F2/proposed según `kiwi-decisions.yaml`; no aprobación F3. Sólo lectura de fuentes, sin cambios a UI/registry/DB. No se repitió detector. Se conservó independencia de A y sólo se coordinó disponibilidad del navegador.

## Cobertura y límite observado

No se pudo ejecutar la pasada DOM/runtime/responsive ni guardar capturas nuevas desde B. `cua.createBrowserTab('iab', URL, {visible:false})` falló con `Browser is not available: iab`; inventario de browsers devolvió `[]`. Tras aviso del padre de recuperación se reintentó, volvió a fallar; se reinició kernel y `cua.getState()` devolvió `{apps:[],browsers:[]}`. No se cambió viewport ni se creó pestaña. No se usó navegador externo para sortear la limitación. Las conclusiones siguientes son **verificación de fuente, no observaciones de runtime**.

## Correcciones presentes en fuente

- Vacíos compact: primarias de m-empty y h-empty ya no tienen `data-wf-persist`, de modo que no les aplica la regla que las ocultaba (líneas 303 y 310). Rutas de ambos botones añadidas (377–378).
- Etiquetas: Especie/Predio/Proveedor/Horno tienen `for` y `id`; los campos repetidos tienen nombres `Kilos de MAG-003` y `Kilos de MAG-002` (293–294). k2 trae `aria-describedby="k2-error"`, aunque sólo existe ese nodo en el estado inicial de saldo excedido.
- Identidad del ejemplo: HOR-003 abierta usa MAG-004/MAG-005, AC-002 procede de HOR-002. Ya no se duplica la condición abierta/cerrada en el mismo folio.
- Geometría: stage sin padding, frame con max-width100%/sin borde (180–181); selector1024 presente y S.w usa el ancho real inicial (321). Rail medium96px en600–1023 (193–199); sidebar base240px a1024/1440. Son reglas inspeccionadas, sin medición runtime.
- Apertura sin preselección: k1/k2 vacíos en h-abrir; min0, máximos2000/1300, step0.001; primaria inicialmente disabled (293–298).
- Handler input suma cantidades, valida y habilita revisión; submit incluye sólo lotes con valor>0, total e irreversibilidad (350–369). Ruta fuente esperada: ambos vacíos→deshabilitada; k1=500/k2vacío→500kg, revisión sólo MAG-003.
- Escape y Cancelar tienen rutas para cerrar la capa (379–381), aunque sigue sin código de gestión de foco/trampa/restauración.

## Pendientes concretos encontrados en fuente

1. **P2 — Corrección de saldo deja un mensaje de error obsoleto.** `h-abrir-saldo` dibuja k2=1500 y `#k2-error: Solo hay 1,300 kg.`. Al bajar a1000, el handler puede poner aria-invalid=false y habilitar revisión, pero nunca oculta ni modifica el párrafo de error (294, 350–360). Hace falta comprobar en runtime y sincronizar mensaje/atributo/estado. En h-abrir normal, si se excede cualquier saldo, sólo se marca aria-invalid; no se crea mensaje textual y k2 describe un id inexistente.

2. **P2 — Volver a cantidades descarta la selección que se acaba de revisar.** El botón usa `data-go="h-abrir"` (369), `go` llama render y `abrir()` vuelve a escribir inputs vacíos (293–294). No existe draft de cantidades. Esto afecta al nuevo flujo de revisión, no a persistencia de servidor: debería poder corregirse una cantidad sin reconstruir toda la selección.

3. **P2 — Gestión de foco pendiente en la revisión y en modal.** Revisión reemplaza `#wf-view.innerHTML` sin focus; modal se añade por render sin focus inicial, inert o trap. Escape sí tiene handler. Son límites de interacción F2 a cerrar antes de validar accesibilidad interactiva; no afirmar teclado completo por existir Escape.

4. **P3 — El total pierde la unidad después de escribir.** Template `#kg-total` contiene `0 kg` y sigue `de 10,000 kg`, pero handler lo sustituye por sólo `total.toLocaleString` (295/355): aparece «Total 500 de10,000kg». Los botones sí incluyen kg. Conviene mantener unidad en el total.

5. **P2 — Hora de cierre del ejemplo anterior al inicio.** HOR-003 empieza «hoy09:00» y su modal aún tiene `¿Cuándo terminó?=hoy08:00` (template horneadaAbierta y317). Es inconsistencia del ejemplo, no validación de backend.

## Secuencia recomendada para completar runtime cuando vuelva el navegador

En pestaña nueva B o del padre: capturar m-empty/h-empty a390; h-default a768/1024/1440 y medir document/frame scrollWidth. En h-abrir: confirmar k1/k2 vacíos y disabled; escribir500 en MAG-003; revisión debe incluir sólo ese lote y500kg; volver y comprobar conservación. En h-abrir-saldo: cambiar1500→1000 en MAG-002, comprobar total3000/aria-invalid=false/primaria habilitada y desaparición del error; revisar. En recepción expandir Detalles opcionales y verificar nombres accesibles. En cierre comprobar Escape, Cancelar y foco de teclado. No repetir detector en esta pasada confirmatoria.

No hay overlay ni servidor creado por B. No hay temporales que limpiar; este archivo es evidencia persistente. La ausencia de capturas no equivale a aprobación responsive o accesible de r02.
