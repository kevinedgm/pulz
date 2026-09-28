# Orden de construcción para coco · arranque/r01 · lima · 2026-09-27

Estructura congelada en `brief.md`, `index.html`, `declaracion.md`,
`hallazgos.md`. Sin piezas nuevas del sistema.

1. **Refactor previo (sin cambiar comportamiento):** extraer
   `apps/web/src/modules/configuracion/components/RecursoCapa.vue` de
   `RecursosPage.vue` (formulario de alta/edición + validación + guardado);
   `RecursosPage` la consume igual; `ArranquePage` la consume con
   `kinds` limitados a tanque/tina/colector.
2. **`modules/arranque/`**: `routes.ts` (`/e/:slug/arranque`, `meta:
   { shell: true, destino: "inicio", titulo: "¿Qué tienes hoy?" }`),
   `api.ts` (`cargaInicial(org, idem, kind, resourceId, litros, abv?)` →
   `rpc('registrar_entrada', { p_org, p_idem, p_fecha: now, p_material,
   p_recurso, p_cantidad, p_abv, p_origen: 'carga_inicial' })`; traducción
   de `CAPACIDAD:` y `NO_PERMITIDO:` a texto), `pages/ArranquePage.vue`,
   `components/TarjetaRecipiente.vue`.
3. Estado local: `localStorage pulz:arranque:<org>` = `{ [resource_id]:
   { idem, vacio: boolean } }`; guardado se deriva de `recurso_en_uso`.
4. Inicio: «Empezar» → `/e/:slug/arranque`. Recursos: enlace «Registrar lo
   que hay» → arranque.
5. Verificación: Vitest (TarjetaRecipiente: segmento, campos por kind,
   texto del botón con cantidad y recipiente, disabled sin señal), Playwright
   `qa/evidencia-arranque.mjs` con la dueña de Prueba B: crear Tanque B1
   (capa), guardar 300 L @ 47 (real), Tina B1 vacía, ver «Listo», Inicio sin
   «¿Qué tienes hoy?»; 4 anchos × 2 temas; zoom 200 %. `db reset --linked`
   al cerrar la fase.
