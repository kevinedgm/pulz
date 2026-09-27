# Component API — translating a stable contract into a framework API

Authoritative owner of how a stable Design System contract becomes a reusable component API. `promotion.md` orchestrates promotion and loads this file for the API-design stage; it must not restate these rules. This file is **framework-agnostic** — concrete syntax, types, router, styling, icons, paths, and naming come from the active profile (project-profile.md).

Three layers, three owners:

```text
ui-artifact-contract.md  → what the piece IS (design: anatomy, variants, states, a11y)
component-api.md         → how that piece is EXPRESSED as a reusable API   (this file)
promotion.md             → how it goes from stable to production           (orchestration)
```

## Central rule

> Promoting is not copying the Design Hub HTML into a framework file. Promoting is translating a stable visual + interaction contract into a reusable API of the real stack.

The API expresses **intent, behavior, state, content, composition** — never arbitrary styles. The consumer states what the action is; the Design System decides how it is painted.

```
✅ <Button intent="primary" :loading="saving">Guardar</Button>
❌ <Button color="#D7FB3C" radius="13" shadow="md" background="lime" rounded />
```

## Props — predictable contract variation

Use props for predictable slices of the stable contract: `intent`, `size`, `loading`, `disabled`, `selected`, `block`, `type`, `adapt`, and semantic brand flags like `book`.

Rule: **a visual variation does not automatically deserve a prop.** Reject APIs whose flag combinations let a consumer break the Design System — no `outlined`/`flat`/`ghost`/`rounded`/`elevated`/`bordered`/`shadow`, and no color/style props (`color`, `background`, `radius`). Color is resolved by `intent + context + state → token`.

## Slots — content and limited composition

`default`, `prepend`, `append`. Do not add a slot per internal anatomy detail; the stable anatomy stays owned by the Design System.

## Emits — consumer-relevant events only

`click`, `select`, `open`, `close`, as the component warrants. Never expose events for internal details the consumer should not manage.

## Separate components when anatomy/semantics change

If anatomy, interaction, or semantics change significantly, it is a separate composed component, not a boolean on the base.

```
✅ Button · IconButton · MenuButton · SplitButton
❌ <Button icon-only menu split />
```

## Shared internal contract

Components may share an internal contract (intents, sizes, states, adaptive rules, a11y rules); a base/primitive may exist internally without being public API.

## Controlled state — no business logic

UI components render and interact; they do not own business logic. `:loading`/`:success`/`:error` are driven by the page/composable. The component never decides when a request started or finished.

## Semantic polymorphism

Resolve the right element by intent: `href` → anchor, `to` → framework router link, otherwise a button. Preserve correct HTML semantics and accessibility — not an unconstrained `as: any`. Buttons must not be used for navigation.

## Responsive by intent, not breakpoint props

No `desktop-size`/`tablet-size`/`mobile-size`. Expose a semantic `adapt` (e.g. `default | page-primary | toolbar | inline`); the component + Design System resolve desktop/tablet/mobile from the stable adaptive rules.

## API derives from the stable contract — never invents variants

The API translates only what the stable contract defines. If the stable contract says Primary/Secondary/Quiet/Danger + a Book modifier, the API is:

```ts
intent?: 'primary' | 'secondary' | 'quiet' | 'danger'
book?: boolean
```

Production may **not** spontaneously add `ghost`/`gradient`/`premium`/`elevated`. If production discovers a genuine new need:

```text
stop → return to the Design System lifecycle (candidate → stable) → resume promotion
```

Production is never a back door to change the Design System.

## Types

When the stack supports types, produce closed unions for closed contract sets; avoid open strings.

```ts
export type ButtonIntent = 'primary' | 'secondary' | 'quiet' | 'danger';
export type ButtonSize   = 'sm' | 'md';
export type ButtonAdapt  = 'default' | 'page-primary' | 'toolbar' | 'inline';
```

## API Review (checkpoint before implementation)

```text
COMPONENT API DESIGN → API REVIEW → IMPLEMENTATION
```

Review checks: props express intent? redundant props? invalid boolean combinations? any behavior deserving its own component? slots limited to content? emits only useful events? state properly controlled? responsive encapsulated? semantics + a11y preserved? can the API grow without breaking consumers? No separate manual approval per API unless a **product decision** or a **deviation from the stable contract** appears — those return to the user / the lifecycle.

## Profile-provided specifics

This file stays universal. The active profile supplies: framework, component syntax, type system, router, styling, icon system, testing conventions, component paths, naming conventions. For the Manik/Lustre profile these resolve to Vue 3 `<script setup lang="ts">` + Tailwind + lucide-vue-next + Vue Router — but that belongs to the profile, not to this universal policy.
