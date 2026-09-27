# PULZ · Documento maestro de implementación

> Especificación completa y plan por fases para construir PULZ, un SaaS de
> producción y trazabilidad de mezcal. Escrito para que **Claude Code** lo lea
> entero, elabore su plan de trabajo y lo implemente fase por fase.
>
> Versión 1 · 26 de septiembre de 2026 · Español de México.

---

## 0. Cómo usar este documento

### 0.1 Para Claude Code

1. **Lee el documento completo antes de escribir código.** Luego lee los archivos
   del paquete (§19) en este orden: `docs/referencia/pulz_esquema.sql`,
   `docs/referencia/pulz_simulacion_semilla.sql`, `docs/referencia/pulz_portal_function.ts`.
2. **Planea la fase actual, no todo el proyecto.** Al iniciar cada fase escribe
   `docs/plan/FASE-N.md` con: objetivo, tareas en orden, archivos que tocarás,
   pruebas que escribirás, y cómo vas a comprobar los criterios de aceptación.
   Muéstralo y espera aprobación antes de implementar.
3. **Una fase termina solo cuando pasan sus criterios de aceptación** (§16),
   comprobados con comandos reales. Si algo no se pudo comprobar, dilo.
   No declares terminado por optimismo.
4. **No inventes reglas de negocio.** Si algo no está aquí ni en los archivos de
   referencia, está en §18 (preguntas abiertas) o hay que preguntarlo. Anota la
   duda en `docs/DUDAS.md` y sigue con lo que no dependa de ella.
5. **Un commit por tarea coherente**, con mensaje en español que diga el porqué.
6. **Mantén vivo `docs/ESTADO.md`**: qué fase va, qué pasó, qué falta, qué se
   decidió y por qué. Es lo primero que lees al retomar una sesión.

### 0.2 Orden de autoridad

Cuando dos fuentes choquen, gana la de arriba:

1. Este documento (las decisiones de §2, §7, §10.2 y §18 son finales).
2. `referencia/pulz_esquema.sql` — punto de partida del modelo de datos.
   **No está probado en Postgres real**: al aplicarlo aparecerán errores de
   sintaxis o de orden. Corrígelos sin cambiar la intención y anótalos.
3. `referencia/pulz_simulacion_semilla.sql` — una empresa ficticia completa.
   Es la prueba de humo del esquema: si no carga, el esquema está mal.
4. La rama `saas` del repositorio `traker-palenque` (§17) — referencia de
   patrones ya probados. Se toma la idea, no se copia a ciegas.

### 0.3 Reglas de trabajo que no se negocian

- **Nunca** conectarse al proyecto Supabase de producción del sistema heredado
  (Istmeño). Todo se desarrolla contra Supabase local (CLI) y un proyecto nuevo.
- **Sin JSON ni JSONB para guardar datos.** Todo en columnas y tablas. Solo se
  permite JSON en interfaces que lo imponen (payloads HTTP, el hook de Auth).
- **Nada se borra en el dominio productivo.** Se corrige con otra operación o se
  anula con motivo y autor.
- **La seguridad vive en Postgres** (RLS, llaves foráneas compuestas, funciones
  con verificación de rol). La interfaz solo oculta lo que no tiene sentido ver.

---

## 1. El producto

### 1.1 Qué es

PULZ es la herramienta **privada del dueño del palenque** para registrar y
trazar su producción de mezcal: del maguey al granel. El dueño decide qué
presenta a terceros; el sistema no es una herramienta de cumplimiento para el
verificador.

### 1.2 Los dos dolores que resuelve

1. **Trazar un lote hacia atrás** sin hojear libretas: ¿de qué tinas, horneadas
   y magueyes salió este granel?
2. **Que los trabajadores registren desde el teléfono**, junto a la tina, el
   horno o el alambique, con las manos ocupadas y el sol de frente.

### 1.3 Para quién

Palenques y pequeños productores, sobre todo en Oaxaca. Tres perfiles dentro
de cada empresa: el dueño (administra), quien produce (registra todo el
proceso) y el operador (captura lo del día: mediciones, cortes).

### 1.4 Modelo de negocio

Autoservicio. La empresa se registra sola, prueba, y paga con tarjeta (Stripe).
Crecimiento por boca a boca y redes. Sin venta asistida, sin integración con
organismos certificadores. Dos planes: **Gratis** y **Palenque**
(precio tentativo $299 MXN/mes, sin validar).

### 1.5 Fuera de alcance del MVP

Envasado, hologramas, análisis de laboratorio con límites NOM, reportes para el
Consejo, notificaciones push, migración de datos del sistema heredado. Existen
en la rama `saas` (§17) y pueden venir después.

---

## 2. Principios de diseño

Si una pantalla o regla contradice uno de estos, gana el principio.

1. **Entra por donde estés.** Un lote puede registrarse en cualquier etapa
   (maguey, horno, tina, colector, alambique, tanque). No hace falta empezar por
   el maguey. La única etapa sin entrada directa es la molienda.
2. **La historia hacia atrás es opcional.** Se puede completar después, o nunca.
3. **Nada bloquea salvo lo imposible.** Bloqueos duros solo para: saldo
   negativo, capacidad `estricta`, datos de otra empresa, catálogo de otra
   empresa. Todo lo demás **avisa, pide nota y deja registrar**.
4. **El dueño decide qué se ve.** El sistema registra lo que pasó, incluso
   movimientos no ideales.
5. **Captura mínima, detalle opcional.** Cada pantalla de campo pide lo
   indispensable; el resto se despliega si se quiere.
6. **Todo es lote, recurso y movimiento.** Tres conceptos explican el sistema.

### 2.1 Reglas duras y blandas

| Tipo | Regla | Dónde se impone |
|---|---|---|
| Dura | Saldo de un lote en un recurso nunca negativo | RPC, dentro de la transacción |
| Dura | Capacidad de recurso con política `estricta` (alambiques) | RPC |
| Dura | Toda fila referencia solo filas de su empresa | Llaves foráneas compuestas |
| Dura | Un solo ciclo abierto por tina | Índice único parcial |
| Blanda | Capacidad `flexible` excedida | Aviso + nota en `operation_warnings` |
| Blanda | Ordinario y colas en la misma 2ª destilación | Aviso + nota |
| Blanda | % Alc. fuera de rango habitual | Aviso + nota |
| Blanda | Volumen declarado ≠ volumen del ledger | Movimiento de conciliación automático + aviso |
| Blanda | Brix inicial fuera de rango | Aviso + nota |

