# Assessment B — detector y navegador — 2026-09-28

Target: `design-hub/lab/maguey-horneado/r01/index.html`
URL: `http://localhost:4321/design-hub/lab/maguey-horneado/r01/index.html`
Independencia: no se leyó Assessment A ni se compartieron findings; sólo se coordinó el viewport global del navegador. Pestaña B nueva, IAB tab 1, cerrada al acabar. Sólo se escribieron archivos nuevos en esta carpeta.

## Detector (una sola ejecución)

Comando: `.codex/skills/lima/vendor/impeccable/scripts/impeccable detect --json design-hub/lab/maguey-horneado/r01/index.html`
Exit code 2 (findings); ejecutado una vez, sin reintentos. Total 22 resultados, 3 reglas:

| Regla | Cantidad | Severidad | Localización reportada |
|---|---:|---|---|
| `low-contrast` | 20 | warning / quality | `/Users/datateamconsulting/Downloads/PULZ/design-hub/lab/maguey-horneado/r01/index.html`, línea 0 para todos |
| `cramped-padding` | 1 | warning / quality | mismo archivo, línea 0 |
| `repeating-stripes-gradient` | 1 | advisory / slop | mismo archivo, línea 0 |

Los 20 avisos low-contrast son idénticos: `1.0:1 (need 4.5:1) — text #111111 on #111111`. El CLI no identifica nodos o líneas reales: no brinda localizaciones fiables para este render dinámico. No se confirmó texto negro sobre negro en las vistas inspeccionadas. La lectura DOM computada de ambas primarias en Maguey dio texto `rgb(255,255,255)` sobre fondo `rgb(17,17,17)`, consistente con `.wf .wf-btn--primary` en línea 124 y con la captura. Tratar esos 20 avisos como falsos positivos probables/no confirmados de cascada estática; no presentar veinte problemas de contraste verificados.

`cramped-padding`: `<div> "wf-frame": children flush against border+bg on all sides (no inset)`. Falso positivo para esta estructura: es el marco de pantalla, cuyos hijos shell/header/sidebar van deliberadamente a borde; cuerpo y filas tienen padding propio. Regla CSS del frame línea 38.

`repeating-stripes-gradient`: `repeating-gradient decorative stripes`. Falso positivo/no aplicable al estado: estilo neutral `.wf-img` del kit (línea 58) sin instancia visible. El objetivo es F2 neutral; no exige marca, Manrope o color primario PULZ, ni corresponde acusarlo de interfaz final genérica por su paleta gris.

## Evidencia de navegador

Se utilizó la herramienta nativa CUA/IAB. No hubo script de navegador externo. Se inspeccionaron marcos 1440, 768 y 390 con controles reales; viewports físicos 1440×1000, 768×1024, 1024×1000 y 390×844. El override global se restableció al terminar.

Limitación exacta a 1024: tras reload en viewport 1024, el propio prototipo selecciona marco 768 (`innerWidth < 1200 ? 768`). Sólo ofrece marcos 1440/768/390. No se inyectó estado, por lo que **no se validó un container de 1024**, aunque sí el comportamiento de la página en viewport 1024. No llamar a esta revisión cobertura íntegra del breakpoint expanded 1024.

La estructura interna no desbordó el frame en los casos medidos: frame1440 client1438/scroll1438; frame768 client766/scroll766; frame390 client388/scroll388. El folio largo con guiones se quebró y quedó legible en compact (heading client219/scroll219). En teléfono real, el stage suma padding a su marco fijo: viewport390, frame390 colocado x16→406, stage scroll422 y documento scroll435. La barra de controles también desborda. Esto es un defecto del **visor F2**, no prueba de que la futura app de producción desborde.

### Hallazgos visuales/semánticos verificados

1. **P1 — La primaria desaparece en ambos vacíos compact.** En `m-empty`, el mensaje invita a registrar pero no queda botón visible; en `h-empty`, invita a abrir horneada pero sólo queda «Cocido que ya tenía». DOM de h-empty: única primaria «Abrir horneada» con `display:none`, rect0×0. Causa: CSS `[data-wf-persist]` oculto en compact (línea 114), mientras `sinPrim` de esos estados suprime top y FAB (render líneas 294–299). Los templates m-empty/h-empty están líneas 270 y 277. Esto sí es un defecto de estructura F2, independiente de que los enlaces sean mocks.

