# Declaración documental · PULZ Design Hub · ronda acceso/r01

| Campo | Valor |
|---|---|
| Superficie | 14 piezas `candidate` 0.2.0 (10 sistema + 4 pantallas) + Foundations (Tokens, Iconos) + inicio del Hub |
| Modo | **M2 Página** (contenido nuevo) + **M3 Sincronización** (perfil `mora:`) — sin shell HTML: ver desviación 1 |
| Ronda de kiwi de referencia | `design-hub/lab/acceso/r01/` (propósito y estructura; no como evidencia de implementación) |
| Estado en registry | `candidate` 0.2.0 las 14 (lima, 2026-09-27); ninguna `stable` |
| Evidencia de coco | `coco-declaracion.md` + `lima-compuerta.md` + `qa/evidence/acceso-r01/` (104 capturas) |
| Artefactos | `design-hub/README.md` · `Foundations/{Tokens,Icons}.md` · `Components/{button,text-field,password-field,segmented-choice,status-chip,row-menu}.md` · `Patterns/{banner,state-block,task-layer,list-stack}.md` · `Screens/{acceso-portal,acceso-cambio-contrasena,acceso-bienvenida,equipo}.md` · `lab/hub/encargo-mora.md` · bloque `mora:` del perfil |
| Modifica producción | No (ni CSS, ni API, ni comportamiento) |

## Estándares y fuentes leídos

- `mora-docs/SKILL.md`, `documentation-round-standard.md`, plantillas de encargo y declaración, `examples/mora-block.example.md`.
- Perfil `.claude/skills/lima/profiles/pulz.md` (`hub_root`, `hub_layout`, `registry_path`, `production.*`, `a11y_target`, `coco.data_contract`).
- `design-hub/system/registry.json` (kind, status, versión, contrato, dependencias, QA por faceta, hallazgos de compuerta).
- Código: `apps/web/src/shared/ui/*.vue` (props/emits/slots reales), `modules/acceso/*`, `modules/equipo/*`, `app/router.ts`, `tokens.css`, `iconos.svg`.
- `coco-declaracion.md`, `lima-compuerta.md`, `docs/DUDAS.md` #9 #11 #12.

## Desviaciones

1. **No hay shell HTML del Hub** (`mora.doc_shell` vacío; `Foundations/Patterns/Responsive` estaban vacías). Crear uno sería una estructura nueva → es de kiwi (§6 del protocolo). Se escribió el **encargo documental** (`lab/hub/encargo-mora.md`) y las fichas se publican en **Markdown** como contenido verificado que ese shell mostrará. No se improvisó un shell paralelo ni se copió CSS.
2. **Taxonomía**: las pantallas van en `design-hub/Screens/` (no está en `hub_layout`). Reversible; lima confirma o renombra.
3. **`Responsive/{Mobile,Tablet,Desktop}`** del perfil queda vacío: el rango vive en cada ficha. Decisión para kiwi/lima (encargo, incógnita 2).

## Criterios de éxito

| # | Criterio | Resultado | Evidencia |
|---|---|---|---|
| 1 | Toda ficha refleja estado y versión del registry | Cumple | header de cada ficha = `registry.json` (candidate 0.2.0, owner lima) |
| 2 | API documentada = código público real | Cumple | props/emits/slots extraídos de `defineProps/defineEmits/<slot>` de cada `.vue` |
| 3 | Preview = componente real, sin CSS copiado | Cumple | `Components/demo/index.html#<id>` construido desde el código; anchors verificados en navegador (9/9 resuelven y desplazan) |
| 4 | Nada no implementado se documenta como hecho | Cumple | #11 sesión automática, #9 bloqueo por intentos, #12 ámbar como texto, paginación por 50, «Entendido»: marcados como no hechos o corregidos al contrastar con el código |
| 5 | Enlaces internos resuelven | Cumple | 17 páginas, 0 enlaces rotos (script) |
| 6 | Navegación global única en HTML | No aplica todavía | pendiente del encargo a kiwi |

## Comprobaciones ejecutadas

- Enlaces relativos de las 17 páginas Markdown → 0 rotos.
- `registry.json` válido (JSON) tras la lectura; no se editó.
- Anchors `#button … #list-stack` existen en la demo servida en `http://localhost:4321` (pane del navegador, `getElementById` 9/9; `#task-layer` desplaza a 2614 px).
- Contraste de la ficha Tokens = tabla medida por lima (`lima-compuerta.md`), no recalculada.
- Contraste de claims contra el código: esqueleto de carga (`equipo__esqueleto`), botones «Cerrar» y «Guardar rol», búsqueda local existente, error de formato de usuario — corregidos en `Screens/equipo.md` y `Patterns/list-stack.md` antes de publicar.

## Comprobaciones no ejecutadas

- Render HTML del Hub (no existe shell): sin check de `aria-current`, IDs duplicados ni drawer.
- Censo de cobertura automático: `coverage_script` vacío; el registry es el censo (14/14 con ficha).
- Lectura de las fichas en el shell final: depende de la ronda `lab/hub/r01`.

## Matriz de estados

No aplica a la documentación en sí; cada ficha de pantalla trae su tabla de estados (disparador · qué se ve) derivada del código.

## Hallazgos

| Severidad | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Media | Contrato de `row-menu` en el registry dice «botón ‹⋯ Acciones›»; el código lleva solo «Acciones» (sprite sin ⋯, decisión 2026-09-27) | REVISAR (campo de lima) | lima | alinear el texto del contrato |
| Media | `registry.documentation` apunta a la demo, no a la ficha (`Components/<id>.md`) | REVISAR (campo de lima) | lima | decidir si `documentation` = ficha y añadir `demo` aparte |
| Baja | `hub_layout` no contempla pantallas; mora creó `Screens/` | REVISAR | lima | confirmar taxonomía |
| Baja | `list-stack`: paginación por 50 del contrato no implementada | REPORTAR | coco (cuando haya listas grandes) | documentado como no hecho |
| Info | Sin shell HTML del Hub | DERIVAR | kiwi (`lab/hub/encargo-mora.md`) | ronda F0–F2 del Hub |

## Próximo paso

kiwi ejecuta la ronda `design-hub/lab/hub/r01/` con el encargo; mora la valida contra `documentation-round-standard.md` y publica estas fichas sobre el shell aprobado. Mientras, `design-hub/README.md` es el inicio del Hub.
