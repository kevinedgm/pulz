# Estándar de ronda documental

Estándar que deben cumplir las rondas que cambian la estructura del Design Hub. Lo **escribe y valida mora**; lo **ejecuta kiwi** cuando wireframea el Hub, y lo **respeta mora** cuando publica las páginas reales. El objetivo es que decisión, representación y evidencia sean trazables entre sí.

| Paso | Quién | Artefacto |
|---|---|---|
| Encargo documental | 🫐 mora | `templates/encargo-estructura.template.md` |
| Ronda de estructura F0–F2 | 🥝 kiwi | `brief.md` · `index.html` · `declaracion.md` (plantillas de kiwi) |
| Validación contra este estándar | 🫐 mora | hallazgos (`structural-repair.md`) |
| Páginas reales en el shell activo | 🫐 mora | páginas + `templates/declaracion.template.md` |

## Lo normativo y lo contextual

La estructura de los artefactos y sus invariantes son normativos. Nombres de producto, categorías, cantidades, rutas, estados, versiones, responsables, breakpoints, CSS inline y datos de ejemplo pertenecen al proyecto de origen: no se copian como defaults.

Si el proyecto ya tiene una especificación o perfil aprobado, manda sobre los ejemplos de esta referencia.

## Paquete de tres artefactos

```text
brief.md        → por qué, para quién, qué se prueba y qué queda fuera
index.html      → evidencia navegable de arquitectura, contenido y estados
declaracion.md  → qué se cumplió, cómo se verificó y qué sigue abierto
```

El prototipo puede usar otra tecnología o nombre si el proyecto lo exige, pero conserva la función del artefacto central. No dupliques información: el brief define; el prototipo demuestra; la declaración verifica. Los tres los produce kiwi; mora aporta el encargo y valida el resultado.

## 1. Brief

Incluye, cuando aplique:

1. **Identidad de la ronda:** producto/sistema, ronda, ruta de proceso, fidelidad, fuente y fecha.
2. **Enunciado:** usuario + necesidad + causa o impacto.
3. **Pregunta de diseño verificable:** verbo principal, resultado observable y dato dominante.
4. **Usuarios y permisos:** necesidad y autoridad real; las incógnitas se mantienen explícitas.
5. **Superficies:** qué páginas/fichas/estados se representan y qué queda fuera.
6. **Flujo:** entrada, decisiones, destinos, recuperación y endpoint observable.
7. **Riesgo por acción:** lectura/navegación, escritura reversible o acción destructiva.
8. **Continuidad:** carga, vacío, error, red/offline si aplica, reanudación y cambio de tamaño.
9. **Alcance priorizado:** Must/Should/Could/Won't u otro esquema explícito.
10. **Hechos, supuestos e incógnitas:** separados; los supuestos no se redactan como decisiones aprobadas.

El brief no certifica implementación ni QA. Define lo que el prototipo debe permitir comprobar.

## 2. Prototipo o `index.html`

### Shell del Hub

- Una sola fuente y una sola instancia de navegación global.
- La misma jerarquía se presenta como sidebar persistente o drawer según el contrato adaptativo; no se mantienen dos árboles independientes.
- Breadcrumb para ubicación; búsqueda global cuando el alcance la incluya.
- “En esta página” es contexto local derivado de secciones reales. Puede ocultarse o compactarse, pero no se convierte en otro drawer global.
- El Hub no adopta la navegación del producto documentado. Si una ficha describe bottom navigation u otro patrón del producto, se muestra dentro de esa ficha, no en el shell del Hub.

### Inicio del Hub

Selecciona bloques según el alcance real. Un inicio completo suele incluir:

- propósito y alcance del sistema;
- acción principal y accesos directos;
- flujos principales;
- pantallas o superficies;
- componentes destacados;
- actualizaciones recientes;
- convenciones de madurez.

No añadas KPIs, miniaturas o métricas decorativas sin una decisión del producto.

### Ficha de pantalla

Orden relativo recomendado:

```text
Header y metadata → Propósito → Ruta/entradas/salidas → Componentes usados
→ Estructura por dispositivo → Estados → Responsive → Eventos/interacciones
→ Criterios de aceptación
```

La ficha de pantalla compone y enlaza componentes; no repite su documentación completa.

### Ficha de componente

Orden relativo recomendado:

```text
Header y metadata → Propósito/cuándo usar → Anatomía → Configuración o API real
→ Estados → Comportamiento/eventos → Responsive → Accesibilidad → Contenido
→ No usar para → QA/Lifecycle
```

