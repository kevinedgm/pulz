# Iconos

## Fuente canónica

**Lucide** es la única biblioteca aprobada.

| Token | Valor |
|---|---:|
| Tamaño pequeño | 16 px |
| Tamaño medio | 20 px |
| Tamaño grande | 24 px |
| ViewBox | 24 |
| Stroke | 2 |

## Reglas

Iconografía de trazo consistente, simple y contemporánea. Los iconos refuerzan navegación, acciones y estados, no se usan como decoración. Las acciones ambiguas combinan icono y texto. Ningún estado depende exclusivamente de icono o color. Un icono sin significado propio es decorativo y se oculta a tecnologías de asistencia; uno informativo recibe nombre accesible.

`apps/web/src/shared/ui/Icono.vue` entrega los 15 nombres semánticos mediante imports explícitos de `@lucide/vue@1.48.0`. Mantiene `nombre`, `size` y `titulo`; con título expone nombre accesible y sin título es decorativo. La app y la demo ya no inyectan el sprite global.

El sprite histórico `apps/web/src/shared/ui/iconos.svg` se conserva como evidencia, no como segunda biblioteca canónica. `pulz-mark` conserva la geometría de marca original (viewBox 96); es un logotipo, no un icono Lucide. Cinco usos heredados de iconos a 22 px se alinearon a 24 px; no se alteraron sus targets ni los valores base de las Foundations.

[Verificación acotada de entrega](../lab/foundations-binding/r01/result.md): 17 pruebas de Icono, build app/demo y comprobación de SVG reales en navegador. No implica promoción de lifecycle ni QA visual completa de todas las pantallas.
