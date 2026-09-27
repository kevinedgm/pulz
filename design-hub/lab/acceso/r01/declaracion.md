# Declaración de cumplimiento · Acceso · r01

| Campo | Valor |
|---|---|
| Ruta | R1 (una dirección estructural) |
| Fidelidad | F2 (mid-fi: contenido real, estados, responsive; sin sistema visual) |
| Pregunta de diseño | ¿Puede cualquier persona del palenque entrar en <20 s con un solo campo, sin saber qué es un correo sintético, y puede el administrador dar acceso en un solo paso eligiendo entre dictar o mandar enlace? |
| Artefactos | `brief.md` (brief + 3 user flows) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

- kiwi: `references/brief-funcional.md`, `user-flow.md`, `fidelidad.md`, `wireframing.md`, `hig-web-pwa.md`, `validacion.md`; `assets/wireframe-kit.css`, `assets/wireframe-base.html`; `scripts/check_artifact.py`.
- WCAG 2.2 AA (perfil de lima: contraste alto por uso bajo el sol, foco visible, teclado, targets ≥ 44 px, no depender del color).
- Proyecto: `docs/PULZ_MAESTRO.md` §7, §11.1, §13.1–§13.3, §16 Fase 3; esquema y funciones reales (ver fuentes en `brief.md`); perfil `.claude/skills/lima/profiles/pulz.md` (breakpoints 1440 / 768 / 390 como espacios de referencia).

## Desviaciones del protocolo

- El kit se incluyó **inline** en `index.html` (copia idéntica en `vendor/`) porque el visor del entorno abre los archivos como instantánea `data:` y no resuelve hojas relativas; el kit lo permite.
- Se añadieron 4 reglas CSS locales, todas en grises y estructurales: corrección de contraste de la primaria (defecto del kit, ver hallazgos), apilado de la lista de equipo en medium, hoja inferior en compact para el drawer, y la tarjeta centrada de 440 px de las pantallas sin sesión.

## Comprobaciones ejecutadas

- `check_artifact.py index.html --fidelidad F2`: **✔ 0 errores · 0 avisos** (lang, viewport, título, etiquetas balanceadas, solo grises, una familia, panel de estados, notas).
- Navegador (motor del panel de vista previa, archivo abierto suelto): recorrido automático de **156 combinaciones** (4 pantallas × 3 espacios 1440/768/390 × 13 estados): **0 desbordes horizontales** del marco y **≤ 1 acción primaria visible** en cada una (incluida la barra inferior persistente de compact). Errores JS en consola: **0**.
- Revisión visual en capturas: compact 390 · portal default (marca, un campo, contraseña con mostrar/ocultar, primaria en barra inferior legible tras la corrección de contraste); compact 390 · equipo "agregar persona" (hoja inferior sobre scrim, misma instancia del formulario); expanded 1440 · equipo con menú de fila (menú lateral, ruta, una primaria, tabla).
- Teclado/foco: declarado en el artefacto (Esc/atrás cierran drawer y hoja y devuelven el foco a "Agregar persona"; en compact la primaria persistente está en el orden de tabulación al final del formulario). No se ejecutó recorrido de tabulación real (ver abajo).
- Estados representados en el panel: carga · vacío · error (rechazo y red) · sin permiso · sin conexión · contenido largo · solo lectura (vencida) · 404 genérico · alta · acceso creado (enlace) · acceso creado (dictada) · acciones de una fila.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Marca del portal | Logo 56 + nombre a 2 líneas con elipsis + mensaje completo | Igual, tarjeta centrada 440 | Igual | Deferencia al contenido: la marca es lo primero que se ve sin sesión | CSS intrínseco (line-clamp) | — |
| Formulario de acceso (portal, cambio, bienvenida) | Una columna, ancho completo, campos 52 px | Tarjeta 440 centrada | Tarjeta 440 centrada | Una mano y sol: campos grandes, nada a los lados | Container query del kit | Conserva valores y foco al cambiar de tamaño (misma instancia) |
| Acción primaria | Barra inferior persistente (área segura + teclado virtual) | En el formulario | En el formulario | Alcance del pulgar | `[data-wf-persist]` + `.wf-bottom` del kit | Una sola primaria por vista, siempre |
| Banner (sin conexión / solo lectura) | Arriba del contenido, persistente | Igual | Igual | Estado explícito mientras dure | — | — |
| 404 genérico | Pantalla completa sin marca | Igual | Igual | No revelar nada (§7.4) | — | — |
| Navegación de la app (Equipo) | Sin menú lateral (navegación inferior: otra ronda) | Menú lateral 200 | Menú lateral 240 | Menú por destinos (§13.1) | Kit | Ruta "Configuración / Equipo" siempre visible |
| Lista de equipo | Apilada: una tarjeta por persona con rótulos | **Apilada** (la tabla de 5 columnas no cabe con el menú) | Tabla de 5 columnas | Legibilidad; cero desborde | Container query local ≤1023 | Menú de fila abre bajo la fila en todos |
| Agregar persona | Hoja inferior (92 % alto) sobre scrim | Drawer derecho 420 | Drawer derecho 420 | Contexto de la lista visible detrás | Misma instancia del formulario; solo cambia la capa | Esc/atrás cierra; foco vuelve al disparador; con cambios pregunta antes |
| Acceso creado (enlace / dictada) | Hoja inferior | Drawer | Drawer | Continuidad con la alta | Igual | "Copiar" con feedback ≥ 3 s |
| Buscar (equipo) | Campo bajo la primaria, ancho completo | Junto a la primaria | Junto a la primaria | Solo útil con listas grandes | — | — |

