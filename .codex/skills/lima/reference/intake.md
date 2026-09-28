# Intake — los datos exactos que la skill pide en el primer uso

Antes de diseñar nada en un proyecto nuevo, la skill **pide un conjunto fijo de datos en un formato específico** y los mapea 1:1 al perfil. No rastrea el repo esperando inferir un design system, y no inventa tokens. La inspección es solo un respaldo para *pre-rellenar*; los valores autoritativos salen de lo que el usuario aporta aquí.

## Cómo usa esto la skill

1. En el primer uso (sin perfil activo), presenta el **Formulario de Intake** de abajo literalmente y pide al usuario rellenarlo.
2. El usuario lo pega ya relleno. Cada campo tiene un formato estricto (abajo); si un valor no cumple, vuelve a pedir solo ese campo.
3. Mapea cada campo al perfil con la tabla de [Mapeo Campo → perfil](#mapeo-campo--perfil). Ninguna transformación más allá de lo que dice el mapeo.
4. Solo para los campos que el usuario marca `AUTO` puede la skill inspeccionar el repo para rellenarlos — y debe mostrar lo que encontró para confirmar.
5. Nunca avances al diseño hasta que todos los campos REQUIRED estén presentes y confirmados.

## El Formulario de Intake (presentar esto literalmente)

```yaml
# === lima · project intake ===
# Rellena cada valor. Mantén las claves EXACTAMENTE como están escritas.
# Usa AUTO para que la skill inspeccione el repo y proponga un valor (te mostrará lo que encontró).

project_name:            # REQUIRED. Nombre humano. p. ej. "Acme Health"
design_system_name:      # REQUIRED. Nombre del sistema visual. p. ej. "PULZ". Si no existe, escribe NEW y la skill te ayuda a establecer uno mínimo.

# --- Ley visual (la única fuente de verdad visual) ---
color_law: |             # REQUIRED (o NEW). Una línea por regla. Nombra el rol, el hex y el ÚNICO uso.
  # surface  <hex>       # fondo de página
  # ink      <hex>       # texto por defecto
  # action   <hex>       # SOLO la acción primaria / estado activo
  # accent   <hex>       # foco, selección, énfasis secundario
  # danger   <hex>       # SOLO errores / destructivo
  # success  <hex>       # estado positivo (opcional)
  # rule: si un elemento no es acción ni estado, es ink sobre surface.
  # rule: la sombra indica elevación, nunca decoración.
type_law: |              # REQUIRED (o NEW).
  # body:    "<Font>"    # fuente usada en todo el sistema
  # display: "<Font>"    # opcional; solo para marca/títulos
  # scale:   <cómo escalan los tamaños, breve>
tokens_source:           # REQUIRED o AUTO. Ruta(s) al/los archivo(s) que DEFINEN los tokens.
  # - path/to/tailwind.config.(js|ts)   O  path/to/tokens.css  O  path/to/tokens.json
canonical_reference:     # OPTIONAL. Ruta/URL a un mockup canónico (html/figma) al que el diseño debe ajustarse. Vacío si no hay.

# --- Stack (destino de producción) ---
framework:               # REQUIRED o AUTO. p. ej. "vue3-ts" | "react-ts" | "svelte" | "angular" | "web-components"
styling:                 # REQUIRED o AUTO. p. ej. "tailwind" | "css-modules" | "scss" | "styled-components" | "vanilla-css"
icon_library:            # REQUIRED o AUTO. p. ej. "lucide" | "heroicons" | "material-symbols" | "custom-svg"
router:                  # OPTIONAL o AUTO. p. ej. "vue-router" | "react-router" | "none"
component_dir:           # REQUIRED o AUTO. Dónde viven los componentes de producción. p. ej. "src/components/"
naming_convention:       # OPTIONAL o AUTO. p. ej. "PascalCase SFC" | "kebab folder + index.ts"

# --- Design Hub (el laboratorio) ---
hub_root:                # OPTIONAL. Default "design-hub". Dónde se crea el Hub.
hub_language:            # OPTIONAL. Idioma de las etiquetas de sección. p. ej. "es" | "en". Default "en".

# --- Barras de calidad (los innegociables del proyecto) ---
a11y_target:             # REQUIRED. p. ej. "WCAG 2.2 AA" | "WCAG AA" | "none-stated"
breakpoints:             # REQUIRED. Los viewports en los que toda pieza debe verificarse. p. ej. [1440, 1024, 768, 390]
touch_min_px:            # OPTIONAL. Target táctil mínimo en móvil. Default 44.

# --- QA runtime ---
qa_runner:               # OPTIONAL. "playwright" | "none". Default "none".
serve_command:           # OPTIONAL o AUTO. Cómo servir el Hub estáticamente. Default "python3 -m http.server 4321 --directory ."

# --- Anti-referencias (nunca reintroducir) ---
anti_references:         # OPTIONAL. Estéticas/fuentes/colores explícitamente prohibidos. Vacío si no hay.
  # - <estética o fuente derogada>
```

## Formatos de campo (estrictos)

| Campo | Formato / valores permitidos | Si falta/es inválido |
|---|---|---|
| `project_name` | string no vacío | vuelve a pedir (REQUIRED) |
| `design_system_name` | string, o `NEW` | vuelve a pedir (REQUIRED) |
| `color_law` | bloque; cada rol = `name <hex>` donde `<hex>` es `#RGB`/`#RRGGBB`; los roles `surface`,`ink`,`action`,`danger` son obligatorios (o `NEW` para todo el bloque) | vuelve a pedir; si `NEW`, corre el sub-flujo de sistema mínimo |
| `type_law` | bloque con al menos `body: "<Font>"` (o `NEW`) | vuelve a pedir; si `NEW`, propón uno y confirma |
| `tokens_source` | lista de rutas reales del repo, o `AUTO` | si `AUTO`, inspecciona + muestra hallazgos para confirmar |
| `canonical_reference` | ruta del repo o URL, o vacío | continúa sin ella |
| `framework` | uno de los slugs listados, o `AUTO` | si `AUTO`, detecta desde `package.json`; si no es detectable, pregunta |
| `styling` | uno de los slugs listados, o `AUTO` | igual que arriba |
| `icon_library` | nombre de lib conocida o `custom-svg`, o `AUTO` | igual que arriba |
| `router` | router conocido o `none`, o `AUTO`/vacío | opcional |
| `component_dir` | ruta del repo, o `AUTO` | si `AUTO`, detecta la carpeta de componentes existente |
| `naming_convention` | texto libre, o `AUTO`/vacío | opcional |
| `hub_root` | ruta del repo; default `design-hub` | usa el default |
| `hub_language` | `es`/`en`/otro código ISO; default `en` | usa el default |
| `a11y_target` | string; se permite `none-stated` | vuelve a pedir (REQUIRED) |
| `breakpoints` | array JSON de enteros (px), preferible descendente | vuelve a pedir (REQUIRED) |
| `touch_min_px` | entero; default 44 | usa el default |
| `qa_runner` | `playwright`/`none`; default `none` | usa el default |
| `serve_command` | string de shell, o `AUTO`/vacío | usa el default |
| `anti_references` | lista de strings, o vacío | continúa sin ellas |

## Mapeo Campo → perfil

Cada campo del intake aterriza en exactamente un campo del perfil ([project-profile.md](project-profile.md) / [_TEMPLATE.md](../profiles/_TEMPLATE.md)):

| Campo del intake | Campo del perfil |
|---|---|
| `project_name` + `design_system_name` | `name` (`"<project_name> / <design_system_name>"`) |
| `design_system_name` | `design_system` |
| `tokens_source` (+ `canonical_reference`) | `truth_sources` |
| `color_law` | `color_law` |
| `type_law` | `type_law` |
| `hub_root` | `hub_root` |
| `hub_language` (+ defaults) | `hub_layout` (etiquetas de sección localizadas) |
| — (derivado de `hub_root`) | `registry_path` = `<hub_root>/system/registry.json` |
| `framework` + `styling` + `icon_library` + `router` | `production.known_stack` |
| `tokens_source` | `production.token_binding` (mapea tokens del Hub a este archivo; nunca hardcodees) |
| `component_dir` + `naming_convention` | `production.component_layout` |
| — (incluido) | `impeccable_path` = `vendor/impeccable` embebido (ver first-run.md) |
| `qa_runner` + `serve_command` + `breakpoints` | `runtime_qa.*` |
| `breakpoints` | `runtime_qa.viewports` |
| `a11y_target` + `touch_min_px` + `anti_references` | `Notes` del perfil |

## El sub-flujo `NEW` (aún no hay design system)

Si `design_system_name: NEW` o `color_law: NEW`/`type_law: NEW`, el proyecto no tiene sistema que describir. Entonces, y solo entonces, la skill ayuda a *establecer uno mínimo*: propone un set pequeño y defendible de tokens (surface/ink/action/accent/danger + una familia tipográfica + un paso de spacing/radius), lo muestra, y obtiene confirmación explícita antes de escribirlo en el perfil. Este es el único caso donde la skill origina verdad visual en vez de describirla — y siempre lo confirma el usuario.

## Arrancar el bootstrap desde un archivo de intake rellenado

El intake también puede ser un **archivo** que genera el perfil sin edición manual. Guarda el formulario relleno como YAML (ver [../profiles/examples/intake.example.yaml](../profiles/examples/intake.example.yaml)) y pásalo al script:

```bash
bash <skill>/scripts/init-project.sh --intake my-intake.yaml --qa playwright
```

El bootstrap lo parsea (sin dependencias, vía `scripts/parse_intake.py` — sin PyYAML), mapea cada campo con la tabla de arriba, y escribe un perfil **completo** (sin TODOs): name, truth_sources, `color_law`/`type_law` completos, frase de stack, token_binding, component_layout, runtime_qa y Notas (a11y target, touch min, anti-referencias). Los campos dejados como `AUTO`/vacíos caen a los defaults del script o a una nota de "confirmar por inspección".

## Por qué un intake fijo (no inspección libre)

- Los campos del perfil son el contrato real de la skill; pedirlos directo significa cero adivinanzas y cero deriva.
- `AUTO` deja que el repo responda las preguntas mecánicas (stack/rutas) mientras el humano posee las de juicio (color/tipografía/a11y).
- El resultado es reproducible: el mismo intake produce el mismo perfil, en cualquier proyecto — y un archivo de intake relleno lo hace totalmente no interactivo.
