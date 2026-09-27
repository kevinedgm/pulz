# Profile — Manik / Lustre (EXAMPLE)

Example, filled-in profile from a real project (the ManikServicios repository: Lustre design system, Manik Design Hub, Vue 3 + Tailwind). It is **not** an active profile for any other repo — it lives under `profiles/examples/` as a reference of a complete profile. To start a project, copy `profiles/_TEMPLATE.md` to `profiles/<your-project>.md` and fill it by inspecting your repo (see `reference/first-run.md`).

```yaml
name: Manik / Lustre
design_system: Lustre
truth_sources:
  - docs/lustre-mockup.html          # canonical mockup
  - frontend/tailwind.config.js      # tokens
  - Manik Design Hub/lustre.css      # Hub stylesheet
color_law: >
  canvas #F2F1EE, paper #FFFFFF, ink #17150F.
  lima #D7FB3C ONLY for the booking action / active state.
  violeta #6B4CF6 for categories, verified, focus, accents.
  coral #FF5C4D ONLY for save/favorite. success #12805C. rating star #F5A524.
  If an element is neither action nor favorite, it is ink on paper.
  Shadow means elevation, never decoration.
type_law: >
  Instrument Sans across the system. Instrument Serif only for logo/brand
  and business names over photography.
hub_root: Manik Design Hub
hub_layout:
  - Design System/{Botones,Colores,Componentes,Estados,Iconos,Inputs,Tipografía}
  - Responsive/{Desktop,Tablet,Phone,Wide}
  - Patrones UX
  - Flujos
  - Wireframes
registry_path: Manik Design Hub/system/registry.json
production:
  detect: true
  known_stack: >
    Vue 3 <script setup lang="ts"> + TypeScript + TailwindCSS + PWA (Vite),
    icons via lucide-vue-next, no heavy UI framework. Confirm by inspection each time.
  token_binding: Map Lustre tokens to frontend/tailwind.config.js; never hardcode values.
  component_layout: frontend/src/components/ (+ packages/* for shared), match existing naming.
impeccable_path: .agents/skills/impeccable
runtime_qa:
  enabled: true
  runner: playwright
  harness_root: Manik Design Hub/qa       # owns package.json, playwright.config.js, tests/
  hub:
    start_command: "python3 -m http.server 4321 --directory ."   # from harness cwd; serves the Hub root
    base_url: "http://localhost:4321"
  tests_root: Manik Design Hub/qa/tests
  evidence_root: Manik Design Hub/qa/evidence
  viewports: [1440, 1024, 768, 390]
```

Notes:
- WCAG AA is a project requirement (PRODUCT.md): contrast, visible focus, keyboard, touch targets ≥44px on mobile, meaning never carried by color alone.
- Deprecated aesthetics (índigo/Manrope, sedas/Archivo, cobalt marketplace/Inter) are anti-references; never reintroduce them.