---

## 3. Glosario

| Término | Significado |
|---|---|
| **Lote** | Una cantidad identificable de material con folio: maguey, agave cocido, formulación, fermentado, destilado o granel. |
| **Recurso** | Algo físico donde está el material: horno, molino, tina, alambique, colector, tanque. Tiene nombre propio ("Alambique 1") y un tipo de catálogo ("Alambique de cobre"). |
| **Operación** | Una acción de una persona: quién, cuándo pasó, cuándo se sincronizó, por qué. |
| **Movimiento (pata)** | Una fila del ledger: un lote entra, sale o cambia de recurso. Una operación tiene una o varias patas. |
| **Ledger** | `liquid_movements`, inmutable. Los saldos se derivan de él; nunca se guarda un contador. |
| **Linaje** | `lot_lineage`: qué lote aportó cuánto a qué otro lote. Es lo que permite trazar hacia atrás. |
| **Nivel de historia** | `completa`, `parcial`, `declarada`, `sin_historia`. Informativo, no semáforo de cumplimiento. |
| **Corrida** | Una destilación en un alambique: primera o segunda pasada. |
| **Corte** | Lo que sale de una corrida por clase: puntas, mezcal, ordinario, colas. |
| **"Ya mezcal"** | Destilado de la 1ª pasada que ya sale en grado de norma. Va directo a granel sin 2ª pasada. Es normal. |
| **Colector** | Recipiente de una sola clase donde se acumulan cortes. |
| **Granel** | Mezcal terminado en tanque, listo para vender o envasar. |
| **Concepto de movimiento** | Entrada o salida de granel de un catálogo editable: agua, puntas, unión, laboratorio, autoconsumo, merma, venta… |
| **Portal** | `pulz.mx/e/<slug>`: la puerta de cada empresa, con su marca. |

---

## 4. El proceso, etapa por etapa

Flujo normal: **maguey → horneado → molienda/formulación → fermentación →
destilación → granel**. Por el principio 1, cualquier etapa (salvo molienda)
puede ser la primera que un palenque registra.

### 4.1 Recepción de maguey

- Captura: fecha, especie (catálogo), kilos (obligatorio), número de piñas
  (opcional), predio y proveedor (opcionales), nota de calidad.
- Crea un lote `maguey` con saldo sólido en kg.

### 4.2 Horneado

- Abrir: horno, lotes de maguey con kilos de cada uno, fecha de inicio.
- Cerrar: kilos cocidos, fecha de fin, combustible (texto). Crea el lote
  `agave_cocido` con linaje hacia cada maguey.
- Entrada directa: se puede registrar agave cocido "que ya estaba" sin horneado.

### 4.3 Molienda y formulación

- Una formulación toma agave cocido (kg), agua (L), insumos opcionales, y
  **reparte a una o varias tinas**. Cada tina abre un ciclo con su lote
  `fermentado` y linaje hacia la formulación.
- Sin entrada directa: una tina "que ya fermentaba" entra por fermentación.

### 4.4 Fermentación y medición diaria

- **Sin duración fija**: según formulación y clima tarda 4, 6, 7 o más días.
  `fermentation_expected_days` (7 por defecto) es solo referencia visual.
- **Se mide todos los días.** Recordatorio diario a la hora configurada.
- Dos modos por empresa:
  - **Mínimo**: una temperatura, un Brix, actividad.
  - **Completo**: 3 lecturas de temperatura y Brix en superficie y fondo,
    más actividad, dulzor y acidez.
- Cada lectura es una fila (`measurement_readings`). El promedio se calcula al
  vuelo, nunca se guarda.
- Una medición no se borra: se anula con motivo.
- El productor declara la tina **lista**; pasa a `en_vaciado` cuando se carga
  al alambique y a `cerrado` cuando se vacía. Solo entonces la tina se libera.

### 4.5 Destilación

- **Se abre una corrida cuando hay olla libre**, con lo que haya en el origen,
  lleno o no. No hay umbral de llenado.
- Orígenes de una corrida: una o varias tinas, o uno o varios colectores, con
  volumen de cada uno. La carga **consume** el líquido (el alambique no guarda
  saldo); la capacidad del alambique es regla dura.
- Cortes por clase, con volumen y % Alc. declarados:
  - **Puntas**: captura opcional (`record_puntas`, apagado por defecto). Suelen
    ser menos de 300 mL.
  - **Mezcal**: en 1ª pasada es "ya mezcal" y va directo a granel.
  - **Ordinario** y **colas**: van a sus colectores.
- 2ª pasada: normalmente una sola clase. **Ordinario y colas juntos se permiten**
  con aviso y nota.
- **Regla de acumulación de colectores**: un corte se suma al lote vivo del
  colector, **salvo** que ese lote se haya cargado a la misma corrida; entonces
  nace un lote nuevo (evita linaje circular).

### 4.6 Granel

Ver §5.

---

## 5. Granel y el catálogo de movimientos

### 5.1 Qué pasa en un tanque

- **Transferir** de colector o de otro tanque. Si el destino ya tiene lote, el
  usuario decide: **conservar un folio** (el sistema sugiere el del lote mayor)
  o **renombrar** (folio nuevo). En ambos casos se guarda el aporte de cada uno.
- **Entradas y salidas** del catálogo de movimientos (§5.2).
- **El sistema NO calcula el grado.** En cada entrada, quien la hace declara el
  **volumen y el % Alc. resultantes**. Las salidas no piden resultado.
- Si el volumen declarado no cuadra con el ledger (p. ej., contracción al
  agregar agua), la RPC registra una pata `conciliacion` por la diferencia y un
  aviso `diferencia_volumen`.
- Cada movimiento queda con **quién lo hizo, cuándo pasó y cuándo se
  sincronizó** (tabla `operations`).

### 5.2 Catálogo de movimientos (semilla)

