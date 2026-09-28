# Declaración de cumplimiento · ARRANQUE · r01

| Campo | Valor |
|---|---|
| Ruta | R1 |
| Fidelidad | F2 |
| Pregunta de diseño | ¿Puede el dueño, el día uno y sin ayuda, dejar registrado lo que hay en cada recipiente (o marcarlo vacío) en menos de 5 minutos, sin inventar datos, y retomarlo si lo deja a medias? |
| Artefactos | `brief.md` (brief + flujo) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

`wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md`; WCAG 2.2 AA (targets, foco, errores con causa, texto 200 %); `registrar_entrada` (0015), `recurso_en_uso` (0025), `resources` (0006); shell/r01 y configuracion/r01 (capa de alta de recurso).

## Desviaciones del protocolo

Ninguna.

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 0 avisos.
- Chromium (Playwright): **33 combinaciones** (3 espacios × 11 estados): sin desborde, ≤1 primaria fuera de tarjetas (cada tarjeta con datos tiene la suya, por contrato), 0 targets <44 px, 0 errores JS.
- Estados: default (a medias) · carga · sin recipientes · errores (capacidad estricta, ciclo abierto, red) · sin permiso · sin conexión · solo lectura · contenido largo · todos decididos → Listo · agregar recipiente (capa) · ya arrancó.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Tarjetas de recipiente | una columna; Guardar a ancho completo dentro de la tarjeta | una columna | dos columnas | cada tarjeta es una decisión completa; en móvil no se compite por espacio | grid intrínseco | el estado de cada tarjeta vive en la tarjeta (y en localStorage) |
| Litros · % Alc. | apilados | en dos columnas | en dos columnas | números cortos | `ar-fila` | conserva valores al cambiar de tamaño |
| «Listo, ir a Inicio» | barra inferior persistente (solo cuando todos están decididos) | en el pie | en el pie | única primaria de la vista | `page-primary` | — |
| Agregar recipiente | capa = hoja | drawer | drawer | misma capa de Recursos | `task-layer` + `RecursoCapa` | foco vuelve |
| Progreso «n de t» | texto arriba | igual | igual | sin barra de % para conteos pequeños (antipatrón) | `role=status` | — |

## Comprobaciones NO ejecutadas

- Reanudación real tras cerrar el navegador (localStorage + `recurso_en_uso`): en coco.
- Aviso de capacidad con política flexible (`rpc_warn`): en coco contra el proyecto.
- Zoom nativo y lector de pantalla.

## Hallazgos

Ver `hallazgos.md`: 2 altos (irreversible sin modal → el botón dice qué hará; extraer `RecursoCapa`), 2 medios, 1 bajo.

## Traspaso

- **→ lima:** sin piezas nuevas del sistema. **Reutiliza:** `state-block`, `button`, `number-field`, `segmented-choice` (Vacío / Tiene algo), `status-chip` (guardado / vacío), `task-layer` + capa de Recursos, `banner`. **Local (product-application `arranque`):** `ArranquePage.vue`, `TarjetaRecipiente.vue` (local del módulo), estado en `localStorage pulz:arranque:<org>`. **Refactor en configuración:** `RecursoCapa.vue` extraída de `RecursosPage.vue` (mismo comportamiento) para usarla aquí.
- **Datos (`coco.data_contract`):** `Recipiente = Recurso` con `kind ∈ {tanque, tina, colector}` y `active`; `CargaInicial = { resource_id, idempotency_key (uuid del navegador), litros, abv? }` → `registrar_entrada(org, idem, now(), material(kind), resource_id, litros, abv, null, 'carga_inicial')`; `material(kind) = tanque→granel, tina→fermentado, colector→destilado`; estado derivado: `recurso_en_uso.saldo_l > 0 || ciclos_abiertos > 0` = guardado.
- **→ coco:** ruta `/e/:slug/arranque` (`meta.shell`, destino `inicio`, título «¿Qué tienes hoy?»); Inicio → «Empezar» apunta aquí (hoy va a Granel); Recursos enlaza «Registrar lo que hay». Evidencia real en Prueba B (dueña): crear Tanque B1, guardar 300 L @ 47, marcar Tina B1 vacía, Listo; `db reset` después.
- **→ mora:** nada hasta implementar.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) → lima → coco → mora.
