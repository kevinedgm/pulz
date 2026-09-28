# Maguey y Horneado · `maguey-horneado`

**Draft 0.2.1 · owner lima · r05 · 2026-09-28.** Implementación local con
verificación parcial. **No Candidate, no Stable, no release de producción.**
La preview usa los componentes Vue reales con datos simulados; nunca escribe
en Supabase. La aceptación de r01/r02/r03 no se reutiliza.

## Propósito

Consultar lotes de maguey y cocido por saldo; registrar recepción, abrir una
horneada con consumo explícito y registrar su cierre. Dos destinos conservan
la separación del proceso y la continuidad hacia Formulación.

## Uso

Recepción requiere sólo kilos positivos; piñas, especie, predio, proveedor,
fecha, folio y nota no se seleccionan silenciosamente. Para abrir, elegir
horno y kilos por lote, revisar el consumo y confirmar. Cerrar registra kilos
cocidos y linaje; la diferencia se muestra, no se inventa un registro de merma.
«Cocido que ya tenía» registra carga inicial sin historia.

Admin/productor con señal y suscripción pueden registrar. Operador y modo
lectura consultan. Una instantánea queda identificada y bloquea captura hasta
recuperar datos frescos. No es captura offline.

## Ejemplos

<!-- hub-preview -->

[Abrir demo Vue](../Components/demo/index.html?pieza=maguey-horneado&solo=1)

El selector del arnés ofrece normal, vacío, carga, error, operador, sin conexión,
texto largo, fallo de envío y aproximación de texto200%. No emula autenticación
ni verifica RLS. El acceso de Formulación en la demo termina en un aviso de
destino fuera de alcance; en la app apunta a su ruta existente.

## Anatomía

Cabecera con una primaria; Maguey con saldos y agotados plegados; Horneado con
abiertas, cocido disponible y últimas horneadas. Identidad, cantidad con unidad,
estado textual y acciones son grupos distintos. Formularios y revisión
conservan borrador dentro de la pantalla. Máximo50 activos visibles por página.

## Comportamiento

Error conserva datos. Un resultado incierto conserva la intención completa
antes del envío en almacenamiento local por empresa/persona/destino. El
reintento manual mantiene clave, cantidad y fecha; no se reenvía automáticamente.
Un rechazo transaccional conocido permite corregir. El guard bloquea doble
envío. Si no puede protegerse la intención localmente, no se llama a la RPC.
Borrar los datos del navegador elimina la protección local; no hacerlo mientras
haya envíos pendientes. «Quién» procede de perfiles visibles por RLS, nunca UUID
presentado como nombre; si falta el perfil, no se inventa autor.

Una intención incompleta queda conservada y bloqueada, nunca se reenvía.
Cambiar de persona invalida datos/permisos y cambia la partición local;
respuestas antiguas de membresías se descartan. La instantánea muestra fecha/hora.
El contexto del cocido identifica horneada de salida, carga inicial o compra
desde los campos existentes, no desde una recepción de maguey supuesta.

## Adaptación

Compact<600: una columna, navegación inferior, primaria de cabecera, capa inferior.
Medium600–1023: rail160px con etiquetas completas y corte silábico discrecional
«Fermenta-ción» cuando no cabe; el nombre accesible sigue siendo «Fermentación».
Expanded≥1024: sidebar240px;
el contenido usa hasta960px y columnas según espacio de su contenedor.
Insets16/24px; formularios720px, revisión640px, cierre440px.
El mismo formulario se conserva al cambiar tamaño.

## Accesibilidad

Teclado y foco comprobados en navegador; errores asociados a campos,
significado no sólo por color, acciones descriptivas y cantidades con kg.
`danger-text` canónico corrige el contraste de errores pequeños. Controles
de48px y targets mínimos44px según Foundations. No se certifica WCAG completa:
pendientes touch físico, lector de pantalla, forced-colors y zoom nativo200%.

## API real

`SuperficieMH` recibe `datos`, `destino`, `puede`, `enLinea`, `guardar`,
`formulacion`; opcionales `errorCarga`, `instantanea`, `simulado`, `contexto`.
Emite `recargar`. Es componente local, no nueva API estable del sistema.

`guardar(captura)` recibe la unión recepción/apertura/cierre/entrada cocido.
Adaptación a `registrar_recepcion_maguey`, `abrir_horneado`, `cerrar_horneado`
y `registrar_entrada` existentes; los permisos definitivos son de RLS/RPC.

## Implementación

Código en `apps/web/src/modules/maguey-horneado/`; rutas `/e/:slug/maguey`
y `/e/:slug/horneado`. Demo en `apps/web/hub/DemoMagueyHorneado.vue`.
Reutiliza button, number-field, text-field, select, datetime-field,
origin-allocation, status-chip, state-block, task-layer y shell canónicos.
Fuentes locales y tokens de Foundations; ningún cambio de valores base.

## QA y lifecycle

R05:34 pruebas del módulo incluidas en183 pruebas locales de aplicación PASS;
build de app, tipos, demo y lint del alcance PASS. Los cinco tests de acceso
alojado pasan tras autorización específica; el fallo DNS inicial correspondía
al entorno restringido. Esto no aprueba operaciones de negocio alojadas.

Browser:320/390/600/768/1023/1024/1440, normal y folio largo; recepción123.456kg,
apertura120.5kg, cierre100.25kg y entrada9.75kg simulados con teclado; retorno de
revisión, Más, detalle y foco. Corte de «Fermentación» corregido. Composición
revisada por separado del overflow. No se verificó shell autenticado con RPC reales.

Seis dimensiones y evidencia: [resultado r05](../lab/maguey-horneado/r05/result.md)
y [matriz de aceptación](../lab/maguey-horneado/r05/acceptance-matrix.md).
Mora documenta sólo hechos y límites del draft por el dictamen nuevo de Lima.
No hay promoción a Candidate/Stable ni aceptación global.