Cada concepto trae comportamiento, no solo nombre:

| Dirección | Concepto | Lote de origen | Crea lote | Pide resultado | Pide contraparte |
|---|---|---|---|---|---|
| entrada | Agua para bajar grado | no aplica | no | sí | no |
| entrada | Puntas para subir grado | opcional | no | sí | no |
| entrada | Unión con otro lote | requerido | no | sí | no |
| entrada | Compra de granel | no aplica | sí | sí | sí |
| entrada | Carga inicial | no aplica | sí | sí | no |
| entrada | Ajuste de inventario (+) | no aplica | no | sí | no |
| salida | Venta a granel | — | — | — | sí |
| salida | Envasado | — | — | — | no |
| salida | Muestra de laboratorio | — | — | — | sí |
| salida | Muestra comercial | — | — | — | sí |
| salida | Autoconsumo | — | — | — | no |
| salida | Merma | — | — | — | no |
| salida | Ajuste de inventario (−) | — | — | — | no |

La empresa **agrega** los suyos (p. ej. "Regalo a cliente") y **desactiva** los
que no usa. Ver §10.2 para cómo se implementan las semillas.

### 5.3 Compra de granel

- El certificado del organismo es **opcional**: folio, organismo, especie y
  predio declarados; nada bloquea si faltan.
- El lote nace con `origin = 'compra'` e `history = 'declarada'`.

---

## 6. Trazabilidad y nivel de historia

- **Hacia atrás**: consulta recursiva sobre `lot_lineage` desde cualquier lote,
  con cantidades y % Alc. declarados en cada arista. Debe responder en una
  pantalla: "este granel salió de estas corridas, estas tinas, estas horneadas,
  este maguey de este predio".
- **Nivel de historia** por lote: `completa` (llega al maguey), `parcial` (una
  parte llega), `declarada` (origen externo con datos del proveedor),
  `sin_historia` (carga inicial). Se recalcula cuando cambia el linaje.
- **Completar historia**: el usuario puede ligar después un lote a sus padres
  (aristas con `retroactive = true`).
- **Bitácora**: vista `movement_log`, cada pata con quién, cuándo, concepto y
  nota. Filtrable por lote, recurso, persona y fecha.

---

## 7. Portal por empresa y acceso

### 7.1 Qué ve la gente

- Un solo sitio, pero cada empresa entra por **`pulz.mx/e/<slug>`** y ve su
  nombre, logo, color y mensaje de bienvenida, desde la primera carga.
- Al instalar la PWA desde ese portal, el icono del teléfono lleva el nombre de
  la empresa. Dos empresas instaladas en el mismo teléfono son dos apps.
- La vista previa del enlace en WhatsApp muestra la marca de la empresa.

### 7.2 Dos clases de persona

| | Titular (dueño) | Colaborador |
|---|---|---|
| Entra con | correo real | usuario simple: `ana.lopez` |
| Correo en Auth | el suyo | `ana.lopez@<organization_id>.usuarios.pulz.mx` |
| Recupera acceso | por correo | se lo restablece su administrador |
| Recibe correos | sí | nunca |

- El correo sintético usa el **id** de la empresa, no el slug, para que
  renombrar el portal no toque ninguna cuenta.
- `username`: `^[a-z0-9]([a-z0-9._-]{1,28}[a-z0-9])$`, único por empresa.

### 7.3 Slug del portal

- Formato `^[a-z0-9]([a-z0-9-]{1,38}[a-z0-9])$`, sin `--`.
- No puede ser uno de `reserved_slugs` (tabla, no CHECK).
- **Se puede cambiar.** El trigger `organizations_slug_guard` guarda el viejo en
  `organization_slug_history`; el viejo redirige con 301 para siempre y ninguna
  otra empresa puede tomarlo.

### 7.4 Estado del portal

| Suscripción | Portal |
|---|---|
| gratis, prueba, activa | abierto |
| vencida | abierto en **solo lectura** (se conserva lectura y exportación) |
| cancelada o inexistente | **404 genérico idéntico** |

El 404 no distingue entre inexistente y cancelada: no se revela qué empresas
existen. No existe ninguna función que liste portales.

### 7.5 Inicio de sesión

- El navegador pide `portal_branding(slug)` (función pública, columnas fijas:
  id, slug, nombre, logo, color, mensaje, solo lectura, redirección).
- El colaborador escribe usuario y contraseña; el navegador arma el correo
  sintético y llama **directo** a `supabase.auth.signInWithPassword`. No hay
  función de login intermedia: el correo sintético no es secreto, y así cada
  intento cuenta contra la IP real de quien lo hace.
- Un `@` en el campo significa correo real (titular).
- Todo rechazo muestra el mismo mensaje: "Usuario o contraseña incorrectos".
- **Freno de intentos**: hook de Auth "Password verification attempt" →
  `auth_password_attempt(event)`. 5 fallos en una hora bloquean 15 minutos
  (30 si reincide). El administrador desbloquea con `desbloquear_miembro`.
  Confirmar que el plan de Supabase incluye el hook; si no, anotarlo en
  `docs/DUDAS.md` y seguir con el límite por IP de Supabase.
- Tras entrar, el router compara el slug de la URL con las membresías de la
  persona: si pertenece, entra; si no, el mismo 404.

### 7.6 Alta de colaboradores

- Solo el administrador, desde Equipo. Una Edge Function `manage-member` crea la
  cuenta en Auth (`email_confirm: true`) y la membresía en una sola operación.
- Dos formas de entregar el acceso:
  1. **Contraseña dictada** en persona → `must_change_password = true`; el
     router lleva a cambiarla; la bandera la baja el servidor.
  2. **Enlace de bienvenida** de un solo uso (72 h) por WhatsApp:
     `pulz.mx/e/<slug>/bienvenida#<token>`. Se guarda solo el hash sha256.
     El trabajador elige su contraseña.

### 7.7 Marca en el HTML (Cloudflare Pages Function)

`referencia/pulz_portal_function.ts` va en
`apps/web/functions/e/[slug]/[[path]].ts`. Reescribe `index.html` con
HTMLRewriter (título, `apple-mobile-web-app-title`, `theme-color`, `og:*`,
manifiesto, icono) y sirve `/e/<slug>/manifest.webmanifest` con `id`, `scope` y
`start_url` propios. Cachea 5 minutos, incluido el "no existe". Si falla,
sirve la app genérica: es una mejora, no una dependencia.

