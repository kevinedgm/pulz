# Maguey/Horneado · pruebas que exigen hardware y lector de pantalla (16.03, 16.04, 16.07)

Estas tres no se certifican desde este entorno: no hay teléfono físico ni
tecnología de asistencia que se pueda operar de verdad. El 2026-09-28 se
intentó con el simulador de iOS 26 (Safari, iPhone 17 Pro) y se descartó
como evidencia: el panel inyecta toques que Safari interpreta como
pulsación/hover (un campo necesita dos toques para enfocar y a veces abre
el menú de pegar) y, con el teclado en pantalla activo, la escritura
inyectada no llega. Aunque funcionara, un simulador no es un dispositivo
físico y «no disponible» no es PASS. Lo único observado con valor: el
teclado del sistema sube sobre la barra de acción del portal («Entrar»
queda debajo hasta que se cierra el teclado o se envía con la tecla de
retorno), que es el comportamiento normal de iOS Safari.

## Guion de 15 minutos con un teléfono real (para el dueño o quien pruebe)

Requisitos: un iPhone o Android reciente con `http://<ip-de-tu-mac>:5173`
alcanzable (mismo wifi; `pnpm --filter @pulz/web dev -- --host`), usuario
`aurelia` / contraseña de la semilla en Cuatro Vientos, y una tina de
prueba que no importe medir. Anota cada paso como PASS / FAIL con una foto
de pantalla. Todo lo que se registre se retira con `db reset --linked`.

### 16.03 · Tacto físico (targets ≥ 44 px, sin toques accidentales)

1. Inicio → **Maguey** con un solo toque en la barra inferior (pulgar, una
   mano). ¿Entró a la primera? ¿Tocó el ítem de al lado por error?
2. Maguey → **Registrar recepción** (botón de la cabecera). Un toque.
3. En el formulario: toca «Detalles opcionales», luego cada selector
   (especie, predio, proveedor) y «cambiar» de la fecha. ¿Alguno pidió
   dos toques o abrió otra cosa?
4. Desplaza la lista con el dedo desde la mitad de la pantalla (no desde
   los bordes): ¿se mueve suave, sin activar botones al pasar?
5. Horneado → «Cocido que ya tenía» abre una capa: cierra con la **X** y
   con un toque **fuera** de la capa. ¿Se cerró solo cuando querías?
6. Con el pulgar en el borde inferior, toca la barra de navegación cinco
   veces seguidas en ítems distintos: ninguna pulsación debe caer en el
   ítem vecino.

### 16.04 · Teclado virtual (nada tapado por teclado, barra inferior ni áreas seguras)

1. Maguey → Registrar recepción → toca **Kilos**. Con el teclado abierto:
   ¿ves el campo, su etiqueta y la unidad «kg»? ¿La barra inferior de
   navegación se ocultó (no debe quedar flotando sobre el teclado)?
2. Escribe `abc` y sal del campo: ¿ves el mensaje de error completo sin
   cerrar el teclado?
3. Toca «cambiar» junto a «¿Cuándo pasó?»: el selector de fecha nativo
   ¿aparece completo y se puede confirmar?
4. Escribe `120` en Kilos y usa la tecla **Ir/Intro** del teclado: ¿se
   registró o al menos llegaste al botón «Registrar recepción» sin que el
   teclado lo tapara para siempre?
5. Repite 1–2 en un teléfono con **muesca/isla dinámica en horizontal**:
   ¿algún control queda bajo la muesca o la barra de inicio?

### 16.07 · Lector de pantalla (VoiceOver en iOS · TalkBack en Android)

1. Activa el lector. En Maguey, recorre con deslizamientos a la derecha:
   ¿lee «Maguey, encabezado», luego el resumen «N lotes con saldo … kg»?
2. En una fila de lote: ¿lee folio, contexto, «… kg restantes de … kg» con
   la unidad, el estado («con saldo») como texto y el botón «Ver detalle»?
3. «Registrar recepción» → Kilos: ¿anuncia «Kilos (obligatorio), campo de
   texto» y, tras un valor inválido, el error asociado al campo?
4. Un botón deshabilitado (p. ej. la primaria sin kilos): ¿lo anuncia
   «atenuado/desactivado» y lee el motivo si lo hay?
5. Horneado → «Cocido que ya tenía»: al abrir la capa, ¿el foco entra a la
   capa, lee su título y **no** puede llegar al fondo con deslizamientos?
   Al cerrarla, ¿vuelve al botón que la abrió?
6. Registra una recepción de prueba: ¿anuncia el resultado («Recepción
   registrada · … kg») una sola vez, sin repetir el banner del shell?

## Qué hacer con el resultado

Cada FAIL vuelve a coco con la foto; si obliga a cambiar estructura o
flujo, se abre kiwi r07. Con los tres PASS, lima cierra el bloque 16 y
reevalúa Candidate para `maguey-horneado`.
