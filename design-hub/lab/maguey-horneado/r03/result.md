# Maguey/Horneado r03 · resultado

2026-09-28 · **REJECTED F2**. Seis de los siete hallazgos r02 resueltos;
adaptación parcialmente resuelta. **Coco no autorizado. Mora no elegible.**
El frente único sigue siendo Maguey/Horneado; no se abre otro proyecto/fase.

## Checklist y artefactos

- [Checklist vivo](../../../../docs/plan/CHECKLIST-MAGUEY-HORNEADO.md).
- [Wireframe F2](index.html), [decisiones](kiwi-decisions.yaml),
  [declaración](declaracion.md), [gate Lima](lima-contract.yaml),
  [seis dimensiones](compliance-current.json).
- [Evidencia runtime](evidence/runtime-confirmation.json) y [QA compact](qa-compact.html).

## Resuelto con evidencia nueva

Recepción sin opcionales supuestos; borrador preservado entre revisión/vuelta;
fecha de cierre coherente y advertencia al editar; exceso de saldo y ARIA
sincronizados; kg presentes en total/revisión/resultado; cierre por teclado con
contención bidireccional, Escape y devolución de foco. También se corrigieron
el botón de volver y el menú que permitía eludir el estado de solo lectura.

Geometría: columnas de kg alineadas en expanded, acciones legibles, rail
medium completo y folios compactos a todo el ancho. Primaria compact visible
en cabecera, sin FAB duplicado. Los valores de referencia son del F2 neutral,
no nuevos tokens canónicos ni estilos listos para producción.

## Seis dimensiones

| Dimensión | Resultado | Evidencia / límite |
|---|---|---|
| technical | PASS, solo F2 local | 11/11 Node/JSDOM; checker 0 errores/0 avisos; medición de overflow |
| structural | FAIL | navegación inferior a 320 px todavía amontona dos destinos |
| visual | FAIL | crowding pendiente, aunque no exista overflow |
| accessibility | PARTIAL | foco/teclado de cierre verificados; faltan zoom, forced-colors, touch físico y lector |
| design_system | PENDING_F3_VALIDATION | fuentes canónicas existen; F2 neutral no prueba consumo de tokens de producción |
| documentation | PARTIAL | trazabilidad nueva completa; nota heredada del F2 todavía menciona FAB |

## Revisión de composición

- Collision: no solapamiento observado en filas y cierre revisados.
- Crowding: **FAIL** en navegación compact 320; Fermentación/Destilación se leen pegadas.
- Hierarchy: kg dominantes, identificación/contexto secundarios; mejora confirmada.
- Grouping: abiertas / cocido con saldo / últimas se conservan.
- Alignment: tres columnas numéricas a x=608 y ancho=311 en 1440 px.
- Density: folio largo ya usa todo el ancho; navegación inferior aún demasiado densa.
- Action dominance: una primaria visible; compact en cabecera. Acciones de fila de 48 px.
- Responsive composition: 1440/1024/768/390 revisados; borde 320 devuelve hallazgo.
- PULZ Foundations: rangos adaptativos respetados; color/type/icon/motion de F3 no certificados.

## Verificaciones

`node --test design-hub/lab/maguey-horneado/r03/prototype.test.mjs`: **11/11**.
`python3 .codex/skills/kiwi/scripts/check_artifact.py design-hub/lab/maguey-horneado/r03/index.html`:
**0 errores / 0 avisos**. La marca mecánica de primarias agrega todas las
plantillas: no se interpreta como aprobación visual de cada vista.

Browser: anchos CSS reales 1440/1024/768; iframe de 390/320 CSS px para compact.
No hubo overflow horizontal en las listas medidas. Cierre: foco `kc`,
Shift+Tab a Cancelar, Tab a `kc`, Escape al disparador; guardar con Enter
mostró los **4,321 kg** capturados. No datos persistidos.

## Pendiente único siguiente, sin reiniciar el frente

Kiwi r04 debe resolver `MH-NAV-03` (separación de destinos a 320 px) y
sincronizar la nota de primaria `MH-DOC-03`. Conservar todos los avances
enumerados en el contrato. Lima valida; no impone geometría ni construye.
No generar orden de Coco ni publicar una página canónica hasta el gate válido.

Se completó el ciclo acotado de Impeccable: revisión → lote de correcciones →
confirmación. Se detiene el pulido de r03 y queda congelada como evidencia
rechazada, no como estructura aprobada. Sin subagentes nuevos ni escritura DB.

## Warnings

Capturas iniciales llamadas `h-default-390.png` / `h-default-320.png` se tomaron
con viewport externo limitado a **480 px**; no prueban esos tamaños. Las
capturas `confirm-*-390/320.png` usan iframe con esos anchos CSS comprobados.
Ver [notas de evidencia](evidence/README.md).
No se ejecutaron build de aplicación, tests globales, RPC o E2E de producción
porque esta ronda solo cambia el laboratorio y documentación. No certificar
WCAG global. R02 conserva los hashes anteriores, no se sobrescribió ni aprobó.