---

## 8. Arquitectura

### 8.1 Piezas

| Pieza | Tecnología | Responsabilidad |
|---|---|---|
| PWA | Vue 3 + TypeScript + Vite + `vite-plugin-pwa` + Pinia + Vue Router | Interfaz, captura en campo, cola offline |
| Hosting | Cloudflare Pages | Servir la PWA y la función del portal (§7.7) |
| Base | Supabase Postgres | Modelo, RLS, reglas de negocio en funciones RPC |
| Auth | Supabase Auth | Titulares con correo, colaboradores con correo sintético, hook de intentos |
| Archivos | Supabase Storage | Bucket público `branding` (logos) y privado `evidencias` (fotos, documentos) |
| Servidor | Supabase Edge Functions (Deno) | `signup-company`, `manage-member`, `billing-checkout`, `billing-portal`, `stripe-webhook`, `platform-admin` |
| Cobro | Stripe | Suscripciones, portal de cliente, webhooks |

**Decisión final**: las funciones de servidor son Supabase Edge Functions, no un
Worker de Cloudflare (reemplaza lo dicho en la contrapropuesta). Cloudflare solo
sirve la PWA y la función del portal.

### 8.2 Dónde vive la lógica

- **Reglas de dominio**: en funciones RPC de Postgres, transaccionales e
  idempotentes (§12). El navegador nunca inserta patas del ledger a mano.
- **Captura simple** (mediciones): puede ir por PostgREST con políticas que
  restringen a ciclos abiertos de la empresa.
- **Nada de lógica de permisos en el navegador** que no esté también en la base.

### 8.3 Offline

- Solo **mediciones, cortes y fotos** se capturan sin señal. Van a una cola en
  IndexedDB con su `idempotency_key` (UUID generado en el teléfono) y
  `occurred_at` del momento real.
- Al volver la señal, la cola se envía en orden; reenviar es seguro porque la
  RPC busca la `idempotency_key` en `operations` antes de hacer nada.
- Transferencias, uniones, entradas y salidas de granel **requieren señal**:
  dependen de saldos que decide el servidor.
- La interfaz muestra cuántas capturas esperan envío y cuáles fallaron.

### 8.4 Ambientes

| Ambiente | Base | PWA | Stripe |
|---|---|---|---|
| local | `supabase start` | `pnpm dev` | `stripe listen` + modo prueba |
| staging | proyecto Supabase aparte | Cloudflare Pages (preview) | modo prueba |
| producción | proyecto Supabase aparte | Cloudflare Pages | modo real |

---

## 9. Estructura del repositorio

```
pulz/
├── apps/
│   └── web/
│       ├── functions/e/[slug]/[[path]].ts   # portal (Pages Function)
│       ├── public/icons/
│       ├── index.html                        # etiquetas genéricas que el portal reescribe
│       └── src/
│           ├── app/            # router, shell, guardias, navegación
│           ├── modules/        # un dominio por carpeta
│           │   ├── acceso/     # portal, login, cambio de contraseña, bienvenida
│           │   ├── equipo/
│           │   ├── catalogos/
│           │   ├── recursos/
│           │   ├── maguey/
│           │   ├── horneado/
│           │   ├── formulacion/
│           │   ├── fermentacion/
│           │   ├── destilacion/
│           │   ├── granel/
│           │   ├── trazabilidad/
│           │   ├── ajustes/
│           │   └── cobro/
│           │       # cada módulo: pages/ components/ api.ts routes.ts store.ts __tests__/
│           └── shared/
│               ├── ui/         # tokens.css, iconos y componentes (ver §13.4)
│               ├── offline/    # cola IndexedDB
│               ├── supabase/   # cliente, tipos generados, errores
│               └── utils/
├── supabase/
│   ├── config.toml
│   ├── migrations/             # 0001_… en orden, una responsabilidad por archivo
│   ├── functions/              # Edge Functions (§8.1)
│   ├── seed.sql                # solo local: dos empresas + la simulación
│   └── tests/                  # pgTAP
├── packages/
│   └── shared/                 # tipos generados de la base, constantes compartidas
├── .claude/                    # Fruti Squad instalado para Claude Code (§13.4)
├── design-hub/                 # Design Hub y registry de Fruti Squad (lo crea lima)
├── docs/
│   ├── ESTADO.md  DUDAS.md  DECISIONES.md
│   └── plan/FASE-N.md
└── .github/workflows/ci.yml
```

Monorepo con **pnpm workspaces**.

---

## 10. Modelo de datos

### 10.1 Convenciones

- Toda tabla de negocio lleva `organization_id NOT NULL` y
  `unique (organization_id, id)`; los hijos usan **llaves foráneas compuestas**
  `(organization_id, x_id)`. Así una fila de una empresa no puede apuntar a otra
  aunque una política RLS estuviera mal escrita.
- **ENUM solo para mecánica** (roles, estados, tipos de pata). Lo que un
  palenque nombra a su manera es catálogo.
- **Nada de listas en columnas**: lecturas, límites de plan y cambios de
  auditoría son filas.
- **Volúmenes solo en el ledger**; saldos por vista.
- **Grado**: siempre declarado por el usuario (`abv` en la pata,
  `result_abv` en la operación). No existe columna calculada de alcohol puro.
- `updated_at` lo fija el servidor con trigger (concurrencia optimista en
  catálogos y recursos).
- Nombres de columna: los dígitos forman su propio segmento (`brix_top_1`),
  para que el mapeo snake_case ↔ camelCase sea reversible.
- Grants explícitos por tabla; nunca `alter default privileges`.

### 10.2 Cambio obligatorio respecto a `pulz_esquema.sql`: semillas copiadas

El SQL de referencia comparte las semillas con filas de `organization_id NULL`
y tablas `*_hidden`. **Se reemplaza** por el patrón de la rama `saas`, que
conserva la llave foránea compuesta, lo único que el motor garantiza:

