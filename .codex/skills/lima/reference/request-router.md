# Request router — classify, resolve intent, inspect

Natural language in; a structured decision out. Runs first, every time.

## Step 1 — Understand the need

Resolve: what is this for, how is it used, what UX problem it solves. If the request answers this, proceed. If a **product decision that changes the experience** is missing, ask that one thing (source-of-truth.md), then proceed.

## Step 2 — Inspect the existing system

Reuse before create (rule owned by source-of-truth.md):

1. Read the registry (`registry_path` from the profile) — does the piece exist, in what state?
2. Read the profile's `truth_sources` for tokens/visual law.
3. Scan the Hub (`hub_layout`) for adjacent solutions to reuse.

## Step 3 — Emit a structured request

Separate **what** from **what to do with it**:

```yaml
artifact_type:   # token | surface | component | pattern | navigation | template | product-application
artifact:        # e.g. button, date-picker, primary-nav, directory-screen
intent:          # create | redesign | critique | distill | adapt | polish | harden | audit | promote | deprecate
scope:           # design-system | product-application
```

Same artifact, different workflow:

```text
"créame Buttons"    → component / button   / create
"pule Buttons"      → component / button   / polish
"adapta Buttons"    → component / button   / adapt
"promueve Buttons"  → component / button   / promote
```

`intent` selects the workflow:

- `create` / `redesign` → full pipeline (SKILL.md), ending at the Candidate Gate.
- `critique` / `distill` / `adapt` / `polish` → re-enter that pre-candidate stage on the current piece.
- `harden` / `audit` → post-candidate stabilization stage; only valid once the piece is `candidate`.
- `promote` → promotion.md (piece must be `stable`).
- `deprecate` → deprecation path in lifecycle.md.

## Step 4 — Classify the artifact type

| Type | Signals | Lives in (Hub) |
|---|---|---|
| token | color, spacing, radius, type scale, elevation | design-system tokens |
| surface | background, card, sheet, panel container | Componentes |
| component | button, input, date picker, avatar, badge | matching folder |
| pattern | reusable interaction across screens | Patrones UX |
| navigation | nav bar, tabs, menu, breadcrumb | Componentes + Patrones UX |
| template | full screen composition | Wireframes / Flujos |
| product-application | a specific product screen/piece | its module; NOT reusable |

A `product-application` is legitimate — do not force it to be reusable. Classify it honestly and skip reuse-promotion pressure for it.

## Step 5 — Detect reusable pieces (with restraint)

Propose promoting a solution to a shared Pattern only when it **appears in two or more contexts**, is **clearly domain-agnostic**, or **removes a relevant duplication**. Do not promote something merely because it "might help somewhere." Record the finding; plan an `impeccable extract` pass (impeccable-bridge.md) when it qualifies.

## Handoff

Continue to ui-artifact-contract.md (what to design) and design-hub.md (where). No approval stop here; the mandatory gates are Candidate Gate (pre-candidate) and the Stable Gate + production approval (post-candidate).