## Comprobaciones NO ejecutadas

- **Recorrido real de teclado** (orden de tabulación, Esc en hoja/drawer): el artefacto lo declara en notas; se comprueba en R3 sobre la implementación (coco).
- **Texto ampliado al 200 %** y **zoom del navegador**: no se ejecutó en el panel de vista previa; la maqueta usa unidades relativas y una columna en compact, pero no está medido.
- **Lectores de pantalla**: solo semántica declarada (labels, `role="dialog"`, `aria-modal`, `role="alert"`, `aria-haspopup`); no se probó con VoiceOver/NVDA.
- **Contraste de la marca real** (color de la empresa sobre fondo): no aplica en F2; lo audita coco con los tokens reales (`portal_branding.brand_color` es libre por empresa → riesgo a resolver en F3: fondo neutro y color solo en acentos).
- **Dispositivos reales**: los 390/768/1440 son espacios de referencia del perfil, no equivalentes de dispositivos.

## Hallazgos

Ver `hallazgos.md` (2 altos: datos de bloqueo/vigencia no legibles por el admin; hook no disponible en el plan · 3 medios · 4 bajos).

## Traspaso

- **→ lima** (cuando el dueño apruebe la estructura): piezas y clasificación propuesta — `campo de texto` (primitive, candidato a reutilizar), `campo de contraseña con mostrar/ocultar` (primitive nuevo), `botón primario / secundario / silencioso / destructivo` (primitives, candidatos), `banner de estado` (pattern), `estado vacío / error / sin permiso` (pattern), `bloque de marca del portal` (product-application), `formulario de acceso` (product-application), `lista de personas con menú de fila` (pattern candidato: lista + acciones), `drawer/hoja de alta` (pattern: capa de tarea acotada), `segmento de dos/tres opciones` (primitive: rol, entrega). Estados que cada pieza debe soportar: los del panel. Matriz de adaptación: arriba.
- **→ coco** (propuesta para `data_contract`, coco la registra): `portal_branding` {name, logo_path, brand_color, welcome_message, read_only, redirect_to}; `mis_membresias` {slug, name, brand_color, logo_path, role, status, username, must_change_password, read_only, cancelled}; equipo: `organization_members` × `profiles.full_name` + **propuesta** `equipo_miembros` con `locked_until`, `invitacion_vence`; acciones `manage-member` {alta(username, nombre, rol, modo, contrasena?) → enlace?, rol, estado, desbloquear, reenviar}; `set-password` {contrasena, token?}; `signInWithPassword` con correo real o sintético. Errores con texto único: rechazo de login, enlace inválido. Guardias del router: `must_change_password` → cambio obligatorio; `read_only` → sin escritura; slug ∉ membresías → 404.
- **→ mora**: nada hasta que exista implementación verificada.

## Criterios observables para la aprobación

Sin desbordamiento en los tres espacios (comprobado en 156 combinaciones) · navegación comprensible (ruta visible en Equipo; portal sin cromo) · la misma tarea se completa en cada modo (entrar; fijar contraseña; agregar persona y entregar acceso) · foco conservado al cambiar de tamaño (misma instancia) · semántica declarada · targets ≥ 44 px (kit) · sin dependencia del color (estados por forma + texto) · movimiento reducido: no hay animaciones en F2.

## Siguiente paso del usuario

**Aprobar la estructura → pasa a lima** (clasificación y contrato) y de ahí a coco (F3 con el sistema PULZ, R3 en `apps/web/src/modules/acceso/`). O pedir cambios → se abre `r02`; nunca se sobrescribe esta ronda.
