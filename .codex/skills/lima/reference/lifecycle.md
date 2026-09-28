# Lifecycle — draft → candidate → stable → deprecated

Three separate responsibilities, never collapsed:

```text
quality-gates.md  → defines the criteria (evaluate)
lifecycle.md      → performs the transition
registry.md       → records the result (persist)
```

Everything below `stable` lives only in the Design Hub laboratory.

## States

| State | Meaning | Lives in |
|---|---|---|
| draft | first exploration, mutable | Design Hub |
| candidate | passed the Candidate Gate, awaiting user stabilization decision | Design Hub |
| stable | user-approved canonical contract | Design Hub (truth) |
| deprecated | superseded; `replacedBy` set | Design Hub |

## The two phases

### Phase 1 — reach candidate (before user acceptance)

```text
design → critique → distill → adapt → polish → architectural review
→ evaluate Candidate Gate
→ PASS → transition draft → candidate
→ registry: status=candidate, qa.candidate=true
```

Reaching candidate is automatic once the Candidate Gate passes. No hardening yet — the direction can still be rejected.

### Phase 2 — reach stable (after user accepts the direction)

```text
CANDIDATE → user review / iterations → user requests stabilization
→ harden → audit
→ evaluate Stable Gate
→ PASS → explicit user approval
→ transition candidate → stable
→ registry: status=stable, qa.stable=true
```

`harden` and `audit` run here, not before candidate.

## Transition rules

- **draft → candidate:** allowed only after the Candidate Gate evaluates PASS. The registry write is a *consequence* of the transition, never a precondition of the gate.
- **candidate → stable:** allowed only after the Stable Gate evaluates PASS **and** the user explicitly approves. The registry write is a consequence.
- **stable → production:** separate explicit approval; see promotion.md. Production is never modified automatically.
- **any → deprecated:** set `replacedBy`, warn about dependents (registry.md), keep the old demo reachable.

## Refine loop on request

"púlelo" / "no me convence" re-enters the impeccable pipeline (impeccable-bridge.md) on the current piece rather than restarting. The router's `intent` picks the entry stage; pre-candidate intents re-run Phase 1, `harden`/`audit` run Phase 2.

## System evolution

If an explicit user instruction changes a rule that a `stable` piece depends on, treat it as an evolution of the system: re-run the affected piece through the lifecycle (a stable rule is not immutable, but it is never silently overwritten). See the source precedence rules in source-of-truth.md.