1. Plantillas de plataforma en tablas propias, sin `organization_id`:
   `catalog_item_templates`, `movement_concept_templates`, `species_templates`.
   Solo el admin de plataforma las edita.
2. `catalog_items`, `movement_concepts` y `species` pasan a
   `organization_id NOT NULL` con `unique (organization_id, id)`.
3. `seed_organization_catalogs(org)` copia las plantillas activas a la empresa.
   La llama `provision_organization()` en el alta (§12.1). Cada fila copiada
   guarda `template_id` para saber de qué semilla vino.
4. Ocultar = `active = false` en la fila de la empresa. Se eliminan
   `catalog_item_hidden`, `movement_concept_hidden`, `species_hidden`,
   `catalog_visible()`, `concept_visible()` y las vistas `*_for_org`.
5. Las referencias tipadas pasan a compuestas, p. ej.
   `foreign key (organization_id, type_item_id) references catalog_items(organization_id, id)`,
   más un CHECK o trigger que verifique que el `catalog` del elemento
   corresponde (`tipo_alambique` para un alambique, etc.).
6. Una plantilla nueva no se propaga sola a empresas existentes: hay una función
   de plataforma `propagate_template(template_id)` que la agrega a quien no la
   tenga, sin tocar las que la empresa ya editó.

Actualizar la simulación (`seed.sql`) para que siga cargando.

### 10.3 Grupos de tablas (del SQL de referencia, ya con §10.2)

| Grupo | Tablas |
|---|---|
| Plataforma | `reserved_slugs`, `organizations`, `organization_slug_history`, `profiles`, `platform_admins`, `organization_members`, `member_invitations`, `login_throttle`, `organization_settings` |
| Cobro | `plans`, `plan_limits`, `plan_features`, `subscriptions`, `stripe_events` |
| Catálogos | plantillas (§10.2), `catalog_items`, `movement_concepts`, `species`, `predios`, `suppliers`, `supplies` |
| Infraestructura | `resources` (un modelo para los seis tipos, con `capacity_policy` y `liquid_class` solo en colectores) |
| Núcleo | `operations`, `operation_warnings`, `lots`, `lot_lineage`, `lot_external_sources`, `maguey_receptions`, `liquid_movements`, `attachments` |
| Etapas | `roasting_runs` + `roasting_run_inputs`, `formulations` + `formulation_inputs` + `formulation_supplies`, `fermentation_cycles`, `fermentation_measurements`, `measurement_readings`, `distillation_runs` + `distillation_run_inputs` + `distillation_cuts` |
| Auditoría | `audit_events`, `audit_changes` |
| Vistas | `resource_lot_balances`, `lot_declared_abv`, `movement_log`, `solid_lot_balances` |

### 10.4 Detalles que ya se validaron con la simulación

La simulación de "Mezcal Cuatro Vientos" (242 filas, 475 llaves foráneas
revisadas con un verificador propio, no en Postgres) encontró y corrigió:

1. Referencia circular `operations.result_lot_id` ↔ `lots.operation_id`:
   la llave de `operations` es `deferrable initially deferred`.
2. La carga al alambique consume el líquido (destino nulo).
3. Un lote puede aportar dos veces al mismo hijo: sin `unique(child, parent)`.
4. Colector que se alimentaría a sí mismo: regla de §4.5.
5. Las RPC son `security definer` con verificación de rol al inicio.
6. Semillas por empresa: resuelto ahora con §10.2.

---

## 11. Seguridad

### 11.1 Roles

| Acción | admin | productor | operador |
|---|---|---|---|
| Portal, marca, ajustes, cobro | sí | no | no |
| Equipo: altas, roles, desbloqueos | sí | no | no |
| Recursos e infraestructura | sí | no | no |
| Catálogos (tipos, conceptos, especies) | sí | no | no |
| Predios, proveedores, insumos | sí | sí | no |
| Recepción, horneado, formulación | sí | sí | no |
| Mediciones | sí | sí | sí |
| Corridas y cortes | sí | sí | sí |
| Granel: transferir, entradas, salidas | sí | sí | no |
| Completar historia, corregir operaciones | sí | sí | no |
| Anular mediciones | sí | sí | no |
| Leer todo lo de su empresa | sí | sí | sí |

Estas asignaciones son la propuesta inicial; confirmar en §18.

### 11.2 RLS

- Toda tabla con RLS activada. **Una política por operación** (select, insert,
  update, delete). Nunca `for all`.
- Lectura: `is_member(organization_id)`. Para rendimiento, envolver como
  `(select is_member(organization_id))` y tener índice en
  `organization_members (user_id, organization_id)`.
- Escritura de producción: solo por RPC. Las tablas del núcleo no tienen
  política de insert/update para `authenticated`.
- Empresa con suscripción `vencida`: `has_role()` rechaza escrituras; la lectura
  sigue.
- El admin de plataforma **no ve datos de clientes**: las políticas de dominio
  no incluyen `or is_platform_admin()`. Su panel muestra agregados.

### 11.3 Pruebas de aislamiento (obligatorias antes de abrir registro público)

pgTAP con dos empresas reales en la semilla. Para cada tabla de negocio:
un usuario de la empresa A no lee, no inserta, no actualiza y no referencia
filas de la B, ni por PostgREST ni por RPC. Un operador no ejecuta RPC de
admin. Un usuario sin membresía activa no ve nada.

---

## 12. Comandos (RPC)

### 12.1 Contrato común

Todas las funciones de dominio:

- `security definer`, `set search_path = public`.
- Primer paso: `has_role(p_org, roles_permitidos)` o excepción `P0001`.
- Segundo paso: si `p_idempotency_key` ya existe en `operations` para esa
  empresa, **devuelven el resultado original** sin hacer nada más.
- Insertan la operación (`recorded_by = auth.uid()`, `occurred_at` del
  parámetro, `recorded_at = now()`), sus patas y su linaje en **una**
  transacción.
- Bloquean con `select … for update` los lotes y recursos que tocan, **en orden
  de id**, antes de validar saldos (evita carreras entre dos teléfonos).
- Errores con mensaje en español para la persona; prefijos estables para el
  cliente: `SALDO_INSUFICIENTE:`, `CAPACIDAD_EXCEDIDA:`, `NO_PERMITIDO:`,
  `LIMITE_PLAN:`.
