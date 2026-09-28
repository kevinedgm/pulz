# Hallazgos · HUB · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | Duplicar contenido (Markdown + HTML) derivaría en dos verdades | El sitio se **genera** desde las fichas Markdown + el registry (`marked`, script propio); el HTML no se edita a mano | mora (estándar) → coco (script) | `design-hub/scripts/build-hub.mjs` → `design-hub/site/` |
| Alta | La preview debe ser la demo real, no CSS copiado | `iframe` a `Components/demo/index.html?pieza=<id>&solo=1` (ya soportado por `DemoHub.vue`); las pantallas usan galería de capturas | coco | — |
| Media | `Responsive/{Mobile,Tablet,Desktop}` del perfil está vacío y duplicaría lo que cada ficha ya dice | Se retira de la navegación; se anota en el perfil (`hub_layout`) | lima | actualizar el perfil |
| Media | El shell del Hub necesita tokens pero no puede copiar el CSS de los componentes | Hoja propia `design-hub/assets/hub-shell.css` que consume `tokens.css` (copia sembrada) con clases mínimas (`hub-*`); chip de madurez con la misma convención de forma que `status-chip` pero clase propia | coco | — |
| Baja | Búsqueda global | Could; no entra | — | r02 si hace falta |
| Info | `hub_root` sirve desde la raíz del repo (`python3 -m http.server 4321`); el sitio vive en `design-hub/site/` y enlaza demo y evidencia con rutas relativas | supuesto declarado | coco | — |
