# Iconos

| Campo | Valor |
|---|---|
| Fuente propietaria | `apps/web/src/shared/ui/iconos.svg` (sprite, un solo set de trazo, viewBox 24) |
| Componente | `Icono.vue` — `nombre: IconoNombre`, `size?: number`, `titulo?: string` (sin título es decorativo, `aria-hidden`) |
| Inyección | `App.vue` inserta el sprite una vez; cada uso es `<use href="#id">` |

## Símbolos que existen (12)

| id | Concepto |
|---|---|
| `i-maguey` · `i-horno` · `i-molienda` · `i-tina` · `i-destila` · `i-lote` | etapas del proceso |
| `i-home` | inicio |
| `i-medir` | medición |
| `i-mas` | agregar (**"+"**; redibujado en la ronda acceso/r01: antes eran tres líneas) |
| `i-bell` · `i-clock` | aviso · tiempo |
| `pulz-mark` | marca PULZ (viewBox 96) |

## Lo que NO existe — y cómo se resolvió

No hay ojo (mostrar contraseña), «⋯», copiar ni compartir. Por la regla de un
solo set (sin emojis, sin otro set), esos controles llevan **texto**:
«Mostrar / Ocultar», «Acciones», «Copiar enlace», «Compartir…»
(`docs/DECISIONES.md`, 2026-09-27). Agregar iconos al sprite es una decisión
del dueño, no de una pieza.
