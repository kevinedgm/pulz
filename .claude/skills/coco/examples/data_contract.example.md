# `coco.data_contract` — no lo llenas tú

**Lo primero, para que no te bloquees:** el `data_contract` **empieza vacío (`none-yet`) y tú no tienes que escribirlo.** coco lo va llenando **solo**, mientras diseñas. No es un formulario de instalación.

```yaml
# así queda tras el setup — y así se queda hasta que empieces a diseñar:
coco:
  data_contract: none-yet
```

### ¿Cómo se llena entonces? (sin que hagas nada especial)

coco, cada vez que le pides diseñar una pantalla, **empieza preguntando por el dato protagonista** (es el Paso 1 de su protocolo). En ese momento:

- Si ya tienes el modelo en código (tipos, DTOs, API), coco lo **lee** y registra la entidad.
- Si aún no existe (proyecto en construcción), coco te pregunta los campos, tú respondes, y coco los **anota** en el `data_contract`.

En ambos casos **coco escribe el contrato por ti**, como efecto de ir diseñando. Con el tiempo el contrato refleja las entidades que realmente usaste — sin que nunca te sentaras a "llenarlo".

> **¿Estás construyendo el proyecto y no sabes el modelo aún?** Perfecto: déjalo en `none-yet`. coco tratará los datos como *ilustrativos* (los marca como ejemplo, no reales) y poblará el contrato conforme las entidades vayan apareciendo. No te bloquea.

### Atajo opcional (solo si quieres adelantarlo a mano)

No es necesario, pero si prefieres agregar una entidad tú mismo, se lo pides a coco en lenguaje natural:

> *"coco, agrega al data_contract: Usuario = id, nombre, email?, avatar?"*
> *"coco, lee mis tipos en `src/types/` y arma el data_contract"*

---

## Qué guarda el contrato (para que lo reconozcas cuando coco lo escriba)

Cuando coco lo puebla, cada entrada tiene tres partes:
1. **Entidades y campos** — `Entidad = campo1, campo2?, campo3?` (el `?` = opcional; coco maneja el caso vacío).
2. **Reglas de presentación** — decisiones derivadas del dato (cuándo mostrar/ocultar/derivar). No son campos.
3. **NO reales** — la lista negra: lo que se ve bien pero no existe en tu API.

Los siguientes son ejemplos de **cómo se ve el contrato DESPUÉS** de que coco ha trabajado un rato en distintos proyectos — no algo que copies al empezar.

---

## Ejemplo A — Marketplace / directorio (con reseñas y precio)

```yaml
coco:
  data_contract: >
    Vendedor = id, nombre, categoria?, ciudad?, descripcion?, avatar?,
    precioDesde?, calificacion?, totalResenas?.
    Producto = id, titulo, precio, imagen?, stock, vendedorId.
    Regla de presentación: mostrar estrellas solo si totalResenas >= 3.
    Regla: "agotado" se deriva de stock === 0 (no es un campo).
    Regla: si no hay avatar, usar iniciales del nombre.
    NO reales (nunca diseñar como reales): distancia/geolocalización, "disponible ahora",
    galería de fotos, dirección exacta, tiempo de entrega, chat en la tarjeta.
```

**Qué haría coco con este contrato** (al diseñar una tarjeta de vendedor):
- ✅ Dibuja nombre y, si vienen, categoría/ciudad/descripción/avatar (todos `?` → maneja el vacío: sin avatar usa iniciales; sin ciudad no deja un hueco).
- ✅ Muestra `precioDesde` como "Desde $X" solo si existe; si no, "Precio a consultar".
- ✅ Muestra estrellas **solo si `totalResenas >= 3`** (la regla); con 0–2 reseñas, sin estrellas.
- ✅ Marca "Agotado" derivándolo de `stock === 0`, no espera un campo `agotado`.
- 🚫 **Rechaza** poner "a 2 km de ti", "disponible ahora", una galería, la dirección exacta, el tiempo de entrega o un botón de chat — están en NO reales. Si tú se lo pides igual, coco lo marca como *"propuesta futura (no hay dato)"* en vez de fingir que existe.
- 🟡 Si pides un campo que **no está** en el contrato (p. ej. "muestra el teléfono"), coco te avisa que ese dato no está declarado y pregunta antes de inventarlo.

