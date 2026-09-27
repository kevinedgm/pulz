# Bloque de estado · `state-block`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/BloqueEstado.vue` |
| Demo real | `Components/demo/index.html#state-block` |
| Pruebas | `ui.test.ts` (1 caso: título, texto y acción del consumidor) |
| Evidencia | `qa/evidence/acceso-r01/bienvenida-invalido-*`, `equipo-sin-permiso-*`, `no-encontrado-*` |

## Para qué

Decir qué pasa cuando no hay contenido normal: **vacío** (con la siguiente
acción útil), **error** (con causa y Reintentar) o **sin permiso** (explica
quién puede; no inventa «solicitar acceso»).

## Uso

- Título = qué pasa; texto = causa o quién puede; a lo sumo **una** acción en
  el slot.
- Vacío de Equipo: «Solo estás tú» con la primaria dentro (la de cabecera
  baja a secundaria).
- Error de red en formularios: «No pudimos conectar — Revisa tu señal. Lo que
  escribiste se conserva.» + Reintentar.

## Anatomía

`div.bloque` centrado, máx. 520 px → `h2` título → `p` texto opcional →
`div.bloque__accion` con el slot.

## Variantes

| variante | semántica | borde |
|---|---|---|
| `empty` | `aria-live=polite` | `--border` |
| `error` | **`role=alert`** | `--late` |
| `denied` | `aria-live=polite` | `--border` |

## Responsive

Mismo bloque en todos los rangos; en compact ocupa el ancho de la tarjeta sin
estirarse verticalmente (la tarjeta usa `align-content: start`).

## Accesibilidad

Estado en texto; `error` se anuncia como alerta; la acción es un `button`
real del consumidor con 44 px.

## API real

```ts
props: { variante: "empty" | "error" | "denied"; titulo: string; texto?: string }
slots: default (la única acción, opcional)
```

## Implementación

Tokens: `--surface`, `--text`, `--muted`, `--border`, `--late`, `--sp-*`,
`--r-xl`, `--font`. Dependencias: `button`.

## QA y ciclo de vida

Capturas en 4 anchos × 2 temas (tres variantes en pantallas reales). **Pendiente
para Stable:** harden/audit.