La configuración se marca como supuesto si la API aún no existe o no fue confirmada. Una tabla plausible no convierte un supuesto en contrato.

### Metadata

Mantén el mismo orden entre fichas. Como mínimo: estado, versión, actualización y responsable cuando existan. Añade `replaces`/`replacedBy` solo con evidencia. Los marcadores deben llevar etiqueta visible; no aparentan ser datos reales.

### Estados y continuidad

Representa los estados relevantes para la pregunta de diseño:

- carga con una huella estable;
- error con recuperación y navegación aún operativa;
- vacío y vacío causado por filtros, cuando difieran;
- búsqueda con resultados y sin resultados;
- drawer modal en tamaños donde aplique;
- offline solo si el producto lo contempla o se declara como incógnita/propuesta;
- deprecated con reemplazo real o campo pendiente explícito;
- estados propios del componente.

Cada estado documenta disparador, comportamiento y recuperación. No inventes funcionamiento offline, persistencia o datos de reemplazo.

### Responsive

- Usa breakpoints del perfil; si no existen, declara los tamaños como referencias del prototipo, no como contrato.
- Explica qué cambia, por qué y qué permanece invariante.
- Tablas pueden convertirse en bloques cuando el ancho no permite comparación legible.
- Verifica contenido largo, etiquetas extensas y ausencia de overflow horizontal.

### Madurez y accesibilidad

- Draft, Candidate, Stable y Deprecated se distinguen por texto y al menos otra señal no cromática.
- Foco visible, teclado, `Escape`, restauración y focus trap cuando el drawer sea modal.
- Controles principales apuntan a 44 × 44 CSS px; si se usa el mínimo WCAG 2.2 de 24 × 24, documenta las excepciones aplicables.
- La navegación, búsqueda y estados tienen nombres accesibles y atributos ARIA coherentes.
- Movimiento y transiciones respetan `prefers-reduced-motion` cuando existan.

### Fidelidad y estilos

- Las rondas de estructura del Hub son **F0–F2** (kiwi, kit neutral). No hay F3 de la estructura del Hub: la presentación final es el shell activo que mora reutiliza al publicar.
- En F1/F2 sin design system aprobado, usa una presentación neutral y declárala como wireframe.
- Un prototipo autocontenido puede usar estilos inline por portabilidad, pero eso es una desviación documentada, no una base de producción.
- En documentación productiva se reutiliza exclusivamente el shell activo del Hub.
- No copies CSS de componentes ni reconstruyas un shell deprecado para “hacer que se vea”.

## 3. Declaración de cumplimiento

Incluye:

1. resumen de superficie, ronda, fidelidad, pregunta, artefactos y si modifica producción;
2. estándares y fuentes realmente leídos;
3. desviaciones con causa e impacto;
4. matriz criterio → resultado (`cumple`, `parcial`, `no cumple`, `no aplica`) → evidencia/localización;
5. verificaciones ejecutadas con tamaños, herramientas y resultado observable;
6. verificaciones no ejecutadas, sin convertirlas en aprobadas;
7. matriz de estados representados con disparador y recuperación;
8. hallazgos con severidad, decisión, responsable y siguiente acción;
9. próximo paso condicionado por lo pendiente.

Un “✔” exige evidencia. Si una verificación fue manual, emulada, parcial o hipotética, se rotula así.

## Consistencia entre artefactos

Antes de entregar, contrasta:

- mismo nombre de ronda, fidelidad y superficies;
- mismos usuarios, alcance y nomenclatura;
- cada Must del brief tiene representación o desviación explícita;
- cada criterio declarado apunta a una ubicación observable;
- cada prueba mencionada fue ejecutada y sus límites están registrados;
- supuestos e incógnitas conservan esa etiqueta en el prototipo y la declaración;
- el prototipo no introduce rutas, API, versiones o responsables que el brief considere desconocidos;
- hallazgos abiertos alimentan el siguiente paso, sin desaparecer entre rondas.

Las discrepancias inequívocas en la documentación publicada son reparables por Mora; en una ronda de kiwi, Mora las reporta y kiwi abre la siguiente ronda (`rNN+1`), sin sobrescribir la evaluada. Una discrepancia que implique elegir nueva IA, shell, lifecycle o contrato pasa a `REVISAR` según [structural-repair.md](structural-repair.md).
