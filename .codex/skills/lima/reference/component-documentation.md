# Component documentation — the Design Hub documentation standard

Authoritative owner of **how every Design System artifact is documented**. Not a gallery, not a static mockup: each artifact has one **canonical, living, Vuetify-style reference page**. `design-hub.md` owns building demos in the lab; this file owns the documentation standard every page must follow, so no page invents its own visual religion.

> **Golden rule.** Documentation describes **what actually exists** and states clearly **what does not yet exist**. It never documents aspired-to props, variants, or APIs as if they worked. A beautiful page claiming `loading`, `density`, `rounded`, `variant`, `elevation` all work while the real component laughs from another folder is a failure.

A page is complete only if it answers, without opening the source: what is it · when to use / not use · how it looks · what variants exist · what states · how it behaves · how it responds on mobile · how to use it correctly · what API it has · how validated it is · where it is implemented.

## Fed by sources of truth (never hand-duplicated)

```text
registry            → status · version · source · behavior · production · dependencies · QA
component-api/types → props · slots · emits · types   (only when a production API exists)
runtime-qa evidence → per-facet verification status
design hub source   → live, runnable examples + explanation
project profile     → design-system context
```

Status/version live only in the registry; do not restate them in multiple files. Prefer reflecting the real source over re-typing a table that will drift.

## Page shell (three-zone, Vuetify-style)

Every component page uses the shared docs shell:

```text
[ left nav: Design System, grouped Foundations/Components, current item + lifecycle badge ]
[ readable content column (~760px) ]
[ "On this page" sticky index (desktop) / compact index (mobile) ]
```

On ≤1000px the left nav becomes a togglable drawer (burger + scrim + Escape). Anchors must work. This shell is provided by `docs.css` + `docs.js` in the Hub; reuse it, never re-layout per page.

## Mandatory section order

Include a section only when it applies; omit (do not empty-stub) what doesn't:

```text
Component Header → Overview → Usage → Anatomy → Variants/Intents → Sizes/Shapes
→ States → Behaviors → Responsive → Examples → Playground → Accessibility
→ API Reference (Props · Slots · Emits · Types) → Do/Don't → Implementation → QA/Lifecycle
```

## Section contracts

- **Header:** name, short description, type, status, version — from the registry. When useful: source, behavior source, production implementation.
- **Lifecycle badge:** draft ("exploration, API may change") · candidate ("in evaluation, not a stable contract") · stable ("approved contract, promotable") · deprecated ("do not use in new work; replaced by …"). Always from the registry.
- **Overview:** what it is / for / what problem it solves — a few lines, not an essay.
- **Usage:** when to use / when not to use; link a more appropriate component if one exists.
- **Anatomy:** the real parts (container, leading icon, label, trailing, interaction area) — never invented anatomy.
- **Variants/Intents:** every valid variant shown, runnable, explained (purpose · when to use · when not · special rules). Discarded variants only when the decision is worth explaining — not a cemetery of rejected ideas.
- **Sizes/Shapes:** visual comparison; each exists for a real use.
- **States:** default/hover/focus-visible/pressed/selected/open/loading/success/error/disabled when they apply; interactive states must be **runnable**, not fake screenshots.
- **Behaviors:** action/toggle/disclosure/menu/split/destructive documented separately, each with description · live demo · interaction · code · a11y notes.
- **Live examples:** every example runs; each has a Preview/Code toggle and a Copy button that copies clean code (no line numbers/decoration) with copied feedback.
- **Playground:** for multi-prop components; demo + snippet update together; **only valid contract combinations** — it must not let the user break the Design System.
- **Responsive:** show desktop/tablet/mobile and explain *what changes, why, what stays invariant* (e.g. menu: popover → touch popover → bottom sheet). Not just resizing an iframe.
- **Accessibility:** semantics, keyboard, focus, screen reader, touch, contrast, reduced motion, zoom/text scaling, responsive a11y — reflecting **real registry QA evidence** (e.g. `keyboard: runtime-verified`, `touch: runtime-verified · emulated · accepted`, `zoom200: manual-verified`), never marketing, never a bare "Accessibility ✓" when granular evidence exists.
- **API Reference:** appears **only when a real production API exists**. Props/Slots/Emits/Types tables document only what is really implemented and public. No invented props, no internal types.
- **Do/Don't:** real system rules where misuse is a real risk.
- **Implementation:** design source · behavior source · production implementation · dependencies · profile dependencies · version · status — from the registry.
- **QA/Lifecycle:** the real gate/QA evidence (Candidate Gate, Stable Gate, Runtime QA counts, per-facet status incl. caveats), not a green tick.
- **Related:** only real, existing sibling components.

## Lifecycle-gated API (the honesty rule in practice)

The same page evolves incrementally — never a rewrite at promotion:

```text
BEFORE production (draft/candidate):
  document design contract + live HTML/CSS/JS + states + behaviors + responsive + a11y/QA.
  "Production Component API" section says: "Not available yet — not promoted to production."
  Do NOT write framework usage (e.g. <LButton>) as current usage; future API only as
  clearly-labeled future architecture.

AFTER production (stable + promoted):
  the SAME page gains real Props/Slots/Emits/Types and real framework usage examples.
  No parallel/duplicate documentation.
```

## Reusable documentation primitives

Implement once as shared Hub HTML/CSS/JS (not necessarily Vue) and reuse everywhere:

```text
ComponentHeader · LifecycleBadge · OnThisPage · LiveExample · CodeViewer · CopyButton
VariantShowcase · StateShowcase · ResponsivePreview · ApiTable (Props/Slots/Emits/Types)
AccessibilityStatus · DoDont · ImplementationMeta · Playground · DocsShell (three-zone nav)
```

## Consistency rule

Button, Inputs, DatePicker, Navigation, Tables, etc. must feel like one documentation set — same layout, spacing, headings, example containers, code blocks, tables, status badges, navigation, terminology, responsive behavior. Never design a page from scratch; adopt the shell and primitives.
