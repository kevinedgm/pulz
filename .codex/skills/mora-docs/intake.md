# Intake — los datos exactos que mora pide en el primer uso

mora cura el Design Hub de un proyecto. Inspecciona el repo para resolver datos mecánicos y pregunta únicamente decisiones que no puedan inferirse con seguridad.

mora comparte el perfil con `lima` y coco, así que el intake es: **el intake del architect, más un pequeño bloque `mora:`.**

## Cómo usa esto mora

1. En el primer uso en un repo, busca un perfil activo en `profiles/<project>.md` de Lima.
   - **Si existe**: reúsalo. Pide solo las adiciones `mora:` de abajo si faltan.
   - **Si no existe y la configuración debe persistir**: inspecciona el repo, completa rutas mecánicas y pregunta solo los campos de juicio que falten.
   - **Si el trabajo es acotado y el usuario ya dio el Hub**: registra supuestos y continúa sin bloquear por el perfil.
2. Valida cada campo. Los campos `AUTO` se resuelven inspeccionando el repo; confirma solo hallazgos ambiguos o de alto impacto.
3. Mapea todo al perfil (los campos del architect vía el mapeo de su `reference/intake.md`; los campos `mora:` vía la tabla de abajo).
4. Confirma el perfil antes de una reestructura global. Para reparaciones deterministas y acotadas, informa el supuesto y continúa.

## Los campos del architect (reusar literalmente)

Usa el formulario exacto de `lima/reference/intake.md`. mora se apoya específicamente en: `hub_root`, `hub_language`, `registry_path` (derivado), `component_dir` (→ `production.component_layout`), `breakpoints`, `a11y_target`. También se beneficia de `design_system_name`.

## Las adiciones de mora (presentar esto literalmente)

```yaml
# === mora · documentation additions (append to the project intake) ===
doc_standard:      # OPTIONAL. Ruta al spec del estándar de doc (orden de secciones + regla de honestidad).
                   # Vacío => mora usa su orden canónico interno.
                   # p. ej. ".../lima/reference/component-documentation.md"

doc_shell:         # REQUIRED (o AUTO). La(s) hoja(s)/script(s) del único shell activo.
                   # p. ej. ["design-hub/assets/hub-shell.css", "design-hub/assets/hub-navigation.js"]

serve_command:     # OPTIONAL o AUTO. Cómo servir el Hub estáticamente para validar.
                   # Vacío => "python3 -m http.server 4321 --directory ."

coverage_script:   # OPTIONAL. Check de censo de que todo componente está documentado. AUTO | vacío.
                   # p. ej. "python3 design-hub/lab/scripts/coverage.py"

hub_preview:       # OPTIONAL. Cómo la Preview viva embebe el componente REAL (iframe a un harness).
                   # Vacío => preview no disponible/no verificada; nunca se copia CSS como sustituto.
                   # p. ej. "iframe http://localhost:5175/qa/<component>?raw=1"
```

## Formatos de campo (estrictos)

| Campo | Formato / valores permitidos | Si falta/es inválido |
|---|---|---|
| `doc_standard` | ruta del repo, `AUTO`, o vacío | `AUTO` → detecta el estándar instalado de lima; vacío → orden canónico interno de secciones (declarado) |
| `doc_shell` | lista de rutas reales del repo, o `AUTO` | `AUTO` → detecta el shell css/js del Hub + muestra; si no encuentra ninguno, mora señala que las páginas no tienen shell que reutilizar |
| `serve_command` | string de shell, `AUTO`, o vacío | vacío → `python3 -m http.server` |
| `coverage_script` | comando de shell, `AUTO`, o vacío | `AUTO` → detecta; vacío → cobertura reportada `manual` |
| `hub_preview` | string que describe el embed del harness, o vacío | vacío → preview no disponible/no verificada; sin espejo de CSS |

Ejemplos neutrales del bloque completo: [examples/mora-block.example.md](examples/mora-block.example.md).

## Mapeo Campo → perfil (bloque mora)

Estos aterrizan bajo una clave `mora:` en el mismo `profiles/<project>.md`:

| Campo del intake | Campo del perfil |
|---|---|
| `doc_standard` | `mora.doc_standard` |
| `doc_shell` | `mora.doc_shell` |
| `serve_command` | `mora.serve_command` |
| `coverage_script` | `mora.coverage_script` |
| `hub_preview` | `mora.hub_preview` |

Ver [profile-additions.md](profile-additions.md) para cómo se consume cada campo en el protocolo.

## Por qué un intake fijo

- Los campos del perfil son el contrato persistente de mora; la inspección resuelve mecánica y el usuario conserva las decisiones de juicio.
- Compartir el perfil del architect significa que un proyecto se describe **una vez** y la skill de diseño, coco y mora leen todos la misma verdad.
- `AUTO` deja que el repo responda las preguntas mecánicas (shell/rutas) mientras el humano posee las de juicio (estándar de doc, estrategia de preview).
