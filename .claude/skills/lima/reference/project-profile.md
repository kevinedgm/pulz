# Project profile — how the skill binds to a concrete project

The skill core is universal. Everything project-specific — design system, tokens, Hub layout, registry location, production stack — lives in a **profile** under `profiles/`. Load the active profile first, every session.

## Why

The same skill must work on Lustre+Vue here and on, say, PULZ+React elsewhere. Nothing in `reference/*` (except this file) may hardcode a color, path, or framework. When a reference needs a project fact, it reads it from the active profile.

## Selecting the active profile

Ignore `profiles/_TEMPLATE.md` (the template) and anything under `profiles/examples/` (reference examples) when detecting the active profile.

1. If exactly one active profile exists in `profiles/`, use it.
2. If several exist, choose by matching the current repo (its design system name / stack) and confirm with the user if ambiguous.
3. If none exists, **initialize** — create one from the template below by inspecting the repo (or run the bootstrap in [../scripts/init-project.sh](../scripts/init-project.sh)), and confirm it with the user before designing. Full playbook: [first-run.md](first-run.md).

## Profile template

The canonical, commented template is [../profiles/_TEMPLATE.md](../profiles/_TEMPLATE.md) — copy it to `profiles/<your-project>.md` and fill it. A profile must define:

```yaml
name:                # human name of the profile
design_system:       # name of the design system that is the visual truth
truth_sources:       # files that define tokens/visual law (paths)
  - ...
color_law:           # the system's color rules, briefly
type_law:            # typography rules
hub_root:            # path to the Design Hub root
hub_layout:          # the folder taxonomy inside the Hub
registry_path:       # path to registry.json
production:
  detect: true       # always inspect; never assume
  known_stack:       # what the repo uses today (confirmed by inspection)
  token_binding:     # how Hub tokens map to production tokens
  component_layout:  # where production components live + naming
impeccable_path:     # where the impeccable skill is installed
runtime_qa:          # optional: runner + harness_root + hub start/base_url + tests/evidence + viewports
```

## Which references consume the profile

- source-of-truth.md → truth sources, color/type law
- design-hub.md → hub_root, hub_layout
- registry.md → registry_path
- promotion.md → production.*
- impeccable-bridge.md → impeccable_path

Never restate these facts inside a reference; read them from the active profile.