- Los avisos blandos no fallan: requieren `p_nota` no vacía cuando aplican, y
  quedan en `operation_warnings`. Si falta la nota, fallan con
  `REQUIERE_NOTA:<codigo>` para que la interfaz la pida.

### 12.2 Funciones

| Función | Qué hace | Notas |
|---|---|---|
| `provision_organization(nombre, slug, …)` | Crea empresa, membresía admin, ajustes, suscripción gratis y copia catálogos | La llama `signup-company` con service_role |
| `registrar_recepcion_maguey` | Lote maguey + recepción | kg obligatorio |
| `registrar_entrada` | Entrada directa en cualquier etapa salvo molienda | Crea lote con `origin` `carga_inicial` o `compra`; datos externos opcionales |
| `abrir_horneado` / `cerrar_horneado` | Horneada con entradas en kg; al cerrar nace el agave cocido con linaje | Saldo sólido no negativo |
| `registrar_formulacion` | Formulación + reparto a tinas: abre ciclos y lotes fermentado | Un ciclo abierto por tina |
| `registrar_medicion` | Medición con lecturas como filas | Solo en ciclos abiertos; offline |
| `anular_medicion` | Marca anulada con motivo | No borra |
| `declarar_tina_lista` | Ciclo a `lista` | |
| `abrir_corrida` | Corrida + patas `carga_alambique` desde tinas o colectores | Capacidad estricta; aviso si mezcla ordinario y colas |
| `registrar_corte` | Pata `corte` a colector; nace lote o se acumula (regla §4.5) | Offline |
| `cerrar_corrida` | Cierra la corrida | |
| `cerrar_ciclo` | Tina vaciada, ciclo `cerrado`, tina liberada | |
| `transferir` | Mueve un lote entre recursos; si el destino tiene lote, conservar o renombrar | |
| `registrar_movimiento_granel` | Cualquier concepto de entrada o salida | Entradas piden resultado; conciliación automática |
| `completar_historia` | Liga un lote a padres existentes o a datos declarados | Aristas `retroactive` |
| `corregir_operacion` | Operación de corrección que referencia a la original | Nunca edita ni borra |
| `desbloquear_miembro` | Limpia el freno de intentos | Solo admin |

Firmas detalladas en la sección 0011 del SQL de referencia.

---

## 13. Interfaz

### 13.1 Navegación

- El menú sigue al proceso, no a las tablas: Inicio · Maguey · Horneado ·
  Fermentación · Destilación · Granel · Trazabilidad · (admin) Configuración.
- Infraestructura (tinas, alambiques, tanques) vive en Configuración; en
  Fermentación se listan **usos** de tinas, no tinas.
- Móvil (<640 px): navegación inferior, acción principal como botón flotante,
  una columna en orden de prioridad.

### 13.2 Pantallas clave

1. **Portal y acceso**: marca de la empresa, usuario, contraseña; cambio
   obligatorio; bienvenida por enlace.
2. **Primer arranque del dueño**: "¿Qué tienes hoy en tanques y tinas?" —
   captura rápida de cargas iniciales para empezar a usar el sistema el día uno.
3. **Inicio / hoy**: tinas que toca medir hoy, corridas abiertas, colectores con
   contenido, capturas pendientes de enviar.
4. **Medición diaria**: pensada para una mano, números grandes, un gesto por
   pantalla, funciona sin señal.
5. **Corrida**: orígenes, cortes, avisos en línea.
6. **Tanque de granel**: saldo, grado declarado vigente con quién y cuándo,
   historial de movimientos, botones Entrada / Salida / Transferir.
7. **Lote**: árbol hacia atrás, nivel de historia, completar historia.
8. **Configuración**: recursos, catálogos, equipo, ajustes, portal y marca.

### 13.3 Accesibilidad de campo

Objetivos táctiles de 44 px mínimo, contraste alto (uso bajo el sol), textos
cortos, confirmaciones claras con quién y cuándo quedó registrado.

### 13.4 Design system y flujo de interfaz: Fruti Squad

La interfaz se diseña, gobierna, construye y documenta con **Fruti Squad**
(`github.com/kevinedgm/fruti-squad`), instalado para Claude Code:

| Paso | Miembro | En PULZ |
|---|---|---|
| 1 | kiwi | Brief funcional, flujo y wireframes F0–F2 de cada pantalla de §13.2. La estructura se aprueba antes de pasar al siguiente. |
| 2 | lima | Decide qué es componente del sistema y qué es local, registra y fija el contrato. Guarda el perfil del proyecto. |
| 3 | coco | Alta fidelidad con los tokens reales e implementación en Vue; auditoría. |
| 4 | mora | Documenta en el Design Hub solo lo implementado y verificado. |

Reglas para Claude Code:

- **Ninguna pantalla se construye sin su ronda de kiwi aprobada** por el dueño.
- **El dominio no se inventa en la interfaz**: el `data_contract` de coco sale de
  este documento y del esquema, nunca de suposiciones para que un layout se vea
  completo.
- Si Fruti Squad y este documento chocan en una regla de negocio, gana este
  documento; en una regla de diseño, gana el perfil de lima.

**Identidad que va en el perfil** (intake de `setup`; formato exacto en
`skills/lima/reference/intake.md` del repo de Fruti Squad):

| Campo | Valor |
|---|---|
| `design_system_name` | PULZ |
| `color_law` | tinta `#173F87` solo para lo que importa (acciones primarias, títulos, barras); barro `#F2CFC2` para acentos, avisos suaves y fondos de icono; superficie `#FFFFFF` sobre lienzo `#F8F6F2`; texto `#18243A`; semánticos solo en estados: al día `#287A55`, pendiente `#C17A18`, atrasado `#B93A2E`, info `#2B6CB0` |
| `type_law` | "Atkinson Hyperlegible Next" con respaldo del sistema; base 16 px |
| `tokens_source` | `apps/web/src/shared/ui/tokens.css` (sembrar con `docs/referencia/pulz-tokens.css`, que trae tema claro y oscuro, radios, espacios y objetivo táctil de 44 px) |
| `framework` / `styling` / `icon_library` | `vue-ts` / CSS con variables / sprite propio `docs/referencia/pulz-iconos.svg` (`#i-maguey`, `#i-horno`, `#i-molienda`, `#i-tina`, `#i-destila`, `#i-lote`, `#i-medir` y otros) |
| `a11y_target` | WCAG 2.2 AA, más uso bajo el sol: contraste alto y objetivos de 44 px |
| `breakpoints` | 1440, 1024, 768, 390 |

