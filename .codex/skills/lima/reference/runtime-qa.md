# Runtime QA — turning "implemented" into "runtime-verified"

Static review proves a handler, ARIA attribute, or focus trap **exists**. It does not prove the interaction **works when executed**. This file owns the responsibility of running design-system pieces in a real browser and classifying the resulting evidence. It is not a sub-agent; it is a playbook the skill follows.

The runtime QA infrastructure belongs to the **project** (a QA harness), never to the skill. The skill only discovers it, uses it, asks to install it when missing, and blocks the Stable Gate when it is unavailable.

```text
Adaptive UI System Architect
  ├─ defines what must be checked (quality-gates.md)
  ├─ detects available runtime QA (this file)
  └─ consumes evidence (registry.md)
            ↓
      Project QA Harness  ──▶  Playwright (browser)
```

The Design Hub stays the laboratory + docs + demos. The harness is verification infrastructure. The registry records the evidence.

## Discovery

Before running or blocking, inspect the project (values come from the profile's `runtime_qa`, see project-profile.md):

1. Is a runtime QA runner present? (e.g. Playwright in a harness `package.json`, an installed browser)
2. How is the Design Hub served? (static server command + base URL)
3. Where do tests live? (`tests_root`)

## Rule

```text
runtime QA available            → run it, collect evidence, classify, then update the registry
runtime QA absent               → ask the user for authorization to install/configure it
user declines / env disallows   → Stable Gate BLOCKED (do not fake a pass)
```

Never install a runner without explicit authorization. Never substitute static inspection for a runtime run.

## Evidence classification (never infer)

The skill must never reason "a handler exists → the interaction passed". Record the true level of evidence in `qa` (schema in registry.md):

| Level | Meaning |
|---|---|
| `static-reviewed` | code inspected, not executed |
| `blocked-runtime` | needs execution; runner unavailable |
| `blocked` | needs a rendered browser; none available |
| `runtime-verified` | executed in a real browser and observed working |
| `runtime-verified-emulated` | verified via emulation (e.g. Chromium touch), not a physical device |
| `runtime-verified-approx` | verified via an approximation (e.g. root-font-size doubling, not native text-zoom) |
| `passed-with-reviewed-findings` | a real deterministic check ran (e.g. the detector) |
| `screenshots-reviewed` | visual evidence captured for human review |

Order of operations (mirrors the gate discipline): **run tests → collect evidence → classify results → update registry.** Creating a test does not make a facet `runtime-verified`; only a passing run does.

## What runtime QA must cover for an interactive component

- **Viewports:** the mandatory set (e.g. 1440 / 1024 / 768 / 390): no horizontal overflow, no clipping, targets correct, menus within viewport.
- **Keyboard:** real key events (Tab, Enter/Space, ArrowUp/Down, Home/End, Escape); assert `aria-expanded`, focused element, order, close, focus return.
- **Focus:** trap and return for modal surfaces.
- **Async:** idle→loading→success and →error; assert `aria-busy`, double-submit blocked, geometry stable (measure width before/during/after), state restored.
- **Menus / action sheet / split / disclosure:** each exercised; on mobile assert the sheet is modal (background not tabbable) with focus trap + return.
- **Long content:** exercised in the real product-context scenario.
- **Reduced motion:** via the browser's real `prefers-reduced-motion` emulation.
- **Touch:** emulated touch when a device is unavailable — record as `runtime-verified-emulated`, never as physical-device proof.
- **Zoom/text 200%:** use the most faithful available approach; if the runner cannot reproduce native text-zoom, record `runtime-verified-approx` or `blocked`, never a plain pass.
- **Screenshots:** complementary evidence for human review, not a substitute for DOM/geometry/attribute/focus assertions.

## Fidelity honesty

`-emulated` and `-approx` are verified-with-a-caveat. They do not silently become `runtime-verified`. A facet stuck at that level is a decision point the user resolves at the Stable Gate, not an automatic pass. When the user accepts a caveated level for the gate, record it as an object `{ status, gateAccepted: true, caveat }` (registry.md) — keep the true provenance; never upgrade the level just to get a green check.

## Manual verification (when automation cannot reproduce a condition faithfully)

Some conditions cannot be reproduced faithfully by headless automation (e.g. the browser's **native text/zoom at 200%**, which redistributes layout/viewport/controls differently from doubling `root font-size`). For these, a minimal **human-in-the-browser** check is the honest path — no new infrastructure required. The agent must not fabricate `manual-verified`; only a human (or a session with an interactive browser) can grant it.

Native 200% zoom checklist (for `zoom200`):

```text
Open the piece in a real browser → native zoom 200% (Ctrl/Cmd +)
Review at 1440 / 1024 / 768 / 390 where applicable, on:
  Buttons · Menus · Action sheet · Split · Disclosure · Long labels · the Agenda scenario
Verify: no clipping · no overlap · no control loss · no accidental horizontal scroll
        · focus still visible · content still operable
```

If it passes, record `zoom200` as `{ status: "manual-verified", gateAccepted: true }`. If it fails, keep it blocked and file the defect back through the lifecycle.

## Explicit-evidence rule (mandatory)

A facet may be recorded as `manual-verified` **only** when the user explicitly states they ran the test and supplies the real result. Conditional, templated, or hypothetical statements never count as executed evidence, and an ambiguous acknowledgement is not a result — ask for the explicit result before recording anything.

Does NOT count (never record `manual-verified`):

```text
"if it passes, I'll tell you…"      "the message would be…"
"use this template…"                "when I test it…"
"ya lo probé, está bien"  (ambiguous — which viewports? what result? → ask)
```

Counts:

```text
"I ran the test in a real browser. 1440 PASS · 1024 PASS · 768 PASS · 390 PASS · Overall PASS."
```

If a `stable` transition was granted on evidence that turns out inferred rather than explicitly supplied, revert to the last genuinely demonstrated state and restore the blocker. Conditional or templated evidence never counts as executed evidence.
