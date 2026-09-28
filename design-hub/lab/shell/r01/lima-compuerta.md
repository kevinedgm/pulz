# lima · Compuerta Candidate — ronda shell/r01

Evaluada el 2026-09-27 con `coco-declaracion.md`, las 50 capturas de
`qa/evidence/shell-r01/`, la re-ejecución de `evidencia-acceso.mjs` (104) y
el zoom 200 % aproximado. Resultado: **las 6 piezas pasan a `candidate`
0.2.0** (app-shell, page-header, side-nav, bottom-nav, fab, inicio).

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía | contratos del registry + código | ✔ 6/6 |
| Variantes justificadas | side-nav 2 anchos; bottom-nav sin variantes; page-header con/sin empresa; fab 1 | ✔ |
| Estados | shell: 10 (carga, error, denied, offline, readonly, long, multi, teclado, zoom); capturas de 7 pantallas/estados × 8 | ✔ (multi-empresa y teclado real: no verificados, ver abajo) |
| Responsive (transformación) | barra 4+Más / lateral 200 / lateral 240 + cuenta al pie; capturas 4 anchos | ✔ |
| A11y base | una nav principal; aria-current; targets ≥44 medidos por Playwright; Esc en capas; foco; contraste heredado; zoom 10/10 | ✔ |
| Demo en el Hub | 4 piezas en `Components/demo`; app-shell e inicio = pantallas reales + capturas | ✔ |
| critique→polish | manual-playbook / degraded (sin impeccable ejecutable) | registrado |

Hallazgos devueltos a coco y corregidos: carrera popstate (capa → navegación),
empresa repetida en medium, etiqueta partida en la barra de 390. Excepciones
aceptadas: Cuenta como drawer (`task-layer`), layout por `meta.shell`.

Revisiones de mora resueltas en el registry: `documentation` apunta a la
ficha Markdown y `demo` a la demo; texto del contrato de `row-menu`
("Acciones", sin ⋯); taxonomía `Screens/` confirmada (queda como
convención; `hub_layout` del perfil se actualiza en la ronda del Hub).

No verificado (Stable): teclado virtual real, lector de pantalla, cambio de
empresa con dos membresías, "sin lotes" real, zoom nativo, forced-colors,
harden/audit.

Entrega a mora: fichas ya escritas por adelantado (`Patterns/app-shell.md`,
`Components/{page-header,side-nav,bottom-nav,fab}.md`, `Screens/inicio.md`);
mora confirma que reflejan el registry (candidate 0.2.0) y publica.