---

## 14. Cobro y planes

- Tablas `plans`, `plan_limits` (una fila por límite; `null` = ilimitado),
  `plan_features`, `subscriptions`, `stripe_events`.
- Límites se imponen con **trigger** que toma `for update` sobre la empresa
  (serializa altas simultáneas) y falla con `LIMITE_PLAN:<clave>:<valor>`.
- `billing-checkout` y `billing-portal` crean sesiones de Stripe; el webhook
  verifica firma, es idempotente (`stripe_events.id`) y actualiza
  `subscriptions`.
- Estados: `gratis`, `prueba`, `activa`, `vencida` (solo lectura), `cancelada`.
- Valores de los límites y el precio: ver §18.

---

## 15. Pruebas y calidad

| Nivel | Herramienta | Qué cubre |
|---|---|---|
| Base | pgTAP (`supabase test db`) | Aislamiento (§11.3), cada RPC: camino feliz, idempotencia, cada regla dura, cada aviso blando, concurrencia con dos sesiones |
| Semilla | `supabase db reset` | La simulación de Cuatro Vientos carga sin errores y sus saldos finales coinciden con §15.1 |
| Unidad | Vitest | Funciones puras del front: cola offline, formateo, reglas de interfaz |
| Integración | Vitest contra Supabase local | Login por portal, alta de miembro, flujo completo de una corrida |
| E2E | Playwright | Portal → login → medición → corrida → granel, en 390 px y 1440 px |
| Portal | Vitest + Miniflare o wrangler | La función reescribe marca, redirige slug viejo, 404 idéntico |

### 15.1 Saldos esperados de la simulación

| Recurso | Lote | Volumen |
|---|---|---|
| Colector colas | COL-002 | 16 L |
| Tanque 1 | G-COMPRA-01 | 250 L |
| Tanque 2 | G-INI-01 | 341.8 L |
| Tina 1 | FER-T1-001 | 870 L |
| Tina 2 | FER-T2-001 | 1,400 L |
| Tina 3 | FER-T3-INI | 1,300 L |

CI (`.github/workflows/ci.yml`): levantar Supabase, `db reset`, pgTAP, Vitest,
build. Todo en verde para fusionar.

---

## 16. Plan por fases

Cada fase tiene criterios de aceptación **comprobables con un comando o una
prueba**. No se empieza la siguiente sin cerrar la anterior.

### Fase 0 · Arranque

- Monorepo pnpm, Vite + Vue + TS, ESLint, Prettier, Vitest, Supabase CLI,
  wrangler, CI mínimo. Crear `docs/ESTADO.md`, `docs/DUDAS.md`,
  `docs/DECISIONES.md`.
- Instalar Fruti Squad para Claude Code
  (`npx github:kevinedgm/fruti-squad setup --target claude`) con el intake de
  §13.4, y sembrar `tokens.css` y el sprite de iconos.
- **Acepta**: `pnpm install && pnpm build && pnpm test` en verde;
  `supabase start` responde; CI corre en un PR; existe el perfil PULZ de lima
  con los valores de §13.4 y el Design Hub inicial.

### Fase 1 · Base de datos

- Partir `pulz_esquema.sql` en migraciones ordenadas. Aplicar §10.2. Corregir lo
  que Postgres rechace sin cambiar la intención y registrarlo en DECISIONES.
- Adaptar la simulación a `seed.sql` + una segunda empresa mínima.
- pgTAP de aislamiento completo (§11.3).
- **Acepta**: `supabase db reset` sin errores; saldos de §15.1 exactos
  consultando `resource_lot_balances`; pgTAP de aislamiento en verde; no hay
  ninguna política `for all` (`select … from pg_policies where cmd = 'ALL'`
  devuelve cero filas); no hay columnas `json`/`jsonb` en tablas de `public`.

### Fase 2 · Comandos

- Cuerpos de todas las RPC de §12 con el contrato de §12.1.
- Reescribir la simulación para que se construya **llamando a las RPC**, no con
  inserts directos. Debe dar los mismos saldos.
- **Acepta**: pgTAP por RPC (feliz, idempotencia, duras, blandas); prueba de
  concurrencia: dos transferencias simultáneas del último litro → una pasa y la
  otra falla con `SALDO_INSUFICIENTE`; la simulación por RPC da §15.1.

### Fase 3 · Portal, acceso y equipo

- `portal_branding`, slugs con historial, `signup-company` (confirmación de
  correo del titular), `manage-member` (dictada y enlace de bienvenida),
  hook de intentos, `desbloquear_miembro`, pantallas de acceso, guardias del
  router, Pages Function del portal.
- **Acepta**: pruebas de integración de login por usuario y por correo; mensaje
  idéntico en los cuatro rechazos (empresa inexistente, usuario inexistente,
  contraseña mala, cuenta suspendida); 5 fallos bloquean y el admin desbloquea;
  slug renombrado redirige 301; empresa vencida entra en solo lectura; empresa
  cancelada da 404 idéntico; la función del portal pasa sus pruebas; el título
  del HTML servido en `/e/cuatro-vientos` es "Mezcal Cuatro Vientos · PULZ".

### Fase 4 · Interfaz base y configuración

- Cada pantalla pasa por kiwi → lima → coco (§13.4). Shell, navegación, tema, Configuración (recursos, catálogos, equipo,
  ajustes, portal y marca con subida de logo), primer arranque "¿qué tienes
  hoy?".
- **Acepta**: un dueño nuevo, desde cero, configura su palenque y registra una
  carga inicial en un tanque sin ayuda; cada pantalla tiene su ronda de kiwi
  aprobada y su auditoría de coco; mora las documentó en el Design Hub;
  capturas en 390/1024/1440 px, claro y oscuro, sin desbordes.

