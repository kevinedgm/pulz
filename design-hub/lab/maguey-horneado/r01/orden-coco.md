# Orden de construcción para coco · maguey-horneado/r01 · lima · 2026-09-27

Estructura congelada en `brief.md`, `index.html` (60 combinaciones · 0
hallazgos), `hallazgos.md`, `declaracion.md`. Aprobación automática
(`CLAUDE.md` §4).

## Clasificación

| Pieza | Clase | Decisión |
|---|---|---|
| `maguey-horneado` | product-application | **new**: `modules/maguey/` (`MagueyPage`, `RecepcionPage`) y `modules/horneado/` (`HorneadoPage`, `AbrirHorneadaPage`, `CerrarHorneadaCapa`, `CocidoCapa`), un `api.ts` por módulo |
| `origin-allocation` | pattern | **reuse** (kg; tercer consumidor → cumple el pendiente para Stable) |
| resto de piezas | — | **reuse** sin cambios |

Registro: `maguey-horneado` como `draft` 0.1.0.

## Orden

1. `conInstantanea` pasa a `shared/offline/instantanea.ts` (hoy duplicado en
   fermentación, destilación y granel; hallazgo LOW de destilación).
2. Módulos `maguey` y `horneado` con rutas, `destinos.ts` sin
   `proximamente`, puras con prueba (`kgRestantes`, `merma`).
3. Evidencia `qa/evidencia-maguey-horneado.mjs` con escrituras reales
   (recepción 2,000 kg Tobalá → horneada → cierre 1,800 kg) en 4 anchos × 2
   temas; `db reset` al cerrar la fase.
4. Declaración → lima → mora (`Screens/maguey-horneado.md`) → sitio.