## Ejemplo B — App de tareas / proyectos

```yaml
coco:
  data_contract: >
    Tarea = id, titulo, estado, prioridad?, vence?, asignadoA?, etiquetas?.
    Usuario = id, nombre, avatar?.
    Regla de presentación: "vencida" se deriva de vence < hoy (no es un campo).
    Regla: mostrar avatar si existe; si no, iniciales.
    NO reales (no diseñar como reales): progreso %, horas estimadas,
    número de comentarios, adjuntos, actividad reciente en la tarjeta.
```

**Qué haría coco con este contrato** (al diseñar una fila/tarjeta de tarea):
- ✅ Dibuja título y estado siempre; prioridad, fecha, asignado y etiquetas solo si vienen (`?`).
- ✅ Marca la tarea como "Vencida" **derivándolo** de `vence < hoy` — no busca un campo `vencida`.
- ✅ Muestra el avatar de `asignadoA` si existe; si no, iniciales.
- 🚫 **Rechaza** dibujar una barra de progreso %, "3h estimadas", el número de comentarios, adjuntos o un feed de actividad: no están en el modelo. Nada de barras de progreso decorativas sin dato detrás.
- 🟡 Si pides "muestra cuánto falta para vencer", coco lo acepta porque **se deriva** de `vence` (dato real); pero "muestra el progreso %" lo rechaza porque no hay de dónde calcularlo.

## Ejemplo C — Panel SaaS / facturación

```yaml
coco:
  data_contract: >
    Cuenta = id, nombre, plan, estado, creadaEn.
    Factura = id, numero, monto, moneda, estado, emitidaEn, venceEn?.
    Regla de presentación: "vencida" se deriva de venceEn < hoy y estado != 'pagada'.
    Regla: montos con separador de miles y 2 decimales; nunca color como único indicador de estado.
    NO reales (no diseñar como reales): proyección de gasto, uso en tiempo real,
    comparativa con otras cuentas, "ahorro estimado".
```

**Qué haría coco con este contrato** (al diseñar la lista de facturas):
- ✅ Dibuja número, monto (con miles y 2 decimales, la regla) y estado siempre; `venceEn` solo si viene (`?`).
- ✅ Marca "Vencida" derivándolo de `venceEn < hoy && estado != 'pagada'`.
- ✅ Acompaña el estado con **texto + icono**, nunca solo color (la regla) → cumple accesibilidad.
- 🚫 **Rechaza** gráficas de proyección de gasto, medidores de uso en tiempo real, comparativas con otras cuentas o un "ahorro estimado": no hay datos para eso.
- 🟡 Si pides un dashboard con "gasto del próximo mes", coco te dice que ese dato no existe y ofrece, a lo sumo, un placeholder marcado como *propuesta futura*.

---

## Cómo se ve un contrato mal hecho (evítalo)

```yaml
# ❌ Vago: coco no sabe qué es real ni qué manejar como opcional.
coco:
  data_contract: "usuarios y productos"
```
**Qué pasa:** coco no puede confiar en ningún campo. O te frena a preguntar todo, o —peor— rellena la UI con campos plausibles (email, teléfono, foto) que quizá no existan. El diseño resultante no se puede implementar tal cual.

```yaml
# ❌ Sin lista "NO reales": coco no sabe qué NO debe inventar.
coco:
  data_contract: >
    Vendedor = id, nombre, precio.
```
**Qué pasa:** al no haber lista negra, coco puede "enriquecer" la tarjeta con distancia, tiempo de entrega o un chat porque *se ven bien* en un marketplace. Todo eso es inventado: no hay dato detrás. La tarjeta se ve linda en el mockup y es imposible en producción.

---

Un buen contrato **siempre** trae las tres partes: entidades (con opcionales `?`), reglas de presentación (lo que se deriva), y la lista de **NO reales** (lo que coco jamás dibuja aunque quede bonito). Con eso, lo que coco diseña siempre es implementable con los datos que tu proyecto realmente tiene.
