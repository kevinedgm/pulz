# Primer uso — inicializar la skill en un proyecto nuevo

Esta skill es agnóstica del proyecto. En un repo que nunca ha visto, **no hay perfil activo**, así que lo primero — antes de cualquier trabajo de diseño — es inicializar: producir un perfil relleno y scaffoldear las carpetas a las que apunta (Design Hub, registry, harness de QA). Todo lo específico del proyecto vive en ese perfil; el núcleo de la skill se mantiene universal.

## Cuándo corre esto

Dispara la inicialización cuando **cualquiera** de estas es cierta:

- `profiles/` no tiene perfil activo (solo `_TEMPLATE.md` y/o `examples/`).
- El usuario pide "configurar", "instalar", "inicializar" o "usar esto en un proyecto nuevo".
- El `hub_root` / `registry_path` del perfil activo aún no existen en disco.

Si ya existe un perfil activo válido y sus rutas resuelven, **omite el init** y diseña normalmente (ver [project-profile.md](project-profile.md) para la selección).

## Las dos formas de inicializar

Ambas producen el mismo resultado: un perfil confirmado + las carpetas scaffoldeadas.

### A. Guiada (conversacional) — por defecto cuando el usuario está presente

La skill **pide un conjunto fijo de datos en un formato específico** y los mapea directo al perfil — no ronda el repo esperando inferir un design system, y nunca inventa tokens. La inspección es solo un respaldo para los campos que el usuario marca `AUTO`.

1. **Presenta el formulario de intake** de [intake.md](intake.md) literalmente y pide al usuario rellenarlo. Cada campo tiene un formato estricto y un mapeo fijo al perfil.
2. **Valida cada campo** contra la tabla de formatos de intake.md. Si un valor no cumple, vuelve a pedir solo ese campo. Para los campos marcados `AUTO`, inspecciona el repo y luego **muestra lo que encontraste** y pide confirmación al usuario.
3. **Resuelve `NEW`** si el proyecto aún no tiene design system: corre el sub-flujo `NEW` de intake.md (propón un set mínimo de tokens/tipografía, confirma) — el único caso donde la skill origina verdad visual en vez de describirla.
4. **Escribe el perfil**: copia `profiles/_TEMPLATE.md` a `profiles/<project>.md` y rellena cada campo vía el *mapeo Campo → perfil* de intake.md (1:1, sin transformación extra).
5. **Scaffoldea** las rutas que declara el perfil (raíz del Hub + taxonomía, `system/registry.json`, harness de QA si está habilitado). El script en `scripts/` lo hace de forma determinista.
6. **Confirma el perfil terminado con el usuario** antes de diseñar.

La idea: el usuario aporta los datos una vez, en la forma exacta que la skill consume, así no hay nada que adivinar ni nada que derive.

### B. Por script (un comando) — lo más rápido, no interactivo

Dos variantes. Ver [../scripts/init-project.sh](../scripts/init-project.sh) y [../scripts/README.md](../scripts/README.md).

**B1 — desde un archivo de intake rellenado (recomendado): genera un perfil COMPLETO, sin editar.**
Rellena el intake (ver [intake.md](intake.md) y [../profiles/examples/intake.example.yaml](../profiles/examples/intake.example.yaml)), luego:

```bash
bash mis-agentes/skills/lima/scripts/init-project.sh \
  --intake my-intake.yaml --qa playwright
```

El script parsea el intake (sin dependencias) y escribe el perfil con color_law/type_law/truth_sources/stack/runtime_qa ya rellenos — tú solo lo confirmas.

**B2 — solo flags: genera un perfil con TODOs para rellenar a mano.**

```bash
# desde la raíz del repo, apuntando a la ubicación de la skill:
bash mis-agentes/skills/lima/scripts/init-project.sh \
  --name "Acme / PULZ" \
  --design-system "PULZ" \
  --hub "design-hub" \
  --qa playwright
```

`impeccable` viene incluido con la skill en `vendor/impeccable`, así que `--impeccable` es opcional; el script deja `impeccable_path` apuntando a esa copia embebida (relativa al repo). Pasa `--impeccable <ruta>` solo para apuntar a una instalación compartida.

El script:
- crea `profiles/<slug>.md` desde la plantilla (pre-rellenando name/design-system/hub/registry/impeccable/qa; impeccable por defecto al `vendor/impeccable` embebido),
- crea la raíz del Hub con sus carpetas de taxonomía,
- crea `<hub>/system/registry.json` como `{}` (registry vacío),
- si `--qa playwright`, scaffoldea `<hub>/qa/` con `package.json`, `playwright.config.js`, `tests/`, `evidence/`,
- imprime los comandos siguientes exactos (instalar deps de QA, servir el Hub) y los TODOs que aún necesitan input humano (color_law, type_law, truth_sources).

Nunca sobreescribe un perfil, Hub o registry existente — seguro de re-ejecutar.

## Qué "comandos de primera vez" corre el usuario

La secuencia concreta y copiable para un proyecto totalmente nuevo:

```bash
# 1. Arranca el perfil + Hub + registry (+ harness de QA opcional)
bash mis-agentes/skills/lima/scripts/init-project.sh \
  --name "<Project> / <System>" --design-system "<System>" \
  --hub "design-hub" --qa playwright   # impeccable incluido; --impeccable opcional

# 2. Rellena los campos que solo un humano da en el perfil generado
#    (color_law, type_law, truth_sources) — inspecciona tokens/mockups, no adivines.
$EDITOR mis-agentes/skills/lima/profiles/<slug>.md

# 3. (solo si --qa playwright) instala deps de QA + navegador, una vez
cd design-hub/qa && npm install && npx playwright install --with-deps chromium && cd -

# 4. Valida el scaffold
node -e "JSON.parse(require('fs').readFileSync('design-hub/system/registry.json','utf8')); console.log('registry OK')"
```

Después del paso 2 la skill tiene un perfil activo válido y puede diseñar. Los pasos 3–4 solo importan cuando llegues al QA runtime.

## Resultado de la inicialización

- `profiles/<project>.md` — la única fuente de verdad específica del proyecto, confirmada por el usuario.
- `<hub_root>/` — el laboratorio, con la taxonomía declarada.
- `<registry_path>` — un registry vacío `{}` (almacén de verdad; crece a medida que se diseñan piezas).
- opcional `<hub_root>/qa/` — el harness de QA runtime.

Desde aquí aplica el pipeline normal (SKILL.md): lee el perfil + registry primero, luego diseña → critique → distill → adapt → polish → candidate, y después harden → audit → stable.

## Reglas durante el init

- Inspecciona antes de escribir; nunca asumas un stack ni inventes tokens.
- Pregunta solo decisiones de producto, nunca detalles de diseño que puedas inferir.
- El perfil generado es un borrador hasta que el usuario lo confirme.
- El scaffolding es aditivo e idempotente — nunca destruye archivos existentes del proyecto.
- Si el repo ya tiene un design system, el perfil lo **describe**; la skill nunca reemplaza un sistema real por una invención propia.
