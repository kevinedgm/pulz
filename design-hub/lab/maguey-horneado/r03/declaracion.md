# Declaración Kiwi · Maguey/Horneado r03

2026-09-28 · Ruta R1 · Fidelidad F2 · Producción modificada: **no**.
Pregunta: completar recepción/apertura/cierre sin datos supuestos, pérdida de
borrador ni acciones ambiguas, en todos los rangos de espacio.

## Estándares leídos

Maestro PULZ, CLAUDE.md, plan Fase 5, perfil PULZ; Kiwi brief funcional,
user-flow, fidelidad, wireframing, kit neutral, HIG web/PWA, validación y
contrato de geometría; Lima source-of-truth y quality-gates; Impeccable
adapt/polish/craft-floor. No nuevas leyes visuales de producción.

## Adaptación y estado

| Elemento | Compact | Medium | Expanded |
|---|---|---|---|
| Navegación | inferior; Más abre destinos | rail 160 px con etiquetas | sidebar 240 px |
| Fila | identidad, kg, estado y acciones apilados | identidad/estado; kg y acciones debajo | desde 1200, identidad/kg/acciones alineadas; 1024–1199 apilado parcial |
| Primaria | cabecera, sin FAB duplicado | cabecera | cabecera |
| Formularios | una columna | pares compatibles | pares compatibles |
| Cierre | hoja inferior ≤90dvh | dialog lateral 440 px | dialog lateral 440 px |
| Continuidad | borrador en memoria; resize no reconstruye DOM | igual | igual |

## Comprobaciones ejecutadas

- Checker Kiwi: 0 errores, 0 avisos. Neutralidad F2, no conformidad F3.
- 11/11 pruebas Node/JSDOM: opcionales, borrador, cantidades/unidades, fecha,
  error reactivo, permisos, volver, resultado y estados sin errores JS,
  IDs duplicados o referencias ARIA huérfanas.
- Navegador: 1440/1024/768 CSS px; iframe con viewport CSS 390/320 px.
  Sin overflow horizontal en listas medidas. No equivale a móvil físico.
- Revisión/apertura: exceso, corrección y retorno conservaron cantidades,
  fecha y folio en la primera pasada; regresión automatizada tras corrección.
- Confirmación cierre: foco inicial `kc`; Shift+Tab → Cancelar; Tab → `kc`;
  Escape → Cerrar horneada. Cierre por teclado muestra 4,321 kg editados.
- Cantidades expanded a 1440: mismo x=608 y ancho=311 en tres filas.
  Botones de fila medidos con 48 px de alto y ancho suficiente.
- Una revisión conjunta, una corrección y una confirmación. Sin más pulido.

## No comprobado / límites

Zoom nativo de texto 200%, forced-colors, lector de pantalla, teclado virtual,
touch físico, orientación y safe-area real pendientes. No RPC, persistencia
real, pruebas E2E del producto, build de aplicación ni F3 en esta ronda.
Destinos fuera del frente se representan sin construir sus pantallas.

## Hallazgos y traspaso

`MH-NAV-03`: crowding de Fermentación/Destilación a 320 px. `MH-DOC-03`:
nota heredada de Maguey aún describe FAB; la geometría r03 usa cabecera.
Lima recibe esta declaración como evidencia **no aprobada**, valida y devuelve
a Kiwi. Coco y Mora no elegibles. No se pide aprobación visual sobre un FAIL.
Siguiente trabajo: corregir esos dos puntos en r04 conservando el resto y
volver a evaluar; no añadir componentes o reglas de negocio.
