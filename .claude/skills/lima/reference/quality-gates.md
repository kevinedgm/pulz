# Quality gates — verifiable candidate and stable criteria

Authoritative owner of the promotion criteria. This file only **defines and evaluates** criteria. It does not perform transitions (lifecycle.md) and does not write state (registry.md). Updating the registry is a *consequence* of passing a gate, never an item inside the gate.

## Candidate Gate (evaluated before draft → candidate)

All must hold:

- ✓ anatomy defined (per ui-artifact-contract.md for the artifact type)
- ✓ variants justified (none that only add complexity)
- ✓ all applicable states designed
- ✓ responsive contract defined (desktop/tablet/mobile transformation, not shrink)
- ✓ accessibility baseline (keyboard, focus, contrast per profile, targets, zoom, long text)
- ✓ interactive demo in the Hub
- ✓ ran critique → distill → adapt → polish

`harden` and `audit` are NOT part of this gate — they belong to stabilization.

## Stable Gate (evaluated before candidate → stable)

All must hold:

- ✓ Candidate Gate already passed and the piece was accepted as candidate
- ✓ verified at 1440 / 1024 / 768 / 390
- ✓ keyboard operable end to end
- ✓ touch targets and touch interactions verified
- ✓ readable/usable at 200% text zoom
- ✓ long content handled (no overflow/clipping)
- ✓ loading / error / empty covered where applicable
- ✓ ran harden (lima) + audit (delegated to coco; consume coco's compliance report as the evidence)
- ✓ **applied at least once inside a realistic product context in the Hub** (a Product Application / realistic scenario, e.g. the piece used inside a real product prototype), proving it works outside its isolated showcase. This does NOT mean implemented in production — production promotion happens only after stable.
- ✓ explicit user approval

## Order of operations at each gate

```text
evaluate gate  (this file)
   ↓ PASS
transition     (lifecycle.md)
   ↓
persist result (registry.md: status + qa flag)
```

A gate item that genuinely does not apply to the artifact type (e.g. loading on a token) is marked N/A with a one-line reason, not silently dropped.
