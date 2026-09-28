# Aviso · `banner`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.3.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` · extendido en `lab/fermentacion/r01` |
| Código | `apps/web/src/shared/ui/Aviso.vue` |
| Demo real | `Components/demo/index.html#banner` |
| Pruebas | `ui.test.ts` (1 caso: `role=status` con título) · `fermentacion-ui.test.ts` (variante cola con acción) |
| Evidencia | `qa/evidence/fase5-offline/1-sin-conexion.png`, `3-tres-pendientes.png` (offline y cola reales); solo lectura solo en el Hub |

## Para qué

Franja persistente arriba del contenido mientras dure una condición que
cambia lo que la persona puede hacer: **sin conexión** o **solo lectura**
(suscripción vencida). No se cierra; desaparece cuando la condición termina.

## Uso

- Un solo aviso a la vez: **sin conexión > cola > solo lectura**. Sin
  conexión y con capturas en cola, el aviso de conexión ya dice cuántas
  esperan.
- Variante `cola` (fermentacion/r01): «N capturas pendientes de enviar · M
  fallaron.» con la acción «Reintentar» en el slot `accion` — la única
  excepción a «sin botón», porque la persona puede hacer algo.
- Lo usan las pantallas de acceso (`PantallaAcceso`), Inicio y Equipo.
- No es para errores de una acción (eso es `state-block` o el error bajo el
  campo).

## Anatomía

`p[role=status]` → `strong` título («Sin conexión.» / «Solo lectura.») +
`span` con la frase del slot.

## Variantes

| variante | fondo | texto | mensaje típico |
|---|---|---|---|
| `offline` | `--pend-bg` | `--text` (13.6 / —) | «Para entrar necesitas señal.» |
| `readonly` | `--info-bg` | `--text` | «La suscripción venció: puedes consultar y exportar, no registrar.» |

## Accesibilidad

`role=status` (se anuncia sin interrumpir); significado en el título, no en
el color; contraste del texto ≥ 13:1 sobre ambos fondos.

## API real

```ts
props: { variante: "offline" | "readonly"; titulo: string }
slots: default (la frase)
```

## Implementación

Tokens: `--pend-bg`, `--info-bg`, `--text`, `--border`, `--sp-*`, `--font`.
Dependencias: ninguna.

## QA y ciclo de vida

Capturas en el Hub (4 anchos × 2 temas); prueba de componente. **No
verificado con datos reales** (queda para Stable: empresa vencida en la
semilla o simulación offline en Playwright).
