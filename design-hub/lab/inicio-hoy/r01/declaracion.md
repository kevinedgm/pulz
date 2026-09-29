# Declaración de cumplimiento · INICIO / HOY · r01

| Campo | Valor |
|---|---|
| Ruta | R1 |
| Fidelidad | F2 |
| Pregunta de diseño | ¿Alguien que abre la app a las 9 de la mañana con el teléfono en una mano sabe en 3 segundos qué le toca hoy y llega a medir en ≤2 toques? |
| Artefactos | `brief.md` (brief + flujo) · `index.html` (wireframe, kit inline; copia en `vendor/`) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

`wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md`; WCAG 2.2 AA (targets 2.5.8, foco, no solo color); `0002` (`organization_settings`), `0026` (vistas); `modules/fermentacion/api.ts` (`agrupar`, `tocaMedirHoy`, `diaDelCiclo`), `modules/destilacion/api.ts`, `shared/offline/{cola,useCola}.ts`, `app/AppShell.vue`; rondas shell/r01, fermentacion/r01, destilacion/r01.

## Desviaciones del protocolo

Ninguna. Aprobación en automático (`CLAUDE.md` §4): la estructura sale de §13.2 #3 y de las cuatro rondas anteriores; los permisos son los de `rpc_guard`.

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 1 aviso (la palabra «vacío» no aparece literal: los vacíos se llaman «Todo medido», «Sin tinas fermentando», «Sin corridas…», «Hoy no hay nada pendiente», «¿Qué tienes hoy?»).
- Chromium (Playwright): **45 combinaciones** (3 espacios × 15 estados): sin desborde horizontal del marco, ≤1 primaria visible por vista (compact: primaria solo en la barra), 0 targets <44 px, 0 errores JS (un choque de nombre con `window.top` corregido antes de la revisión final).
- Estados: default · carga · sin lotes · antes de la hora · todo medido · sin tinas · sin corridas ni colectores · nada pendiente · 14 por medir · nombres/folios largos · sin señal · solo lectura · operador · cola con fallo y corrección · error de carga.
- Capturas revisadas: 1440 default / fallo / nada; 768 default; 390 default / fallo / offline / muchas / largo / temprano.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Bloques Hoy | una columna: Toca medir › Destilación › Por enviar | una columna | dos columnas: Toca medir (3fr) \| Destilación + Por enviar (2fr) | la tarea diaria domina; en ancho, lo secundario cabe al lado sin bajar | grid + container query | una sola fuente de datos; sin ramas |
| Fila de tina | título/sub arriba, botón a todo el ancho | botón a la derecha | igual | una mano | grid | — |
| Primaria «Medir» | barra inferior «Medir Tina 3» (la fila la esconde) | en la fila más atrasada | igual | una primaria por vista; alcanzable con el pulgar | `data-wf-persist` + barra sticky | el foco al volver de Medir cae en el título de Hoy |
| Resumen | envuelve a dos líneas | una línea | una línea | lectura en 3 s | texto | `role=status` |
| Por enviar | acciones apiladas a todo el ancho | en fila | en la columna derecha | motivo + acción juntos | list-stack | Reintentar mantiene el foco en el elemento |
| Navegación | inferior (shell) | lateral 160 | lateral 240 | shell/r01 | app-shell | — |

## Comprobaciones NO ejecutadas

- Datos reales (vistas, cola) y navegación a Medir/Cortar: en coco.
- Comportamiento real del rótulo por `measurement_reminder_hour` y de la instantánea: en coco.
- Lector de pantalla, tacto físico, zoom nativo: fuera de esta fase (como en MH r06).

## Hallazgos

Ver `hallazgos.md`: 3 altos, 3 medios, 2 bajos; todos con decisión.

## Traspaso

- **→ lima · piezas.** **Reutiliza:** `app-shell`, `page-header`, `banner`, `state-block`, `status-chip` (`pending`/`failed`/`partial`/`on`), `list-stack`, `button`. **Candidata (que lima decida):** `queue-item` — ítem de la cola con resumen, estado, motivo y acciones Reintentar / Corregir / Descartar (hoy el shell solo muestra el total y Fermentación lo pinta por fila; si se repite en Inicio conviene una sola pieza). **Local (product-application `inicio-hoy`):** `HoyPage`, `FilaTinaHoy` (o reutilizar `FilaUso` de fermentación con `puedeGestionar=false`; lima decide), `FilaCorridaHoy`, `FilaColectorHoy`, `api.ts` (`cargarHoy` con `conInstantanea`, puras: `resumenHoy`, `rotuloHora`).
- **Datos (`coco.data_contract`, propuesta):** `Hoy = { tinas: UsoTina[] (tinas_en_uso), ajustes: { measurement_reminder_hour, fermentation_expected_days } (organization_settings), corridas: Corrida[] (corridas, status = abierta), colectores: ColectorConSaldo[] (colectores_con_saldo), cola: ElementoCola[] (useCola, por empresa) }`; derivados: `porMedir/medidas/listas = agrupar(tinas)`, `dia = diaDelCiclo(started_at)`, `antesDeHora = hora local < measurement_reminder_hour`.
- **→ coco:** reemplaza el placeholder de `modules/inicio/pages/InicioEmpresaPage.vue` conservando `tieneLotes` → arranque; rutas de atajo: `/fermentacion/:ciclo/medir`, `/destilacion/:corrida`, `/destilacion/:corrida/corte`, `/granel/transferir?origen=`, `/fermentacion/formular`, `/destilacion/abrir`; el foco al volver a Hoy cae en el título; Medir/Cortar no dependen de `enLinea`. Evidencia real con Aurelia (Cuatro Vientos): Hoy con la semilla (Tina 2 y Tina 3 por medir, Tina 1 en vaciado), medir Tina 2 desde Hoy y verla salir de la lista; Tomás (operador) sin «Pasar a granel»; sin señal con instantánea.
- **→ mora:** nada hasta implementar.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) → lima → coco → mora.
