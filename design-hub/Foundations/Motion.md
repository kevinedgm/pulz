# Movimiento

| Token | Valor | Uso |
|---|---:|---|
| `motion-fast` | 140 ms | Feedback inmediato |
| `motion-standard` | 220 ms | Transición habitual |
| `motion-emphasis` | 320 ms | Cambio que requiere seguimiento visual |
| `motion-easing` | `cubic-bezier(.2,.8,.2,1)` | Curva canónica |

El movimiento comunica continuidad, jerarquía, cambio de estado o feedback. No se usa como decoración gratuita. Con `prefers-reduced-motion: reduce`, las duraciones generadas bajan a 1 ms y no se introduce movimiento espacial innecesario.
