# coco · Declaración de cumplimiento — ronda shell/r01 (F3 + R3)

> Entrada: `brief.md`, `index.html` (F2), `declaracion.md`, `hallazgos.md`
> (kiwi) y `orden-coco.md` (lima). Decisiones autónomas en `docs/DECISIONES.md`.

```text
Ruta: R3 (implementación de la estructura aprobada) + F3 (demos de las 4 piezas en el Hub) + R0 propio
Brief funcional: el de kiwi, vigente. data_contract: Destino y Cuenta registrados (app/destinos.ts, CapaCuenta); sin campos nuevos en la base; Inicio.sinLotes por conteo bajo RLS
Reglas aplicadas:
  · una lista de destinos, dos presentaciones (barra 4+Más en compact; lateral 200/240); Configuración solo admin, nunca deshabilitada; por URL → state-block denied
  · color de empresa solo como línea de acento de 4px; acción = --ink-900; destino actual por borde/sombra + negrita, nunca solo color
  · targets: barra 48px, lateral 44px, FAB 56px, botón de empresa 44px; foco visible 3px; capas con role=dialog (task-layer), foco atrapado y devuelto
  · tema por data-theme + prefers-color-scheme, guardado en localStorage y aplicado antes de montar (sin parpadeo); reduced-motion heredado (sin transiciones)
  · teclado virtual: barra oculta con foco en campo o visualViewport < 75 %
  · sin datos inventados en Inicio (tarjetas Fase 5); "¿Qué tienes hoy?" solo sin lotes; destinos vacíos con "próximamente" honesto
  · 4 símbolos nuevos con el mismo trazo (i-tanque, i-traza, i-ajustes, i-menu); un solo set
Excepciones:
  · Cuenta como drawer de task-layer, no popover (excepción de lima, aceptada)
  · En medium el menú lateral no repite la empresa (la cabecera la muestra): contrato de side-nav ajustado (empresa opcional)
  · "Empezar" (sin lotes) lleva a Granel hasta que exista arranque/r01
  · Layout por meta.shell en App.vue, no rutas anidadas (el portal comparte el prefijo /e/:slug)
Comprobado:
  · vue-tsc ✔ · eslint 0/0 ✔ · prettier ✔ · vite build ✔ · build:hub ✔ (4 secciones nuevas, router en memoria)
  · Vitest 40/40 ✔ (7 nuevos: bottom-nav, side-nav, page-header, fab, tema ×2 + los 33 previos)
  · Playwright qa/evidencia-shell.mjs 8/8 corridas ✔ (1440/1024/768/390 × claro/oscuro; admin y productora): una sola nav principal; 8 enlaces (admin) / 7 (productora) en lateral, 4 en barra; targets ≥44; Más → Configuración; Fermentación "próximamente"; Cuenta con tema (aplica y guarda); Equipo dentro del shell; sin Configuración para la productora y "sin permiso" por URL; sin scroll horizontal; 0 errores JS; 50 capturas en qa/evidence/shell-r01/
  · Playwright qa/evidencia-acceso.mjs 8/8 ✔ re-ejecutada con el shell (Equipo y Cerrar sesión ahora en la Cuenta): 104 capturas
  · zoom 200 % aproximado (qa/zoom-acceso.mjs) 10/10 ✔ con inicio y equipo dentro del shell
  · Hub: 4 símbolos nuevos y 13 secciones presentes (pane del navegador)
Auditoría arquitectónica (manual):
  · shared/ui nuevos = UI primitives sin dominio (ItemNav genérico; el filtro por rol lo hace app/destinos.ts). Health: sano.
  · app/AppShell = composición: conoce el store de acceso y los destinos; CapaMas/CapaCuenta locales del shell (no registry). Health: sano.
  · Findings:
    - MEDIUM · fixed · high — carrera popstate (task-layer history.back) vs router.push desde una capa: irA espera el popstate. Regla para cualquier capa futura que navegue.
    - MEDIUM · fixed · high — empresa repetida en medium (cabecera + lateral): side-nav.empresa opcional.
    - LOW · fixed · high — "Fermentación" se partía en la barra de 390 (borde 2px restaba ancho): borde por sombra interior, sin padding lateral, letter-spacing −0.01em.
    - LOW · NO_ACTION — fab sin uso real hasta Fase 5 (hueco publicado en meta.fab).
Cobertura de doc: 6 fichas nuevas (app-shell, page-header, side-nav, bottom-nav, fab, inicio) + README e Icons.md del Hub actualizados; registry con las 6 piezas (lima).
No pudo comprobarse:
  · teclado virtual en iOS/Android reales (visualViewport emulado no reproduce el teclado)
  · lector de pantalla sobre barra inferior y capas
  · cambio de empresa con dos membresías reales (la semilla tiene una por persona)
  · "¿Qué tienes hoy?" con una empresa sin lotes (Cuatro Vientos ya tiene): llega con la prueba de punta a punta de la Fase 4
  · zoom nativo 200 %, forced-colors, harden/audit (compuerta Stable)
Siguiente paso: lima evalúa la compuerta Candidate; mora ya tiene las fichas listas para publicar el estado.
```
