# lima · Compuerta Candidate — ronda acceso/r01

Evaluada el 2026-09-27 con la evidencia de coco (`coco-declaracion.md`) y dos
comprobaciones propias de lima. El dueño autorizó aplicar las transiciones
("sí, continúa"). Resultado: **las 14 piezas pasan a `candidate` 0.2.0**;
ninguna vuelve a kiwi. Cuatro hallazgos se devolvieron a coco y ya están
corregidos (misma sesión, commit aparte); un hallazgo de token queda como
decisión del dueño.

## Criterios (quality-gates.md) × evidencia

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía definida | contrato en el registry + código en `apps/web/src/shared/ui/` y módulos | ✔ 14/14 |
| Variantes justificadas | button: 4 intents × 2 adapt, todas usadas en las pantallas; chip: 4 (activo/invitado/suspendido/parcial); banner: 2; state-block: 3. Ninguna sin uso | ✔ |
| Todos los estados | coco: carga, vacío, error+reintento, sin permiso, sin conexión, solo lectura, texto largo, 0/null; Playwright cubre 13 pantallas/estados | ✔ (sin conexión y solo lectura solo en Hub + pruebas de componente; ver "no verificado") |
| Contrato responsive (transformación, no escala) | primaria persistente <600; lista apilada ≤1023; drawer→hoja; menú→hoja. Capturas en 1440/1024/768/390 | ✔ |
| A11y base — teclado y foco | Vitest (Esc, flechas, foco devuelto, trap) + Playwright/pane (Esc en menú y capa, submit) | ✔ |
| A11y base — contraste (perfil: alto, sol) | **medido por lima** sobre los pares de tokens usados, claro y oscuro (tabla abajo) | ✔ con 2 hallazgos corregidos + 1 token a decidir |
| A11y base — targets | `--tap` 44px en todo control; lg 52px en acceso; touch emulado en 390 | ✔ (emulado) |
| A11y base — zoom | **medido por lima** al 200 % (root font-size) en 1440 y 390 | ✔ tras 3 correcciones (abajo) |
| A11y base — texto largo | nombre de marca con ellipsis; notas de fila envuelven; no probado con datos largos reales | ✔ revisión estática |
| Demo interactiva en el Hub | 10 piezas del sistema en `design-hub/Components/demo/` (build desde el código); las 4 product-application: wireframe F2 de kiwi + pantallas reales + capturas | ✔ / ✔ con esa lectura |
| critique → distill → adapt → polish | sin impeccable ejecutable (sin sub-agentes ni detector): critique **degraded** single-context; distill/adapt/polish **manual-playbook** sobre el código y las capturas | ✔ registrado como tal, no como ✓ pleno |

## Contraste medido (WCAG 2.x, sobre `tokens.css`)

| Par | Uso | Claro | Oscuro |
|---|---|---|---|
| text / surface | texto | 15.5 | 14.6 |
| muted / surface | ayudas, rótulos 13px | 4.9 | 6.7 |
| surface / ink-900 | texto de la primaria | 10.0 | 6.5 |
| ink-900 / surface | quiet, enlaces | 10.0 | 6.5 |
| ok / ok-bg | chip activo | 4.5 | 6.6 |
| **pend / pend-bg** | chip invitado, aviso offline | **3.0 ✘** | 7.3 |
| late / late-bg | chip suspendido, rechazo | 4.7 | 6.1 |
| info / info-bg | aviso solo lectura | 4.5 | 6.1 |
| **border / surface** | límite de campo (3:1 no-texto) | **1.3 ✘** | 1.3 ✘ |
| muted / surface | límite de campo tras la corrección | 4.9 | 6.7 |
| ink-900 / canvas | anillo de foco | 9.3 | 7.2 |

## Zoom 200 % (aprox., `design-hub/qa/zoom-acceso.mjs`)

Antes: portal y Hub desbordaban a 390 (533/390) por el ancho intrínseco del
`<input>` (size=20 × fuente doble) que fijaba el min-content de su columna, y
las opciones de una palabra del segmento se recortaban. Después: 10/10
comprobaciones sin desborde ni recorte (1440 y 390; portal, inicio, equipo,
alta, Hub).

## Hallazgos devueltos a coco (visual/código) — aplicados

