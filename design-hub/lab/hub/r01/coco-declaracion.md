# coco · Declaración de cumplimiento — ronda hub/r01 (R3)

```text
Ruta: R3 (orden de lima: hub-shell, template) — no toca producción del producto
Brief funcional: el de kiwi (encargo de mora), vigente. Sin data_contract: la "entidad" es la ficha Markdown + su entrada en registry.json
Reglas aplicadas:
  · el sitio se GENERA (design-hub/scripts/build-hub.mjs, `marked`) desde README.md, Foundations/Components/Patterns/Screens/*.md y system/registry.json → design-hub/site/ (30 fichas + inicio + qa + 404); el HTML no se edita a mano
  · hoja propia design-hub/assets/hub-shell.css que consume tokens.css (copiado a site/assets/ en el build); clases hub-* mínimas; ningún CSS copiado de componentes del sistema
  · preview = demo real por iframe (Components/demo/index.html?pieza=<id>&solo=1) para componentes y patrones con demo; galería de capturas de qa/evidence/<ronda>/ para pantallas; "Abrir aparte" siempre
  · una sola jerarquía (Foundations · Components · Patterns · Screens · QA): sidebar 260 px ≥1024, botón «Menú» + drawer role=dialog <1024 (foco atrapado, Esc y scrim cierran, foco vuelve al botón); aria-current por URL (hub-navigation.js, sin dependencias)
  · header de ficha desde el registry (tipo, estado, versión, owner, ronda, actualización); chip de madurez por texto + forma (hub-mad--draft|candidate|stable|deprecated); tabla de facetas de QA al final; «En esta página» derivado de los h2 reales
  · deprecated: fuera de la navegación con aviso «Reemplazada por…»; 404 propio; enlaces .md → .html; rutas al repo → enlaces al código
  · targets: sidebar 36 px (excepción declarada, mínimo WCAG 24), TOC 24, Menú/Cerrar/botones 44; foco visible 3 px; prefers-reduced-motion; modo oscuro por tokens
Excepciones: ninguna respecto a la ronda; búsqueda global fuera (Could)
Comprobado:
  · `pnpm build:hub-site` → "Hub generado: 30 fichas + inicio + qa + 404" (con `marked` 18 en la raíz)
  · `node design-hub/qa/enlaces-hub.mjs` → páginas 33 | enlaces/recursos rotos: 0
  · Playwright `qa/evidencia-hub.mjs` 8/8 ✔ (36 capturas en qa/evidence/hub-r01/): inicio, ficha de componente (iframe de la demo + facetas), ficha de pantalla (galería), qa, drawer <1024 con foco dentro / Esc / foco de vuelta; sin scroll horizontal en 1440/1024/768/390 × claro/oscuro; 0 errores JS
  · capturas revisadas a ojo: inicio 1440 claro, button 1440 claro, arranque 390 oscuro
  · wireframe de kiwi (índice) revalidado tras los ajustes de la construcción: 84 combinaciones · 0 hallazgos · 0 errores JS
Auditoría arquitectónica (manual):
  · build-hub.mjs: un renderer de marked con reescritura de enlaces + plantilla de página; lee el registry una vez; sin estado global aparte de las rutas. Health: sano. Finding LOW · NO_ACTION: el TOC solo toma h2 (decisión del estándar de mora).
  · hub-navigation.js: 55 líneas, sin dependencias, un solo listener de teclado mientras el drawer está abierto. Health: sano.
  · hub-shell.css: 500 líneas, solo clases hub-*, tokens por variable; `table{display:block;overflow-x:auto}` evita el desborde de las tablas de facetas en 390. Health: sano.
  · Findings:
    - LOW · NO_ACTION — el iframe de la demo no adapta su alto al contenido (420/360/480 px por rango, con scroll interno); "Abrir aparte" cubre el caso.
    - INFO — el sitio generado se versiona (como Components/demo/) para que el Hub se pueda abrir sin construir; el build lo sobreescribe completo.
No pudo comprobarse: lector de pantalla; zoom nativo del navegador; el sitio en un servidor distinto de http.server (rutas relativas, debería dar igual).
Siguiente paso: mora valida contra su estándar y publica → lima registra hub-shell como candidate.
```
