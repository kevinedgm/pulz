# R05 · evidencia y límites de aceptación

2026-09-28. No se reutilizó ninguna aprobación histórica.

## Hallazgos corregidos

| ID | Dueño | Corrección | Evidencia |
|---|---|---|---|
| MH-F3-VIS-01 | Kiwi → Lima → Coco | Fermenta-ción discrecional; rail y tipografía conservados | visual-runtime.json + capturas, NavEtiquetas.test.ts |
| MH-AUTH-05 | Coco | Cambios de persona invalidan datos/permisos e intención; refresco de membresías descarta respuestas antiguas | pagina.test.ts + acceso/store.test.ts |
| MH-INTENT-05 | Coco | Valida todas las variantes recuperadas; contenido corrupto se conserva y nunca se envía | superficie.test.ts |
| MH-ORIGIN-05 | Coco | lots.origin + roasting_runs.output_lot_id distinguen cocido producido, inicial y comprado | carga.test.ts |
| MH-CACHE-05 | Coco | Fecha y hora de instantánea visibles, captura bloqueada | superficie.test.ts |
| MH-TEST-05 | Coco | Test del shell comprueba etiqueta normalizada y nombre accesible original | shell.test.ts |

## Composición local

Capturas `evidence/{horneado,maguey-long}-*.png`, con anchos medidos en el
iframe:320,390,600,768,1023,1024,1440. Las capturas terminadas en
`full-1023/1024/1440.png` completan la zona que el viewport externo recortó.
`invalid-click-attempt.json` NO es evidencia de aceptación: el clic no activó
el arnés; se repitió con Enter y se exigió ancho real igual al solicitado.
Las capturas `before-600/1023` también conservaron768 por el mismo problema;
sólo `before-768.png` reproduce el defecto previo con ancho correcto.

| Criterio | Compact | Medium | Expanded |
|---|---|---|---|
| collision | Sin solapamiento visible; nav al pie | Rail separado | Tres zonas de fila sin solapamiento |
| crowding | Cinco targets separados; texto completo | Corte Fermenta-ción | Etiqueta completa en una línea |
| hierarchy | Kilos dominan, contexto secundario | Misma prioridad | Kilos en zona comparativa |
| grouping | Filas por espacio/divisor | Contexto y estado agrupados | Identidad, kg y acciones separados |
| alignment | Contenido16px | Contenido24px, rail160px | Contenido24px, sidebar240px |
| density | Vertical, sin forzar columnas | Columnas sólo si caben | Ancho máximo960px |
| action dominance | Una primaria de cabecera | Primaria clara | Primaria arriba, secundarias de fila |
| responsive | Bottom navigation | Rail | Sidebar |
| Foundations | Manrope, Lucide, tokens canónicos | Igual | Igual |

Alcance: demo con componentes de producción, no shell autenticado ni hardware.
Sin overflow en14 observaciones correctas; no se usa esto como sustituto de
la evaluación de composición. Dos revisores independientes participaron en
código/datos y navegación visual; no constituyen pruebas de tecnología asistiva.

## Remoto (15)

- 15.01: sandbox ENOTFOUND; petición HTTPS sin credenciales fuera del sandbox
  responde401. El servidor es alcanzable: limitación de red del sandbox.
- 15.02: proyecto identificado `ypgeiyorgktshgbzhgfh`; semilla declara
  cuatro-vientos(admin/productor/operador) y prueba-b(admin). No son desechables.
- 15.03: autorización específica obtenida sólo para cinco tests de acceso y
  lectura de membresías; no para fixtures persistentes ni operaciones de negocio.
- 15.04: **5/5 PASS** en `evidence/hosted-access.json`. Un intento inicial fue
  bloqueado por auto-review; se ejecutó sólo después de autorización explícita.
- 15.05–15.14: **BLOCKED**, falta tenant aislado persistente autorizado con
  usuarios por rol y plan de limpieza acotado. Los tests con mocks NO los cierran.
- 15.15: dictamen remoto **PARTIAL**: acceso PASS, flujo de negocio no ejecutado.

Propuesta para desbloquear: autorizar fixtures nuevas `qa-mh-r06-*` únicamente
en PULZ, cuatro operaciones de M/H y consumo de Formulación; dos tenants aislados
y usuarios de prueba. Identificar IDs antes de mutar y registrar limpieza por
IDs exactos, sin reset ni tocar demos. Aún no se han creado ni ejecutado.

## Accesibilidad (16)

| Criterio | Resultado | Evidencia / límite |
|---|---|---|
| 16.01 matriz | DONE | macOS + IAB; viewport CSS/teclado/DOM; sin control nativo de AT/hardware |
| 16.02 teclado | PARTIAL | keyboard.json: cuatro capturas simuladas, revisión/retorno, Más, detalle, Escape/foco/Tab de capa; falta barrido completo de orden y shell autenticado |
| 16.03 tacto físico | BLOCKED | DOM ≥48px alto en navegación no sustituye taps físicos |
| 16.04 teclado virtual | BLOCKED | No hay móvil físico disponible |
| 16.05 texto200% nativo | BLOCKED | La aproximación del arnés no cumple este requisito |
| 16.06 forced-colors | BLOCKED | No hay capability de emulación ni control nativo disponible |
| 16.07 lector pantalla | BLOCKED | Nombres DOM verificados; pronunciación/anuncios no probados |
| 16.08 contraste/motion | PARTIAL | computed-colors.json; elementos muestreados sin transición; falta matriz completa y reduced-motion de capas |
| 16.09 extremos | PARTIAL | Folio largo siete anchos y decimales probados; no toda la combinación paginación + texto nativo200% |
| 16.10 correcciones | DONE local | Seis findings anteriores resueltos con tests; no certifica contextos no ejecutados |
| 16.11 dictamen | DONE | Accessibility PARTIAL; no declaración global WCAG2.2AA |

## Gates (17)

Candidate NO ELEGIBLE: anatomía, estados, responsive y demo existentes;
baseline a11y incompleta (zoom nativo) y ciclo formal completo
critique→distill→adapt→polish no ejecutado en esta ronda. Hub no equivale a promoción.
Stable NO ELEGIBLE: Candidate no aprobado, además hardware/AT pendientes.
Mora SÍ ELEGIBLE únicamente para sincronizar la ficha draft con hechos y límites.
Frente sigue abierto en aceptación, sin otro frente ni despliegue.
