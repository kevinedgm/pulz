# Hallazgos · SHELL · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | Ocho destinos (§13.1) no caben en una navegación inferior con targets de 44 px: máximo 5 | Compact = 4 fijos (Inicio · Fermentación · Destilación · Granel) + "Más" (hoja con Maguey · Horneado · Trazabilidad · Configuración). Medium/expanded: los 8 en el menú lateral | kiwi → dueño | confirmar el orden de frecuencia (incógnita 2) en la aprobación |
| Alta | El sprite no tiene símbolo para Configuración, Trazabilidad, Granel/tanque ni "Más"; `i-lote` se presta a Granel solo provisionalmente | Van con texto (regla de un solo set); se piden 4 símbolos: `i-tanque`, `i-traza`, `i-ajustes`, `i-menu` | lima → dueño | decidir si se agregan al sprite antes de coco o quedan con texto |
| Media | Con el teclado virtual abierto, una barra inferior fija tapa el campo enfocado en pantallas de 390×780 | Ocultar la navegación inferior mientras un campo tiene el foco (`visualViewport`), no reflow del contenido | coco | técnica en la implementación; probar en iOS/Android reales (no automatizable) |
| Media | "¿Qué tienes hoy?" (vacío de Inicio) tiene su primaria dentro del bloque; en compact la barra inferior ya es la navegación, así que la primaria **no** baja a una barra persistente (a diferencia de acceso/r01) | La primaria vive en el bloque; el FAB queda libre en Inicio | kiwi (declarado) | lima fija en el contrato de `app-shell` que el hueco de FAB es por destino |
| Media | Nombre de empresa largo: en la cabecera compact/medium una línea con elipsis; en el menú lateral dos líneas; completo en `title` y en la cuenta | Declarado en la matriz | coco | — |
| Baja | Texto al 200 % en compact: las etiquetas de la barra inferior (11 px → 22 px) se parten en dos líneas; "Fermentación" y "Destilación" son largas | Etiquetas de ≤ 12 caracteres y dos líneas permitidas; nunca ocultar el texto (WCAG 1.4.4) | coco | verificar con `zoom-*.mjs` |
| Baja | El FAB tapa la esquina inferior derecha del contenido en compact | `padding-bottom` del cuerpo ≥ FAB + barra; el FAB no aparece con capas abiertas ni en solo lectura | coco | — |
| Info | Inicio/hoy, etapas y notificaciones son Fase 5: aquí son destinos vacíos con "próximamente" | Sin datos inventados | kiwi | rondas de Fase 5 |
