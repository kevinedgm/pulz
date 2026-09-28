# Tipografía

Fuente canónica: [`.fruti/tokens.json`](../../.fruti/tokens.json).

## Familias

| Rol | Familia | Regla |
|---|---|---|
| Primaria | Manrope | Interfaz, operación, navegación, formularios y datos |
| Secundaria | Instrument Serif | Display/editorial, cifras protagonistas y momentos expresivos |

La familia secundaria nunca sustituye texto operativo ni reduce claridad. Los datos comparables usan `tabular-nums`.

## Escala

`xs 12` · `sm 14` · `md 16` · `lg 18` · `xl 22` · `2xl 28` · `3xl 36` · `4xl 48` px equivalentes en `rem`. Pesos: 400/500/600/700. Interlíneas: 1.15/1.25/1.5.

## Entrega de fuentes

La app y la demo del Hub empaquetan Manrope 400/500/600/700 e Instrument Serif 400 mediante `@fontsource/manrope@5.3.0` y `@fontsource/instrument-serif@5.3.0`. `apps/web/src/shared/ui/fonts.css` se importa desde ambas entradas; no depende de un CDN. Los fallbacks declarados siguen disponibles mientras carga la fuente.

La carga local de los cinco archivos WOFF2 y sus familias/pesos se comprobó en navegador el 2026-09-28. [Resultado y alcance de la verificación](../lab/foundations-binding/r01/result.md). Esto certifica entrega de assets, no conformidad tipográfica o accesibilidad de todas las pantallas. El fixture técnico enlaza el CSS de la build evaluada; tras otra build debe generarse evidencia nueva.
