# UI artifact contract — designing a piece as a system

Every piece is designed as a contract, not a drawing. The contract's shape depends on `artifact_type` (from the router). Design what applies; justify any applicable dimension you skip.

The contract is filled in **after** the universal design process ([design-process.md](design-process.md)) has established purpose, user task, information/action hierarchy, and the UX principles — appearance comes last, not first.

## Contract by artifact type

| Dimension | token | surface | component | pattern | navigation | template | product-application |
|---|---|---|---|---|---|---|---|
| Anatomy | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Variants | scale steps | ✓ | ✓ | ✓ | ✓ | — | as needed |
| Sizes | ✓ | ✓ | ✓ | — | ✓ | — | — |
| States | — | rest/elev | ✓ full | ✓ | ✓ | key states | ✓ |
| Behaviors/interactions | — | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| Content rules | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Responsive contract | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Accessibility | contrast | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Usage rules (when / when not) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

A token needs no `loading` state; a template inherits states from its components. Use the matrix as guidance, not dogma.

## States vocabulary

When applicable: default, hover, focus, pressed, selected, open, loading, success, disabled, empty, error.

## Do variants earn their place?

Each variant must solve a distinct real need. Cut any variant a size/state/token change already covers.

## Accessibility baseline (from the start, not bolted on)

Keyboard, focus order, screen-reader semantics, contrast per the profile's color law, touch targets (≥44px mobile), zoom to 200%, long text. WCAG AA minimum.

## Edge-case matrix (feeds the post-candidate harden pass)

Long strings, dense data, sparse data, empty, error, unexpected content. These are designed here but carried into the `harden` pass (impeccable-bridge.md), which runs after candidate and is checked at the Stable Gate (quality-gates.md).
