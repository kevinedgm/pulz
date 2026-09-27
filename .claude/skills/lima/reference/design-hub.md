# Design Hub — the laboratory

Everything below `stable` is built and shown here; production is never touched during design. The Hub root and taxonomy come from the profile (`hub_root`, `hub_layout`) — never hardcode them here. (Example: the manik-lustre example profile puts the Hub at `Manik Design Hub/` with Design System / Responsive / Patrones UX / Flujos / Wireframes plus a shared stylesheet and `nav.js`; your project's taxonomy comes from your profile.)

## Where a piece goes

Place the piece in the Hub folder matching its `artifact_type` (router). Reuse the profile's Hub stylesheet for tokens; never fork styling.

## What a Hub entry must contain

1. **Interactive demo** — every variant, size, and state rendered and interactive (not a static image).
2. **Responsive comparison** — the same piece across desktop/tablet/mobile (1440/1024/768/390) so the per-breakpoint transformation is visible side by side.
3. **Inline documentation** — problem solved, when to use / when not, variants, states, responsive behavior, accessibility, examples. Docs live with the demo; status lives in the registry.

## Realistic product context

The Stable Gate (quality-gates.md) requires a piece to have been applied at least once inside a realistic product context in the Hub — a Product Application or realistic scenario, not just its isolated showcase. Build that scenario here (e.g. the piece placed inside a real product prototype screen) so stabilization can prove the piece works in context, before any production promotion.

## Consistency

Match the Hub's existing HTML/CSS conventions and navigation wiring so entries feel native. Keep demos self-contained and reachable from Hub navigation.

## After building

Register the piece (registry.md) with `documentation`, `source`, and the status resulting from the transition. The Hub shows it; the registry records its truth.

## Living reference pages (mandatory standard)

The Hub is not a gallery of samples: it is the living, runnable reference of the Design System. Every reusable artifact's page must be a full component reference (demo + code + variants + states + behaviors + responsive + a11y/QA + usage rules + a lifecycle-gated API section), on the shared three-zone docs shell, fed by the sources of truth. The complete standard, section order, section contracts, primitives, and the golden rule are owned by [component-documentation.md](component-documentation.md); follow it when building or updating ANY artifact page — Button is the reference implementation of the standard.

Golden rule (repeated because it is the one that rots first): documentation describes what actually exists and states what does not yet exist. Never document an aspired-to prop, variant, or API as if it worked.
