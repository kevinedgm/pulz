# Orden de construcción para coco · inicio-hoy/r01 · lima · 2026-09-28

Estructura congelada en `brief.md`, `index.html` (45 combinaciones · 0
hallazgos abiertos), `hallazgos.md`, `declaracion.md`. Aprobación automática
(`CLAUDE.md` §4).

## Clasificación y reutilización

| Pieza | Clase | Decisión |
|---|---|---|
| `inicio` | product-application | **extend** (0.2.0 candidate → 0.3.0 draft): `InicioEmpresaPage` deja de ser placeholder; conserva `tieneLotes` → «¿Qué tienes hoy?» → arranque. Locales: `FilaTinaHoy`, `FilaCorridaHoy`, `FilaColectorHoy`, `FilaColaHoy`; `api.ts` (`cargarHoy`, puras `resumenHoy`, `rotuloHora`, `recortar`). |
| `queue-item` (ítem de cola con motivo y acciones) | candidata a pattern | **local por ahora** (`FilaColaHoy`): Inicio es la única lista por elemento; Fermentación y Destilación pintan la cola por fila con `status-chip`. Se extrae al sistema si un tercer consumidor la necesita. |
| `FilaUso` (fermentación) | local de otro módulo | **no se reutiliza**: trae menú, anular/lista/cerrar y corrección por fila; Hoy necesita solo tina · día · última medición · litros · Medir. Se comparte la regla (`agrupar`, `diaDelCiclo`, `haceCuanto`), no la vista. |
| `app-shell` (FAB por `meta.fab` + `useFab`), `page-header`, `banner`, `state-block`, `status-chip` (`pending`, `failed`, `partial`, `on`, `draft`), `list-stack`, `button` | — | **reuse** |

`inicio` queda `draft` 0.3.0 (`sourceRound: lab/inicio-hoy/r01`); la
ficha `Screens/inicio.md` se reescribe cuando mora reciba el código.

## Contrato (congelado)

- **Cabecera**: título «Hoy» con fecha larga (`Intl`, `es-MX`) y hora;
  si hay instantánea: «Mostrando datos guardados el <fecha>» (`<time>`).
- **Resumen** (`role=status`): «N tinas por medir · M corrida(s) abierta(s) /
  sin corridas · K capturas por enviar / nada por enviar».
- **Toca medir**: `agrupar(usos, hoy).porMedir` (mismo orden que
  Fermentación); fila = tina · «toca medir» / «toca desde las H:00»
  (`hora local < measurement_reminder_hour`) · «día N de M» · última
  medición (`haceCuanto` + quién) o «sin mediciones» · litros · **Medir** →
  `/fermentacion/:ciclo/medir`. Máximo 8 filas + «y N más → Fermentación».
  Contexto debajo: «X ya medidas hoy · Y listas para destilar → Fermentación».
  Vacíos: «Todo medido por hoy» / «Sin tinas fermentando» (+ «Llenar tinas»
  para admin/productor con señal).
- **Primaria**: en ≥600 el «Medir» de la primera fila es `intent=primary`;
  en compact la ruta declara `meta.fab = { etiqueta: "Medir", icono:
  "i-medir" }` y la página fija `useFab` a la primera tina; sin tinas por
  medir la acción queda nula (FAB deshabilitado, como Fermentación). Los
  demás «Medir» son secundarios.
- **Destilación**: corridas `status = abierta` (folio · alambique · pasada ·
  L cargados / L cortados · **Cortar** → `/destilacion/:corrida/corte` ·
  «Ver corrida» quiet) y colectores con saldo (colector · clase · litros ·
  % Alc. · «Pasar a granel» → `/granel/transferir?origen=<resource_id>` solo
  mezcal y admin/productor con señal; si no, «Ver» → Destilación). Vacío:
  «Sin corridas abiertas ni colectores con líquido» + «Abrir corrida»
  (admin/productor con señal).
- **Por enviar**: solo si `cola.elementos.length > 0`; fila = `resumen` ·
  hora local de `occurred_at` · chip `pending` («pendiente · espera señal»)
  o `failed` + motivo (`error`) · **Reintentar** (`cola.reintentar(id)`) ·
  **Corregir** si `requiereNota` (medición → `/fermentacion/<p_ciclo>/medir?
  corregir=<id>`; corte → `/destilacion/<p_corrida>/corte?corregir=<id>`) o
  **Descartar** (`cola.descartar(id)`).
- **Nada pendiente**: state-block «Hoy no hay nada pendiente» con atajos
  Fermentación · Destilación · Granel.
- **Permisos**: Medir y Cortar con `!modoLectura` (operador incluido);
  Abrir corrida / Llenar tinas / Pasar a granel con admin|productor y
  `enLinea`; solo lectura: ningún atajo de captura.
- **Sin señal**: `cargarHoy` compone `cargarUsos` + `cargarDestilacion` (cada
  una con su instantánea); `instantanea` = la más antigua de las dos; Medir
  y Cortar no dependen de `enLinea`.
- **Adaptación**: ≥1024 dos columnas (Toca medir 3fr | Destilación + Por
  enviar 2fr); <1024 una columna; <600 filas apiladas con el botón a todo
  el ancho. Foco: el título de la página lo maneja el shell.

## Orden de construcción

1. `modules/inicio/api.ts`: `cargarHoy(org)` y puras con Vitest
   (`resumenHoy`, `rotuloHora`, `recortar`, `instantaneaMasAntigua`).
2. `InicioEmpresaPage.vue` + filas locales; `router.ts` con `meta.fab` en
   `inicio`; `useFab`.
3. Vitest de página (mock de `cargarHoy` y de la cola): default, todo
   medido, operador, solo lectura, fallo con Corregir/Reintentar, sin lotes.
4. Playwright `qa/evidencia-inicio-hoy.mjs` (Aurelia, Cuatro Vientos): Hoy
   con la semilla (Tina 2 y Tina 3 por medir; Tina 1 en vaciado), Medir
   desde Hoy → medición real por la cola → Tina 2 sale de «Toca medir»;
   Tomás (operador) sin «Pasar a granel» ni «Abrir corrida»; sin señal con
   instantánea; 4 anchos × 2 temas. `db reset` al cerrar.
5. Declaración → lima (compuerta Candidate) → mora (`Screens/inicio.md`).