### Fase 5 · Captura por etapa y offline

- Maguey, horneado, formulación, fermentación con medición diaria (dos modos),
  destilación con cortes, granel con catálogo de movimientos. Cola offline para
  mediciones, cortes y fotos.
- **Acepta**: E2E del proceso completo de la simulación desde la interfaz;
  E2E offline: registrar 3 mediciones y 2 cortes en modo avión, reconectar, que
  lleguen una sola vez y en orden; los avisos blandos piden nota y quedan
  registrados.

### Fase 6 · Trazabilidad

- Árbol hacia atrás por lote, nivel de historia, completar historia, bitácora
  filtrable.
- **Acepta**: desde G-INI-01 de la simulación el árbol llega al maguey de
  "Loma del Toro" por la rama producida y muestra "sin historia" en la carga
  inicial; completar historia cambia el nivel correctamente.

### Fase 7 · Cobro

- Planes, límites por trigger, Stripe checkout, portal de cliente, webhook.
- **Acepta**: con `stripe listen`, pasar de gratis a Palenque y de vuelta;
  evento duplicado no cambia nada; superar un límite muestra el mensaje con el
  número; vencida → solo lectura.

### Fase 8 · Endurecimiento y lanzamiento

- Trigger genérico de auditoría a `audit_events`/`audit_changes`; prueba de
  carga básica (20 teléfonos midiendo a la vez); revisión de índices con
  `explain`; staging y producción; respaldo y restauración probados.
- **Acepta**: prueba de carga sin errores; restauración de un respaldo en
  staging; checklist de §11.3 ejecutado contra staging.

---

## 17. Qué tomar de la rama `saas` de `traker-palenque`

Es un SaaS multiempresa previo del mismo autor, con pruebas de integración
reales. **Úsalo como referencia de patrones**, no como base de código: su
modelo no permite entrada por cualquier etapa, no tiene compra de granel ni
carga inicial, sus balances de masa bloquean, y sus mezclas siempre crean folio
nuevo. Si tienes acceso al repositorio, consulta:

| Patrón | Dónde verlo |
|---|---|
| Llaves compuestas y convención de columnas | `docs/ARQUITECTURA_SAAS.md` (Convención de columnas) |
| Folios concurrentes con bloqueo de fila | `app.next_folio` en `supabase/migrations/0003_tenancy.sql` |
| Semillas copiadas por empresa | `app.seed_movement_types` en `0022_movements.sql` |
| Operaciones con folio y efectos que se anulan juntos | `0032`–`0037`, `movements.origin_entity` |
| Bloqueo de lotes en orden de id | `lock_bulk_lot()` en `0032_rectificacion_granel.sql` |
| Cuotas por trigger con `for update` | `0011_platform.sql` |
| Alcance de tinas por operador en filas | `app.member_tank_scopes` en `0005_catalogs.sql` |
| Manifiesto por empresa | `supabase/functions/company-manifest/manifest.ts` |
| Mapper snake/camel y errores tipados | `src/core/data/` |
| Lecciones de pruebas con Supabase local | `docs/ARQUITECTURA_SAAS.md` (Pruebas, Autenticación) |

Dos lecciones operativas de esa rama que ahorran horas:
- `[auth.email] enable_signup = false` apaga **todo** el correo (también los
  inicios de sesión). El control de registros es `enable_signup` de `[auth]`.
- Un usuario insertado a mano en `auth.users` necesita `confirmation_token`,
  `recovery_token`, `email_change_token_new` y `email_change` como cadena vacía,
  no `NULL`, o todo login falla con un 500 opaco.

---

## 18. Preguntas abiertas y supuestos

No bloquean el arranque. Implementar el supuesto y dejarlo configurable o fácil
de cambiar.

| # | Pregunta | Supuesto mientras tanto |
|---|---|---|
| 1 | Escala de actividad, dulzor y acidez: ¿1–10 (documento original) o 1–6 con etiquetas (rama saas, validada con Istmeño)? | 1–6 con etiquetas concordadas en género; cambiar los CHECK del esquema (hoy 1–10) y dejar la escala en una constante |
| 2 | Precio del plan Palenque | $299 MXN/mes, en la tabla `plans`, no en código |
| 3 | Límites del plan Gratis | 2 usuarios, 15 lotes activos, 4 tinas; en `plan_limits` |
| 4 | ¿El operador puede registrar recepción de maguey? | No (tabla §11.1); fácil de abrir |
| 5 | Rango "habitual" de % Alc. para avisar | 35–55 % en granel; ajuste de empresa |
| 6 | Rango de Brix inicial para avisar | 12–14; ajuste de empresa |
| 7 | ¿Vale la pena el folio del certificado del granel comprado? | Campo opcional |
| 8 | Dominio definitivo | `pulz.mx`; una constante de entorno |
| 9 | ¿El plan de Supabase incluye el hook de verificación de contraseña? | Implementarlo; si no está disponible, documentarlo y seguir |

---

## 19. Archivos del paquete

Descomprime el paquete dentro de `docs/` del repositorio nuevo: queda
`docs/PULZ_MAESTRO.md` y `docs/referencia/…`.

| Archivo | Qué es |
|---|---|
| `PULZ_MAESTRO.md` | Este documento |
| `referencia/pulz_esquema.sql` | Esquema v3 completo (aplicar §10.2) |
| `referencia/pulz_simulacion_semilla.sql` | Empresa ficticia completa, fila por fila |
| `referencia/pulz_portal_function.ts` | Pages Function del portal |
| `referencia/pulz_contrapropuesta.html` | Documento de diseño con diagramas y maqueta del portal |
| `referencia/pulz_simulacion.html` | La simulación, tabla por tabla, legible |
| `referencia/pulz-tokens.css` | Tokens de identidad PULZ, tema claro y oscuro |
| `referencia/pulz-iconos.svg` | Sprite de iconos del proceso |

### Prompt sugerido para arrancar Claude Code

```
Lee docs/PULZ_MAESTRO.md completo y los archivos de docs/referencia/.
Crea docs/ESTADO.md y docs/plan/FASE-0.md siguiendo la sección 0.1.
Muéstrame el plan de la Fase 0 y espera mi aprobación antes de implementar.
```
