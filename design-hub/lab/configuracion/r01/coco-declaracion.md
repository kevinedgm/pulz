# coco · Declaración de cumplimiento — ronda configuracion/r01 (F3 + R3)

```text
Ruta: R3 + F3 (demos de las 6 piezas en el Hub) + base (0025 recurso_en_uso)
Brief funcional: el de kiwi, vigente. data_contract: Recurso, ElementoCatalogo, Concepto, Especie, Predio, Proveedor, Insumo, Ajustes, Marca, RecursoEnUso (modules/configuracion/api.ts); sin campos nuevos en la base salvo la función de lectura 0025
Reglas aplicadas:
  · nunca borrar: active=false (desactivar / ocultar), reactivar / mostrar; DELETE ni siquiera concedido
  · una capa por tabla real (RecursoCapa dentro de RecursosPage; capa por catálogo dentro de CatalogosPage con campos por tabla); errores del esquema (unique, CHECK, trigger, slug, bucket) traducidos bajo el campo (mensajeDeError)
  · solo admin (SoloAdmin: denied por URL; banners offline/readonly; primaria deshabilitada con motivo; sin menú de fila)
  · una primaria por vista (page-primary en compact; en vacío vive en el bloque); capas con task-layer (drawer/hoja), confirmaciones cortas
  · select nativo para 4+ opciones; segmento para ≤3; switch role=switch con texto; number-field con unidad; color-field solo acento; file-picker valida como el bucket
  · recorte del logo con canvas (cuadrado centrado, 512, png o webp), subida a branding/<org>/logo.<ext> con upsert; el portal lo publica al instante
  · cambio de enlace: update slug (trigger + historial) → router.replace al nuevo → el viejo redirige (probado ida y vuelta)
  · brand-block: la misma pieza en el portal y en la vista previa (MarcaPortal eliminado)
Excepciones:
  · el recorte del logo usa el centro y no permite arrastrar (kiwi dibujó "arrastra para encuadrar"); con canvas sin librería, el encuadre manual es una ronda aparte si el dueño lo pide
  · fotos con orientación EXIF pueden salir rotadas (no se corrige); declarado en la ficha
Comprobado:
  · pgTAP configuracion.test.sql 37/37 ✔ (33 previos + 4 de recurso_en_uso: saldo, ciclos, una fila por recurso, otra empresa no ve)
  · vue-tsc ✔ · eslint 0/0 ✔ · prettier ✔ · vite build ✔ · build:hub ✔ (6 secciones nuevas)
  · Vitest 47/47 ✔ (7 nuevos de contrato: select, number-field, switch, color-field, file-picker ×2, brand-block)
  · Playwright qa/evidencia-configuracion.mjs 8/8 ✔ (4 anchos × 2 temas; 67 capturas). En 1440/claro escrituras REALES deshechas: alta "Tanque QA" (250 L) y desactivación; aviso "tiene 341.8 L dentro" en Tanque 2 (recurso_en_uso real); "Especie QA" creada y ocultada; ajustes: error mín/máx al salir, guardado ida y vuelta; logo real (pwa-192) recortado y subido a Storage y retirado; enlace → cuatro-vientos-qa → cuatro-vientos (trigger + historial + router)
  · zoom 200 % aproximado (qa/zoom-acceso.mjs) 16/16 ✔: portal, inicio, equipo, alta, recursos, ajustes, portal y marca, Hub a 1440 y 390
Auditoría arquitectónica (manual):
  · 6 primitives sin dominio; SoloAdmin = composición local (permiso + ruta + banners); api.ts concentra PostgREST/Storage y la traducción de errores; páginas conocen su tabla. Health: sano.
  · Findings:
    - MEDIUM · REVIEW_REQUIRED · high — CatalogosPage (~330 líneas) maneja 14 catálogos con un formulario por tabla dentro de una página: funciona; si crece, extraer `CatalogoCapa.vue` por tabla. No se hizo.
    - LOW · fixed — Prettier + manejador inline multi-sentencia rompió la compilación (Vite 500 sin error de tipos): regla → manejadores con más de una sentencia van a un método.
    - LOW · fixed — RecursosPage cargaba los 6 catálogos de tipo siempre (`|| true`): aceptable (≤40 filas) pero se anota.
    - INFO — "Tanque QA" y "Especie QA" quedan como inactivo/oculto en el proyecto de desarrollo hasta el siguiente db reset.
Cobertura de doc: fichas de 6 piezas + Screens/configuracion.md + README; registry por lima.
No pudo comprobarse: selects nativos y cámara en iOS/Android; EXIF; texto largo real; zoom nativo; forced-colors; harden/audit.
Siguiente paso: lima (compuerta) → mora publica → ronda arranque/r01.
```