2. **P2 — Selects sin etiqueta programática.** Especie, Predio y Proveedor en recepción se ven etiquetados, pero sus `select.labels` son `[]`; aparecen como combobox sin nombre en snapshot. Horno en apertura también. Fuente líneas 245 y 257. Los inputs de kilos sí tienen labels asociados. En saldo excedido, `k2` tampoco tiene `aria-invalid` ni asociación a «Solo hay 1,300 kg», y ambos campos se llaman sólo «Kilos», sin identificación del lote para lector de pantalla. Fuente líneas 260–261. Señalar como contrato de accesibilidad que debe fijarse antes de construir, sin confundirlo con backend.

3. **P2 — Referencias de muestra contradictorias en Horneado.** El estado default muestra HOR-002 simultáneamente abierta con 5,200 kg y como origen ya cerrado hoy del lote AC-002. Es visible en captura horneado-768 y en DOM; fuente líneas 252–253. Conviene separar identificadores de ejemplos para poder evaluar estados y linaje sin contradicción.

4. **P2 — Visor no ofrece revisión real de 1024 y recorta a ancho de teléfono.** Detalle y límites arriba. No requiere rediseño de la app para corregir visor.

### Límites de interacción F2, no defectos de producción comprobados

La única lógica manejada por JS es selección de ancho/estado/notas y render. El flujo de producto no está conectado: navegación es `li`/`span`; botones/enlaces de registro/cierre, Cancelar y Más no llevan a estados reales. No existe submit handler ni validación dinámica. No se envió ni modificó información de DB.

Se escribió `abc` en Kilos de recepción: tipo text, required:false, valid:true; el botón continuó diciendo «Registrar 2,000 kg de Tobalá». Es limitación de mock/insuficiencia para validar entrada numérica y total reactivo, no evidencia de que la app acepte kilos inválidos.

Diálogo `h-cerrar`: tiene role=dialog, aria-modal=true y título asociado. Al abrir por el selector, el foco permaneció fuera; Tab desde Cancelar salió al BODY, Escape no cerró y hacer click en Cancelar tampoco. El estado seguía teniendo 1 diálogo. Debe implementarse inicialización/trampa/restauración de foco, Escape y cancelación cuando sea interactivo. No puntuar toda la operación como rota sin declarar primero que F2 sólo cambia por el selector de estados.

El saldo excedido muestra texto localizado y bloquea ambos botones submit (disabled:true), pero es un estado fijo: no prueba de actualización al editar. El modal compact se posiciona dentro del frame, no del viewport; medido top453.5/bottom1317.5 en teléfono844, por lo que los controles inferiores requieren scroll de página. Esto limita evaluación de ergonomía de sheet, sin afirmar que sea producción.

## Overlay / limpieza / fallback

El API disponible documenta `playwright.evaluate` como **read-only**; capacidades de tab sólo `pageAssets` y `webmcp`. No expone evaluación mutable ni inserción de scripts. Por ello el preflight de mutación se descartó por capacidad documentada: no se intentó saltar la limitación con evaluate, URL javascript o navegador externo. **No se inyectó detect.js y no existe overlay [Human] fiable.** No se llamó live-server ni visibility.set(true); navegador de B permaneció en background. Tampoco hay console findings del detector en página.

Fallback usado: CLI ejecutado una vez + capturas nativas + DOM/snapshot/estilos computados de sólo lectura + controles UI. El servidor4321 lo inició el padre, que tiene la responsabilidad de detenerlo; B no inició proceso propio. Pestaña B cerrada y viewport reset. Capturas son evidencia retenida, no temporales a borrar. No se crearon archivos temporales fuera de esta carpeta.

## Capturas retenidas

- `maguey-1440.png`
- `cerrar-1440.png`
- `abrir-saldo-frame390.png` (frame390 en viewport1440)
- `long-frame390.png` (frame390 en viewport1440)
- `h-empty-frame390.png` (frame390 en viewport1440)
- `h-empty-390.png` (viewport real390)
- `m-empty-390.png` (viewport real390)
- `horneado-768.png`
- `maguey-1024-frame768.png`
- `cerrar-390.png`
