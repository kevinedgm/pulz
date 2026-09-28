# Declaración de cumplimiento · SHELL · r01

| Campo | Valor |
|---|---|
| Ruta | R1 (una dirección estructural) |
| Fidelidad | F2 (contenido real, estados, responsive; sin sistema visual) |
| Pregunta de diseño | ¿Cualquier persona, con una mano y sol de frente, llega a la etapa que le toca en ≤2 toques y sabe siempre en qué empresa y con qué permisos está? |
| Artefactos | `brief.md` (brief + 3 user flows) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

- `references/wireframing.md`, `references/fidelidad.md`, `references/validacion.md`, `references/hig-web-pwa.md` (capas, retroceso, deferencia al contenido; sin barras ni terminología de iOS).
- WCAG 2.2 AA: 2.5.8 targets ≥ 44 px (barra inferior 48 px, menú lateral 44 px), 1.4.4 texto al 200 % (estado "zoom"), 2.4.7 foco visible, 1.4.1 no depender del color (destino actual por borde + negrita), 2.4.3 orden de foco en capas.
- Perfil PULZ: breakpoints 1440/1024/768/390; a11y "bajo el sol"; `hub_layout`; `coco.data_contract` (MiMembresia: name, brand_color, role, status, read_only, cancelled).
- `PULZ_MAESTRO.md` §8.3 (offline), §11.1 (roles), §13.1–§13.4, §16 Fase 4.

## Desviaciones del protocolo

