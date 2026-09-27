# Profile — <PROJECT NAME>

<!--
  This is the profile template for the lima skill.
  A profile is the ONLY place project-specific facts live: design system,
  tokens, Design Hub location, registry path, production stack, QA harness.
  The skill core (SKILL.md + reference/*) never hardcodes any of this.

  HOW TO USE
  1. Copy this file to profiles/<your-project>.md (lowercase, dashed).
     e.g. profiles/acme-pulz.md
  2. Fill every field below by INSPECTING the repo (do not guess).
  3. Delete the fields that do not apply (e.g. runtime_qa if there is no
     browser QA harness yet) — but prefer scaffolding them (see scripts/).
  4. Confirm the finished profile with the user before designing anything.

  See reference/first-run.md for the full initialization playbook and
  scripts/init-project.sh for a bootstrap that generates this for you.
-->

```yaml
name:                 # Human name of the profile. e.g. "Acme / PULZ"
design_system:        # Name of the design system that is the visual truth. e.g. "PULZ"

truth_sources:        # Files that DEFINE tokens / visual law (real paths in this repo).
  # - path/to/tokens.(css|js|ts|json)     # design tokens (colors, spacing, radius, type)
  # - path/to/canonical-mockup.(html|fig) # a canonical reference of the intended look
  # - path/to/hub-stylesheet.css          # the Hub's shared stylesheet if any

color_law: >          # The system's color rules, briefly but unambiguously.
  # e.g. "canvas #FFF, ink #111. brand X ONLY for primary action.
  #       accent Y for focus/selection. danger Z ONLY for errors/destructive.
  #       If an element is neither action nor status, it is ink on surface.
  #       Shadow means elevation, never decoration."

type_law: >           # Typography rules.
  # e.g. "Font A across the system; Font B only for display/brand."

hub_root:             # Path to the Design Hub root (the laboratory). Created on first use if absent.
                      # e.g. "design-hub" or "docs/design-hub"
hub_layout:           # The folder taxonomy inside the Hub (list). Adapt to the project.
  # - Foundations/{Color,Type,Icons,Tokens}
  # - Components
  # - Patterns
  # - Responsive/{Mobile,Tablet,Desktop}

registry_path:        # Path to registry.json (persistent source of truth). Created on first use if absent.
                      # e.g. "design-hub/system/registry.json"

production:
  detect: true        # ALWAYS inspect the repo; never assume the stack.
  known_stack: >      # What the repo uses today, CONFIRMED by inspection. Framework, language,
                      # styling, icons, router, build tool. "Confirm by inspection each time."
  token_binding:      # How Hub tokens map to production tokens. e.g. "Map to tailwind.config.js; never hardcode values."
  component_layout:   # Where production components live + naming convention. e.g. "src/components/, match existing naming."

impeccable_path:      # Where the impeccable skill lives. impeccable is BUNDLED with this
                      # skill at vendor/impeccable, so init defaults this to the bundled
                      # copy (a repo-relative path). Override only to use a shared install.

runtime_qa:           # Optional. Delete this whole block if there is no browser QA yet.
  enabled: true
  runner:             # e.g. "playwright"
  harness_root:       # Folder that owns package.json / config / tests. e.g. "design-hub/qa"
  hub:
    start_command:    # Command to serve the Hub statically. e.g. "python3 -m http.server 4321 --directory ."
    base_url:         # e.g. "http://localhost:4321"
  tests_root:         # e.g. "design-hub/qa/tests"
  evidence_root:      # e.g. "design-hub/qa/evidence"
  viewports:          # Mandatory breakpoints to verify. e.g. [1440, 1024, 768, 390]
```

## Notes

<!--
  Record project-specific constraints the skill must always honor. Examples:
  - Accessibility target (e.g. "WCAG AA is a product requirement: contrast,
    visible focus, keyboard, touch targets >=44px, meaning never by color alone").
  - Anti-references: deprecated looks/fonts that must never be reintroduced.
  - Any domain rules that are input context (never design rules).
-->
