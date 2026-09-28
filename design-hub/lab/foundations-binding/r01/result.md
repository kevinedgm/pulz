# Entrega canónica de fuentes e iconos · 2026-09-28

**Corrección acotada implementada y verificada; no promoción de lifecycle.**
Contrato Kiwi F0/R0 → Lima autorizado → Coco → Lima verificación acotada →
Mora M3 (sincronización de Typography/Icons). No se deriva autorización para
Maguey/Horneado ni certificación de todas las pantallas.

## Implementación

- Dependencias exactas `@lucide/vue@1.48.0`, `@fontsource/manrope@5.3.0`,
  `@fontsource/instrument-serif@5.3.0`, lockfile actualizado.
- `shared/ui/fonts.css`, importado desde `src/main.ts` y `hub/main.ts`:
  Manrope 400/500/600/700 e Instrument Serif 400, assets locales.
- `Icono.vue`: 15 nombres existentes con Lucide; nombre accesible opcional,
  decorativos ocultos; marca PULZ intacta, sin sustituirla por Lucide.
- App y DemoHub dejan de inyectar sprite; archivo histórico conservado.
- Cinco usos de 22 px pasan a 24 px canónicos en NavInferior, NavLateral,
  BotonFlotante y CapaMas. No se cambiaron API, targets o navegación.
- Comentarios de tipos y exports alineados con implementación.

## Verificación

Aplicación **145/145** (19 archivos), incluye **17 pruebas de Icono**.
Build app con vue-tsc/Vite/PWA y build demo PASS. En navegador: cinco SVG
Lucide de navegación con viewBox 24, stroke 2 y aria-hidden; Manrope 4 pesos
cargados. Fixture `font-smoke.html` consume la misma build y observa además
Instrument Serif 400. [Recursos y estilos observados](runtime-evidence.json).

| Dimensión | Resultado acotado |
| --- | --- |
| technical | PASS: tipos, tests, builds, imports locales y DOM real. |
| structural | N/A: no nueva estructura; contrato preserva nombres y props. |
| visual | PARTIAL: entrega comprobada; no reauditoría de composición global. |
| accessibility | PASS helper: decorativo/informativo probado; WCAG global pendiente. |
| design_system | PASS binding: familias, biblioteca y tamaños aprobados; bases sin cambiar. |
| documentation | Sincronización M3 de dos fichas; build/enlaces se registran en el informe de continuación. |

No se modificaron tokens base, aprobación de Foundations ni FilaUso.vue.
Instrument Serif se verifica en fixture técnico; no se impuso como fuente
operativa. El smoke enlaza un hash de build concreto: una build futura
requiere regenerar el fixture/evidencia, no reutilizar su aprobación.

Reversión: retirar solo los imports/dependencias y restaurar la implementación
previa del helper y consumidores listados, preservando cambios ajenos.