- Ninguna. El kit va inline (copia idéntica en `vendor/`) para que el artefacto se abra suelto, como en acceso/r01.

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: **0 errores · 0 avisos** (solo grises, una familia, panel de estados, notas, 4 marcas de primaria — una por vista).
- Chromium (Playwright): **351 combinaciones** (3 espacios × 3 roles × 3 destinos × 13 estados) sin desborde horizontal del marco, **≤ 1 primaria visible** (botón primario o FAB) y **0 targets < 44 px** en la navegación; **0 errores JS**.
- Teclado/foco: capas (Más, Cuenta) con `role=dialog`; Esc/atrás/scrim cierran y el foco vuelve al disparador (declarado, no ejecutado en el wireframe).
- Estados representados: default · carga · vacío (¿Qué tienes hoy?) · error · sin permiso (Configuración por URL) · sin conexión · solo lectura · nombre largo · Más · Cuenta · varias empresas · teclado virtual · texto al 200 %.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Navegación principal | barra inferior: 4 fijos (Inicio · Fermentación · Destilación · Granel) + "Más" (hoja con Maguey · Horneado · Trazabilidad · Configuración*) | menú lateral 200 con los 8 destinos | menú lateral 240 con los 8 | 44 px por target → máx. 5 abajo; en tablet/escritorio caben todos | container query; una sola lista de destinos, dos presentaciones | la ruta se conserva al cambiar de tamaño; "Más" devuelve el foco al abrir/cerrar |
| Cabecera | empresa (botón → Cuenta) + título del destino | igual | **solo** título del destino (empresa y cuenta viven en el menú lateral) | no repetir la empresa dos veces | container query | el botón de empresa abre la cuenta |
| Cuenta (persona · empresas · tema · Equipo* · Cerrar sesión) | hoja inferior | popover anclado a la cabecera | popover desde el pie del menú lateral | tarea acotada sobre el contexto | `task-layer` existente | Esc/atrás cierra; foco vuelve |
| Empresa actual | nombre en una línea con elipsis + iniciales; completo en `title` y en Cuenta | igual | dos líneas en el menú lateral | nombres largos reales (razón social) | `text-overflow`, `line-clamp` | — |
| Acento de marca (`brand_color`) | línea superior de 4 px en la cabecera | igual | igual | color de empresa solo como acento, nunca detrás de texto (perfil) | token/variable por empresa | — |
| Banner (sin conexión / solo lectura) | bajo la cabecera, persistente | igual | igual | estado explícito mientras dure | `banner` existente | — |
| FAB (acción principal del destino) | flotante abajo a la derecha, 56 px, sobre la barra; oculto con capas abiertas, solo lectura y en Inicio/Configuración | no existe: la acción vive en la pantalla | igual | §13.1 "acción principal como botón flotante" solo en móvil | hueco por destino; cada ronda de etapa lo define | no compite con la primaria de la pantalla |
| ¿Qué tienes hoy? (Inicio sin lotes) | bloque con su primaria "Empezar" (no baja a barra: la barra es navegación) | igual | igual | primer arranque (§13.2 #2) | `state-block` + ronda arranque/r01 | — |
| Teclado virtual (compact) | la barra inferior se oculta mientras un campo tiene foco | n/a | n/a | no tapar el campo enfocado | `visualViewport` | el foco no se mueve |
| Texto al 200 % (compact) | etiquetas de la barra en dos líneas, nunca ocultas | menú lateral con scroll | igual | WCAG 1.4.4 | `rem`, `min-height`, sin `nowrap` | — |
| Movimiento reducido | capas sin deslizamiento | igual | igual | `prefers-reduced-motion` | CSS | — |

\* Configuración y Equipo solo con `role = admin`; no se muestran deshabilitados.

## Comprobaciones NO ejecutadas

- Teclado virtual real (iOS/Android): la técnica `visualViewport` se declara; no hay dispositivo físico. Playwright emula touch, no el teclado.
- Zoom nativo 200 % del navegador (solo `font-size: 200%` del marco en el estado "zoom").
- Lectores de pantalla (VoiceOver/TalkBack) sobre la barra inferior y las capas.
- Cambio de empresa real (`mis_membresias` con dos filas): la semilla solo tiene una empresa por persona; se representa con datos de ejemplo rotulados.

## Hallazgos

Ver `hallazgos.md` (2 altos: 4 fijos + "Más" como supuesto a confirmar; 4 símbolos que el sprite no tiene).

## Traspaso

- **→ lima:** piezas candidatas al **sistema**: `app-shell` (patrón: cabecera + banner + cuerpo + navegación + hueco de FAB, con los tres modos), `bottom-nav` (componente: 4 + Más, `aria-current`, 48 px), `side-nav` (componente: lista de destinos con icono/texto y bloque de cuenta al pie), `page-header` (componente: título del destino + botón de empresa), `fab` (componente: 56 px, oculto en capas/solo lectura), `theme-switch` (segmented-choice de 3, reutiliza `segmented-choice`). **Reutiliza:** `banner`, `state-block`, `task-layer` (Más y Cuenta), `button`, `status-chip` (solo lectura en la lista de empresas). **Local:** el bloque "Hoy" de Inicio (product-application `inicio`), el índice de Configuración (product-application `configuracion`, ronda aparte). Contrato de datos propuesto para `coco.data_contract`: `Destino = {id, titulo, icono?, soloAdmin, fijoEnCompact}`; `Cuenta = {persona: MiMembresia.username|'titular', rol, empresas: MiMembresia[] (sin cancelled), tema: 'sistema'|'claro'|'oscuro' (localStorage)}`; sin campos nuevos en la base.
- **→ coco (después de lima):** implementación en `apps/web/src/app/` (shell con `<router-view>` anidado), piezas en `shared/ui/`, tema por `data-theme` + `prefers-color-scheme` (tokens.css ya lo trae), `visualViewport` para el teclado, guardias: Configuración por URL sin admin → estado "sin permiso" (mismo patrón que Equipo).
- **→ dueño (en la aprobación):** (1) confirmar los 4 destinos fijos de compact; (2) decidir si se agregan al sprite `i-tanque`, `i-traza`, `i-ajustes`, `i-menu` o quedan con texto; (3) si "cambiar de empresa" basta en Cuenta (supuesto: sí).
- **→ mora:** nada hasta que coco implemente.

## Criterios observables para la aprobación

- Sin desborde en 1440/768/390 (351 combinaciones); una sola primaria por vista; targets ≥ 44 px; el destino actual se distingue sin color; Configuración no aparece a productor/operador; la misma tarea (ir a Fermentación) se completa en cada modo con 1 toque (compact: barra; medium/expanded: menú).

## Siguiente paso del usuario

**Aprobar la estructura** (o pedir `r02` con cambios) → lima → coco → mora. Nada se construye antes.
