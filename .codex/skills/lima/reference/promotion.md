# Promotion — stable contract → production component (orchestration)

Production consumes only stabilized, approved contracts. Promotion is a separate, explicit, user-approved step. Never modify production automatically.

> Promoting is not copying the Design Hub HTML into a framework file. It is translating a stable visual + interaction contract into a reusable component API of the real stack.

This file **orchestrates** promotion. The API-design rules (props, slots, emits, types, composition, controlled state, polymorphism, adaptive API, component boundaries, anti-patterns) are owned by [component-api.md](component-api.md) and are not restated here.

## Promotion pipeline

```text
1. Verify stable status          (status=stable, qa.stable=true)
2. Require explicit production approval
3. Inspect project / profile     (real stack, conventions — never assume)
4. Read the stable UI contract   (the source of everything produced)
5. Design the component API      → component-api.md
6. API Review                    → component-api.md (checkpoint)
7. Implement in the real framework
8. Run production component QA    → runtime-qa.md (against the built component)
9. Record the production artifact in the registry
```

## 1–2. Preconditions

- Piece is `stable` (`qa.stable=true`) and all `dependencies` are stable (registry.md) — otherwise stop and report.
- User explicitly asked to promote to production. Production is never modified automatically.

## 3. Inspect the real stack (never assume)

Read `package.json`, framework configs, existing component conventions, styling system, router, icon system, test conventions, component paths, naming. The profile's `production.known_stack` is a hint (here Vue 3 `<script setup lang="ts">` + Tailwind + lucide + Vue Router), always confirmed by inspection so the skill also works in React, plain HTML/CSS, etc. All concrete specifics come from the profile, not from this file.

## 4. Read the stable contract

Everything produced derives from the stable contract (intents, sizes, states, behaviors, adaptive rules, a11y). Production must not invent new variants — if a genuine new need appears, stop and return to the Design System lifecycle (candidate → stable) before resuming (see component-api.md).

## 5–6. Design the API + review

Design the component API per [component-api.md](component-api.md) and run its API Review checkpoint before writing implementation. A family sharing a contract (e.g. Button / IconButton / MenuButton / SplitButton) is preferred over one component with many boolean flags; the architecture is decided here by inspecting the real frontend, not prescribed in advance.

## 7. Implement

Translate the reviewed API into the real stack and conventions. Bind tokens per the profile's `token_binding` (map the design system's tokens to the project's token system); never hardcode values. Preserve every variant, size, state, behavior, adaptive rule, and a11y guarantee from the stable contract. Follow the profile's `component_layout` for location and naming.

## 8. Production component QA

Run [runtime-qa.md](runtime-qa.md) against the **built component** (not just the Hub demo): keyboard, focus, async, menus, sheet, split, disclosure, destructive flows, responsive, touch, zoom — verified on the framework output, with evidence classified honestly.

## 9. Record it

Update the registry: set `production` to `{framework, path}` (or the API surface for a family), keep `status: stable`, bump `version` if the contract changed. The Hub demo stays canonical; production is a faithful implementation of the stable contract expressed as the API.

## Deprecation

When a piece replaces an older one, set the old piece `deprecated` with `replacedBy`, warn about dependents, and keep the old demo reachable for migration.
