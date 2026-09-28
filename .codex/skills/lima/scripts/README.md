# scripts — bootstrap de primera vez

Configuración determinista para usar la skill `lima` en un **proyecto nuevo**. El núcleo de la skill es agnóstico del proyecto; estos scripts generan lo específico del proyecto que la skill delega a un perfil (el archivo de perfil, el Design Hub, el registry y un harness de QA opcional).

Ver [../reference/first-run.md](../reference/first-run.md) para el playbook completo de inicialización y la alternativa guiada (conversacional).

## `init-project.sh`

Arranca un proyecto en un comando. Aditivo e idempotente — nunca sobreescribe un perfil, Hub o registry existente, así que es seguro re-ejecutarlo.

### Uso

Ejecuta desde la **raíz del repo** del proyecto destino:

```bash
bash <ruta-a-la-skill>/scripts/init-project.sh \
  --name "Acme / PULZ" \
  --design-system "PULZ" \
  --hub "design-hub" \
  --qa playwright
```

`impeccable` viene incluido dentro de la skill (`vendor/impeccable`), así que `--impeccable` es opcional y por defecto apunta a esa copia.

### Flags

| Flag | Default | Significado |
|---|---|---|
| `--name` | nombre de la carpeta actual | Nombre humano del perfil (también genera el slug del archivo de perfil). |
| `--design-system` | igual que `--name` | Nombre del design system que es la verdad visual. |
| `--hub` | `design-hub` | Ruta de la raíz del Design Hub a crear. |
| `--impeccable` | `vendor/impeccable` incluido | Ruta a la skill `impeccable`. Por defecto la copia embebida en esta skill (relativa al repo). Sobreescribe solo para una instalación compartida. |
| `--qa` | `none` | `playwright` scaffoldea un harness de QA en `<hub>/qa/`; `none` lo omite. |
| `--port` | `4321` | Puerto donde se sirve el Hub (usado en la config de QA + el perfil). |
| `--intake` | — | Ruta a un intake YAML rellenado (ver `../reference/intake.md` + `../profiles/examples/intake.example.yaml`). Genera un perfil **completo** (sin TODOs). Sobreescribe los flags individuales donde se solapan; otros flags ganan si se pasan explícitamente. |

### Desde un intake rellenado (perfil completo, sin editar)

```bash
bash <ruta-a-la-skill>/scripts/init-project.sh --intake my-intake.yaml --qa playwright
```

El intake lo parsea `parse_intake.py` (sin dependencias; necesita `python3`, sin PyYAML) y se mapea 1:1 al perfil. `name`, `truth_sources`, `color_law`, `type_law`, `production.*`, `runtime_qa.*` y las Notas de a11y/anti-referencias salen directo del archivo; los campos `AUTO`/vacíos caen a los defaults.

### Qué crea

- `profiles/<slug>.md` — desde `profiles/_TEMPLATE.md`, pre-rellenando los campos que la máquina conoce (name, design-system, hub, registry, impeccable, qa) y dejando los campos que solo un humano da como `TODO` (`color_law`, `type_law`, `truth_sources`, `production.*`).
- `<hub>/` con `Foundations/`, `Components/`, `Patterns/`, `Responsive/`, `system/`.
- `<hub>/system/registry.json` como `{}` (registry vacío).
- con `--qa playwright`: `<hub>/qa/` con `package.json`, `playwright.config.js` (los cuatro viewports obligatorios), `tests/`, `evidence/`.

### Después de ejecutar

1. Rellena los campos `TODO` del perfil generado (inspecciona tokens/mockups, no adivines).
2. Si usaste `--qa playwright`, instala las dependencias una vez:
   ```bash
   cd <hub>/qa && npm install && npx playwright install --with-deps chromium && cd -
   ```
3. Valida el registry:
   ```bash
   node -e "JSON.parse(require('fs').readFileSync('<hub>/system/registry.json','utf8')); console.log('registry OK')"
   ```
4. Confirma el perfil con el usuario, y empieza a diseñar.

## Notas

- El script solo scaffoldea; nunca inventa un design system. Si el repo ya tiene tokens/componentes, el perfil debe **describirlos**.
- El harness de QA asume `python3` (para servir el Hub estáticamente) y Node/npm (para Playwright). Ajusta `start_command` en el perfil si tu entorno difiere.