1. text-field / password-field / acceso-portal: columna `minmax(0, 1fr)` y
   base flex 0 para que el input no ensanche la tarjeta al 200 %.
2. segmented-choice: las opciones bajan de fila cuando una etiqueta no cabe
   (antes se recortaban a 390 con texto doble).
3. text-field / password-field / segmented-choice: borde del control en
   `--muted` (4.9:1) en vez de `--border` (1.3:1): bajo el sol el límite del
   campo tiene que verse.
4. status-chip "invitado": texto en `--text`; el ámbar queda en borde y punto.

## Hallazgo de token — decisión del dueño

`--pend #C17A18` sobre `--pend-bg` = 3.03:1 en claro (texto pide 4.5). Las
piezas ya no pintan texto con él; si el dueño quiere ámbar como texto, el
valor propuesto es `#8F5A10` (5.05:1). `docs/DUDAS.md` #12.

## Excepciones de coco — aceptadas

- "Solo admin" en Equipo como estado de página (kiwi lo tenía como estado;
  un guardia lo dejaría inalcanzable). Aceptada; el contrato de `equipo` en
  el registry lo refleja.
- Bienvenida sin sesión automática: no es defecto de la ronda, es del
  contrato de `set-password`. `docs/DUDAS.md` #11.

## No verificado (queda para la compuerta Stable)

- Zoom nativo 200 % del navegador (solo aproximación por font-size) →
  `manual-verified` requiere a una persona en un navegador real.
- Forced-colors / alto contraste del sistema.
- Alta real desde la pantalla (crea usuarios en el proyecto alojado).
- Sin conexión y solo lectura con datos reales (la semilla no tiene empresa
  vencida).
- Texto largo con datos reales (nombres de 60+ caracteres).
- `harden` y `audit`: **no se corrieron a propósito** (post-candidate).

## Nota sobre `production` en el registry

En PULZ, coco implementa directamente en el stack real (`CLAUDE.md` §3,
`PULZ_MAESTRO.md` §13.4): la demo del Hub se construye desde ese código. Por
eso `production.path` ya apunta a `apps/web/src/…` aunque la pieza sea
`candidate`; no es una promoción separada.

## Entrega a mora-docs

Documentar **solo** lo que el registry marca `candidate` y el código expone:

| Pieza | Fuente | Demo | Pruebas |
|---|---|---|---|
| button | `apps/web/src/shared/ui/Boton.vue` | `design-hub/Components/demo/#button` | `shared/ui/__tests__/ui.test.ts` |
| text-field | `CampoTexto.vue` | `#text-field` | ídem |
| password-field | `CampoContrasena.vue` | `#password-field` | ídem |
| segmented-choice | `SegmentoOpciones.vue` | `#segmented-choice` | ídem |
| status-chip | `ChipEstado.vue` | `#status-chip` | ídem |
| row-menu | `MenuFila.vue` | `#list-stack` (con la lista) | ídem |
| banner | `Aviso.vue` | `#banner` | ídem |
| state-block | `BloqueEstado.vue` | `#state-block` | ídem |
| task-layer | `CapaTarea.vue` | `#task-layer` | ídem |
| list-stack | `ListaApilada.vue` | `#list-stack` | — (capturas) |
| acceso-portal | `modules/acceso/pages/PortalPage.vue` + `NoEncontradoPage.vue`, `components/`, `store.ts`, `api.ts`, `app/router.ts` | `lab/acceso/r01/index.html` + `qa/evidence/acceso-r01/portal-*`, `no-encontrado-*` | `acceso/__tests__/*` |
| acceso-cambio-contrasena | `CambiarContrasenaPage.vue` | `cambiar-contrasena-*` | — |
| acceso-bienvenida | `BienvenidaPage.vue` | `bienvenida-*` | — |
| equipo | `modules/equipo/pages/EquipoPage.vue`, `api.ts`, `0023_equipo_miembros.sql` | `equipo-*` | `supabase/tests/equipo_miembros.test.sql` |

Tokens: `apps/web/src/shared/ui/tokens.css` (no cambiaron). Iconos:
`iconos.svg` (`i-mas` redibujado como "+"). Contratos: `registry.json`
campo `contract`. Lo que **no** debe documentarse como hecho: sesión
automática tras la bienvenida (#11), bloqueo por 5 intentos (#9), ámbar como
texto (#12).
