# Registry — the persistent source of truth

State survives across conversations, people, agents, and time. The registry — not chat memory — is authoritative for what exists and in what state. Its location is the profile's `registry_path` (e.g. `design-hub/system/registry.json`). It is created on first use (init scaffolds it as `{}`; see first-run.md) and is runtime data, not shipped with the skill.

Writing the registry is always a **consequence** of a completed transition (lifecycle.md), never a precondition of a gate (quality-gates.md).

## Schema

```json
{
  "button": {
    "kind": "component",
    "status": "candidate",
    "documentation": "../Design System/Botones/index.html",
    "source": "../Design System/Botones/buttons.css",
    "behavior": "../Design System/Botones/buttons.js",
    "dependencies": [],
    "profileDependencies": ["design_system.tokens"],
    "qa": { "candidate": true, "visual": "pending", "stable": false },
    "refinement": {
      "critique": "degraded",
      "distill": "manual-playbook",
      "adapt": "manual-playbook",
      "polish": "manual-playbook",
      "detector": "passed-with-reviewed-findings"
    },
    "production": { "framework": null, "path": null },
    "version": "0.4.0",
    "replacedBy": null,
    "updated": "2026-09-21"
  }
}
```

| Field | Meaning |
|---|---|
| kind | token/surface/component/pattern/navigation/template/product-application |
| status | draft/candidate/stable/deprecated |
| documentation | Hub demo/doc path (relative to registry) |
| source | main reusable styles/markup path (CSS/markup) |
| behavior | associated reusable behavior (JS) path if any; `null` for artifacts with no JavaScript |
| dependencies | ids of **other registry artifacts** this one composes/relies on. Every id here MUST resolve to a key in this registry — no orphan strings |
| profileDependencies | dependencies on the external design system declared in the active profile (e.g. `design_system.tokens`), which are NOT registry artifacts. Use this instead of inventing registry keys for profile-owned truth |
| qa | gate status. `candidate`/`stable` are booleans. All other keys are granular QA facets describing the **level of evidence**, not the agent's confidence in its own code. Each facet takes one of: `static-reviewed` (code/markup inspected but not run), `blocked-runtime` (needs execution; unavailable), `blocked` (needs a rendered browser; none available), `runtime-verified` (executed in a real browser and observed working), `runtime-verified-emulated` (verified but via emulation, e.g. Chromium touch — not a physical device), `runtime-verified-approx` (verified but via an approximation of the real condition, e.g. root font-size doubling instead of native text-zoom), `passed-with-reviewed-findings` (a real deterministic check ran, e.g. the detector), `screenshots-reviewed` (visual evidence captured for human review), `pending`, or `n/a`. **Only `runtime-verified`/`passed(-with-reviewed-findings)` count as fully verified.** `-emulated`/`-approx` are verified with a recorded fidelity caveat, never silently upgraded to plain `runtime-verified`. Static inspection never yields `runtime-verified`. Add `manual-verified` for a facet a human confirmed in a real browser (e.g. native 200% zoom). A facet may be either a bare string (the level) or an **object** `{ "status": <level>, "gateAccepted": <bool>, "caveat"?: <str>, "requires"?: <str> }` when the Stable Gate needs to record an explicit accept/defer decision on a caveated level — so the registry keeps the true provenance instead of hiding a caveat to get a green check. `stable` may only become `true` when every applicable facet is verified **and** `gateAccepted` (where present) is `true`; a facet at `-emulated`/`-approx` is a user decision point, not an automatic pass. See [runtime-qa.md](runtime-qa.md) |
| refinement | provenance of each impeccable pass, so a check never means different things in different sessions. Each key takes one of: `executed` (the pass's **full playbook workflow** ran, incl. sub-agents/browser where it requires them), `degraded` (ran but below its own invariants — e.g. critique without sub-agents/browser, or audit whose browser-dependent parts could not run), `manual-playbook` (skill loaded the playbook and applied its criteria to the code by hand, without the automated/complete workflow), `not-run`. `detector` records the deterministic `impeccable detect` outcome (e.g. `executed` or `passed-with-reviewed-findings`). A pass that only touched code by hand is `manual-playbook`, never `executed`. Never collapse `degraded`/`manual-playbook` into a plain ✓ |
| production | `{framework, path}` once promoted, else nulls |
| version | semver; bump minor on candidate iterations, major on breaking stable change |
| replacedBy | id of the replacement when deprecated |
| updated | ISO date of last change |

Every dependency — whether in `dependencies` or `profileDependencies` — must resolve to a concrete source of truth: a registry key, or a profile-declared fact. Never leave a symbolic string that resolves to nothing.

## Operations

- **Read first**, always, before designing.
- **Write on every completed transition**, in the same step you change the artifact (no drift): draft→candidate sets `status=candidate, qa.candidate=true` (and `qa.visual` stays `"pending"` until browser/rendered QA actually runs); candidate→stable sets `status=stable, qa.stable=true` and requires `qa.visual="passed"`; promotion sets `production`; deprecation sets `status=deprecated, replacedBy`.
- **Respect dependencies**: do not promote a piece to production before its dependencies are stable; warn before deprecating a piece others depend on.
- **Status lives only here** — a file may hold its own docs, never its own status.

## Queries it must answer

What exists · what is stable/candidate/deprecated · what replaces what · dependencies · which gates passed · where each demo and implementation live · what version each has.
