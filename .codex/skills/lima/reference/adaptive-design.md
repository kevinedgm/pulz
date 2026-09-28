# Adaptive design — real per-breakpoint rethinking (authoritative)

"Responsive" does NOT mean shrinking desktop. It means rethinking composition and interaction per device.

## Targets

| Target | Primary input | Consequence |
|---|---|---|
| Desktop | pointer + keyboard | density OK, hover affordances, compact controls, popovers |
| Tablet | touch, larger reach | larger touch targets (≥44px), fewer hover-only affordances |
| Mobile | thumb, one hand | thumb-zone actions, full-width or bottom-anchored, sheets over popovers |

## Rethink, don't shrink

Decide how composition AND interaction change, e.g.: action → compact button / larger touch surface / full-width or thumb-zone; menu → popover / bottom sheet; filters → toolbar / drawer + chips + clear; table → columns / prioritized columns / stacked cards. Document the transformation per breakpoint, not just CSS media queries.

## Experience principles (applied from the first draft)

Visual hierarchy, legibility, density, contrast, spacing, typography, affordance, feedback, error prevention and recovery — plus keyboard, touch, focus, screen readers, targets, zoom, long text.

## Reference breakpoints

Design and verify at 1440 / 1024 / 768 / 390. These are checked at the Stable Gate (quality-gates.md). The `adapt` pass runs in the pre-candidate phase (critique → distill → adapt → polish), so responsive composition is resolved before the piece becomes a candidate; the later `harden` pass then hardens those already-resolved compositions rather than fabricating new unhardened states.
