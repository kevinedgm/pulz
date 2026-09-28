# Tokens

## Fuentes

| Responsabilidad | Archivo |
|---|---|
| Aprobación | [`.fruti/foundations/approval.yaml`](../../.fruti/foundations/approval.yaml) |
| Verdad canónica legible por máquinas | [`.fruti/tokens.json`](../../.fruti/tokens.json) |
| Binding generado para producción | [`apps/web/src/shared/ui/tokens.css`](../../apps/web/src/shared/ui/tokens.css) |
| Perfil activo | [`.codex/skills/lima/profiles/pulz.md`](../../.codex/skills/lima/profiles/pulz.md) |

## Cobertura

El archivo canónico contiene color base, escalas tonales, aliases semánticos, familias/escala tipográfica, espaciado, sizing, radios, iconografía, movimiento, adaptación y reglas de accesibilidad.

## Contrato de producción

Producción consume las custom properties canónicas del CSS generado. Los nombres históricos (`--ink-900`, `--late`, `--sp-*`, `--r-*`, etc.) son aliases temporales para compatibilidad; no son una segunda fuente de verdad. Los valores base solo cambian mediante una nueva aprobación de foundations.

## Base aprobada

`primary #6D4AFF` · `secondary #FF876F` · `surface #F8F8FA` · `ink #18171F` · `danger #C94D5D` · `success #187A5B` · `warning #9A6715` · Manrope · Instrument Serif · Lucide · espacio 4 px · radios 10/16 px · control 48 px · touch 44 px · movimiento 140/220/320 ms · WCAG 2.2 AA.
