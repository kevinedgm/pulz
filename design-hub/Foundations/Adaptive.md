# Adaptación

| Modo | Referencia | Grid | Navegación | Principio |
|---|---|---:|---|---|
| Compact | 0–599 px | 4 columnas | Bottom navigation | Una columna, jerarquía vertical, acción alcanzable y disclosure progresivo |
| Medium | 600–1023 px | 8 columnas | Rail compacto | Coexistencia selectiva; no ampliar móvil mecánicamente |
| Expanded | ≥1024 px | 12 columnas | Sidebar persistente | Master-detail, comparación y ancho de contenido controlado |

Los límites son tokens de referencia de viewport derivados al materializar la propuesta. Los componentes reutilizables prefieren container queries y deben demostrar que su contenido cabe en el contexto real; “sin overflow” no prueba una composición válida.
