# Principios HIG aplicados a web/PWA

Se toma el **criterio**, no la apariencia de Apple.

## Tomar

- **Claridad**: texto legible, iconos con nombre, propósito evidente.
- **Deferencia al contenido**: el cromo no compite con el contenido; la UI se retira cuando no aporta.
- **Profundidad/capas**: overlays, hojas y drawers comunican jerarquía y cómo volver.
- **Feedback**: cada acción tiene respuesta visible en < 100 ms (estado de presionado, progreso, resultado).
- **Consistencia**: un concepto, un control, un nombre.

## No copiar

- Barras de navegación/tab bars con apariencia iOS en web.
- Controles que imitan los del sistema (switches, pickers) si el navegador ya da uno nativo.
- Terminología de Apple ("Sheet", "Popover" como nombres de producto).

## PWA

- Instalación ofrecida después de obtener valor, nunca al primer arranque ni en medio de una tarea.
- Estado offline explícito y persistente mientras dure; distinguir cache de dato vivo.
- Área segura (`env(safe-area-inset-*)`) y teclado virtual considerados en acciones inferiores persistentes.
- Navegación por historial del navegador respetada (atrás cierra overlays antes de salir de la vista).

## Checklist (Fase 5)

- [ ] ¿Cada icono tiene nombre accesible?
- [ ] ¿Algún overlay se puede cerrar con atrás/Esc?
- [ ] ¿Hay feedback en todas las acciones?
- [ ] ¿El prompt de instalación respeta el momento?
- [ ] ¿Offline es explícito?
