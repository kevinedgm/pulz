# lima · Compuerta Candidate — ronda hub/r01 (`hub-shell`)

Evaluada el 2026-09-27 con `coco-declaracion.md`, `mora-declaracion.md`
(validación contra el estándar documental de mora), 36 capturas de
`qa/evidence/hub-r01/` (8/8 corridas) y el check de enlaces (33 páginas, 0
rotos). **`hub-shell` (template) pasa a `candidate` 0.2.0.** Decisión
automática per `CLAUDE.md` §4: es una pieza de tooling interno, sin regla de
negocio del maestro.

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía | sidebar 260 / barra + drawer, breadcrumb, header desde registry, TOC por h2, preview (iframe o galería), facetas, 404 | ✔ |
| Estados | default, drawer abierto, deprecated (rama del build; sin caso real), sección vacía, 404, demo no disponible (enlace directo) | ✔ (deprecated y sección vacía: probados en el wireframe, no en el sitio: no hay caso) |
| Responsive | 1440/1024/768/390 × claro/oscuro sin desborde; tablas con scroll propio | ✔ |
| A11y base | nav con nombre, aria-current, drawer dialog con foco/Esc, targets 44/36(declarado)/24, foco 3 px, reduced-motion | ✔ |
| Demo | el sitio mismo (`design-hub/site/`), generado y versionado | ✔ |
| critique→polish | manual-playbook / degraded | registrado |

Contrato: sin cambios respecto al `draft`. Se añade la regla de operación:
**cada cambio de ficha o de registry se acompaña de `pnpm build:hub-site` y
del `site/` regenerado en el mismo commit.**

No verificado (Stable): lector de pantalla, zoom nativo, harden/audit, un
caso real de pieza deprecated.

Entrega a mora: ya publicado (mora validó y publicó en la misma ronda; el
registry queda sincronizado con esta compuerta antes de que el build vuelva
a correr, para que el header del sitio muestre `candidate`).
