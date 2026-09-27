# coco · Declaración de cumplimiento — ronda acceso/r01 (F3 + R3)

> Entrada: `brief.md`, `index.html` (F2), `declaracion.md` (kiwi, aprobada por
> el dueño el 2026-09-27) y `orden-coco.md` (lima). Salida: esta declaración,
> para la compuerta Candidate de lima. coco no cambia estados del registry.

```text
Ruta: R3 (implementación de la estructura aprobada) + F3 (demos con el sistema real en el Hub) + R0 propio sobre lo construido
Brief funcional: el de kiwi (brief.md), vigente; no se rehízo. data_contract registrado en el perfil (PortalBranding, MiMembresia, MiembroEquipo, reglas de presentación, NO reales)
Reglas aplicadas:
  · ley de color del perfil: acción = --ink-900; peligro = --late solo en Suspender y errores; estado por forma + texto (chip), nunca color solo
  · una primaria por vista (Entrar / Guardar contraseña / Crear contraseña y entrar / Agregar persona → Crear acceso dentro de la capa); en el vacío la de cabecera baja a secundaria
  · estados obligatorios: carga, vacío, error con reintento, sin permiso, sin conexión, solo lectura, texto largo, 0/null (—)
  · targets ≥ 44px (--tap), campos lg (52px) en acceso; foco visible 3px; reduced-motion en el spinner
  · etiqueta arriba del campo, validación al salir (blur), error con causa y solución, placeholder solo ejemplifica
  · adaptación real por rango: primaria persistente abajo <600; lista apilada ≤1023; drawer→hoja <600; menú→hoja <600 (misma instancia)
  · sin valores a mano: todo de tokens.css; un solo set de iconos (i-mas redibujado como "+"; ojo/⋯/copiar van con texto, decisión previa)
Excepciones:
  · "Solo admin" en Equipo no es guardia del router (orden de lima §66): la ronda de kiwi tiene el estado "Sin permiso" y un guardia lo haría inalcanzable. La página lo muestra; la base rechaza igual. Inicio solo enseña "Equipo" al admin.
  · Bienvenida no deja a la persona dentro (§7.3 "elige su contraseña y entra"): set-password no abre sesión. Se muestra "Listo…" + "Ir a entrar". Registrado en docs/DUDAS.md #11 con propuesta; el botón conserva el texto de kiwi.
  · Sin conexión / solo lectura no se pudieron ver con datos reales (la semilla no tiene empresa vencida ni se simuló offline en Playwright): verificados en el Hub y por prueba de componente.
Comprobado:
  · vue-tsc -b ✔ · eslint 0 errores 0 avisos ✔ · prettier ✔ · vite build ✔ · build:hub ✔
  · Vitest 33/33 ✔ (16 contrato de UI · 9 errores/rechazo único · 2 correoDeAcceso · 5 integración REAL contra el proyecto alojado · 1 existente)
  · Playwright (design-hub/qa/evidencia-acceso.mjs) 8/8 corridas ✔: 1440/1024/768/390 × claro/oscuro, 13 pantallas/estados, 104 capturas en design-hub/qa/evidence/acceso-r01/. Asserts: rechazo único y contraseña limpiada; slug viejo → actual; 404 idéntico; privada sin sesión → portal; dictada → cambio obligatorio (aun pidiendo /inicio); titular → inicio → equipo; menú por fila; alta en capa con confirmación de descarte; productora sin enlace Equipo y con estado "Sin permiso"; sin scroll horizontal; 0 errores JS
  · Navegador en vivo (pane): submit por formulario, Esc devuelve el foco al botón de fila, foco entra a la capa, label↔input ligados
  · pgTAP equipo_miembros 12/12 (commit 4d84bfd)
Auditoría arquitectónica (manual, el perfil no declara audit_component):
  · shared/ui = UI primitives: sin dominio, sin endpoints, API por intención (intent/adapt/variante), tokens del sistema. Component Health: sano.
  · modules/acceso, modules/equipo = feature/page: conocen su dominio (api.ts por módulo, store Pinia solo en acceso), la presentación deriva del contrato (esTitular, enlaceVigente, estaBloqueado en equipo/api.ts, no en el template). Health: sano.
  · Findings:
    - MEDIUM · REVIEW_REQUIRED · high — EquipoPage.vue ~560 líneas (lista + 4 capas: alta, creado, rol, confirmación). Funciona y respeta el contrato; si crece una capa más, extraer `AltaPersonaCapa.vue`. No se hizo: no reduce acoplamiento hoy.
    - LOW · NO_ACTION · high — el 404 se implementa dos veces (ruta con slug y global) a propósito: el mismo componente, sin lógica duplicada.
    - INFO · RECOMMENDATION · medium — `confirm()` nativo para descartar el alta; kiwi pedía "confirmación corta". Válido y accesible; si se quiere estilo propio, es una pieza nueva del registry (dialog), no un parche.
  · Defectos corregidos durante la verificación (todos con prueba de regresión): atributos no heredados en Boton (form → "Entrar" no enviaba), href indefinido pisando RouterLink, aria-describedby colgante, CapaTarea sin foco si nace abierta, bloque estirado en compact, "Acciones · Acciones", icono i-mas como menú.
Cobertura de doc: el registry (lima) ya censa las 14 piezas como draft; las demos F3 viven en design-hub/Components/demo (build desde el código real). Páginas del Hub por pieza: mora. coco no tocó registry.json.
No pudo comprobarse:
  · "5 fallos bloquean y el admin desbloquea": el hook no está en el plan (DUDAS #9). "Desbloquear" existe en el menú y llama a manage-member, pero nunca aparece con la semilla.
  · Alta real por manage-member desde la pantalla (crea usuarios en el proyecto alojado): se probó el formulario hasta "Crear acceso" sin enviar; la función ya tiene smoke por curl (13 casos, commit 83d4a3c).
  · Recuperación por correo del titular (manda un correo real).
  · Web Share ("Compartir…") y clipboard: dependen del navegador; el botón se oculta si la API no existe.
  · Forced-colors / zoom 200 %: no se automatizó.
Siguiente paso del usuario: revisar design-hub/qa/evidence/acceso-r01/ y las pantallas en el dev server; decidir DUDAS #11; si conforme, lima evalúa la compuerta Candidate y luego mora documenta.
```
