# Chip de estado · `status-chip`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.3.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` · extendido en `lab/fermentacion/r01` |
| Código | `apps/web/src/shared/ui/ChipEstado.vue` |
| Demo real | `Components/demo/index.html#status-chip` |
| Pruebas | `ui.test.ts` (1 caso: texto + variante de forma) · `fermentacion-ui.test.ts` (pending/failed) |
| Evidencia | `qa/evidence/acceso-r01/equipo-*` |

## Para qué

Estado en una palabra con **punto de forma + texto**; el color semántico
solo refuerza. Regla de campo bajo el sol: nunca color solo.

## Uso

Usos aprobados: estado de miembro — `on` = activo, `draft` = invitado, `off`
= suspendido; `partial` = fermentando (estado parcial); `on` = tina lista;
`draft` = en vaciado. Cola offline (fermentacion/r01): `pending` = captura
pendiente de enviar, `failed` = la captura falló (es futuro pendiente, no
pasado: no se tacha).

## Anatomía

`span.chip` con `::before` (punto 8 px) + texto del slot; borde 1 px, pill.

## Variantes

| variante | punto | texto | color de refuerzo |
|---|---|---|---|
| `on` | relleno | `--ok` | `--ok` sobre `--ok-bg` (4.5 / 6.6) |
| `draft` | contorno **discontinuo** | `--text` | borde y punto `--pend` sobre `--pend-bg` |
| `off` | contorno, texto **tachado** | `--muted` | `--surface` |
| `partial` | medio relleno | `--info` | `--info` sobre `--info-bg` (4.5 / 6.1) |
| `pending` | contorno **discontinuo** | `--text` | borde y punto `--pend` sobre `--pend-bg` |
| `failed` | relleno, borde **doble** 3 px | `--late` | `--late` sobre `--surface` |

`draft` lleva el texto en `--text` porque `--pend` sobre `--pend-bg` da 3.0:1
en claro (compuerta de lima; token pendiente en `docs/DUDAS.md` #12).

## Accesibilidad

Significado en el texto; forma distinta por variante; sin interacción.

## API real

```ts
props: { variante?: "on" | "draft" | "off" | "partial" | "pending" | "failed" }   // on
slots: default (el texto del estado)
```

## Implementación

Tokens: `--ok/--ok-bg`, `--pend/--pend-bg`, `--info/--info-bg`, `--muted`,
`--text`, `--surface`, `--r-pill`, `--sp-2`, `--font`. Dependencias: ninguna.

## QA y ciclo de vida

Capturas revisadas en 4 anchos × 2 temas; contraste medido. **Pendiente para
Stable:** forced-colors (el punto depende de `border`/`background`).
