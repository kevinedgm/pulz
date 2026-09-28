# Color

Fuente canónica: [`.fruti/tokens.json`](../../.fruti/tokens.json). Aprobación: [`.fruti/foundations/approval.yaml`](../../.fruti/foundations/approval.yaml).

## Roles base aprobados

| Rol | Valor | Uso |
|---|---|---|
| Primary | `#6D4AFF` | Acción primaria y selección activa |
| Secondary | `#FF876F` | Expresión y acento |
| Surface | `#F8F8FA` | Fondo y superficie base |
| Ink | `#18171F` | Contenido ordinario |
| Danger | `#C94D5D` | Error, peligro y acción destructiva |
| Success | `#187A5B` | Resultado correcto |
| Warning | `#9A6715` | Precaución y atención |

Los valores `500` de las escalas son aliases exactos de estos roles. Los tonos `50–900` son derivados por mezcla con `surface` o `ink`; no sustituyen al rol base.

## Ley

Primary gobierna acción/selección; secondary expresa sin asumir significado semántico. Danger, success y warning nunca se intercambian. El significado se comunica con texto y forma además de color. Para texto normal se usan aliases semánticos con contraste suficiente; el rojo base no se fuerza como texto cuando no alcanza 4.5:1.

## Tokens semánticos

`background`, `text`, `textMuted`, `border`, `focus`, `action`, `actionText`, `accent`, `accentText`, `dangerText`, `successText` y `warningText` están definidos en el archivo canónico.
