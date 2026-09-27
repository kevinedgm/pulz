---
name: lima
description: Use when the user asks to design, create, redesign, or refine any UI piece as part of a reusable design system — buttons, inputs, date pickers, navigation, a full screen, tokens, patterns, or templates. Triggers on plain requests like "créame el WebKit de buttons", "diseña los inputs", "necesito un date picker", "rediseña la navegación", "rediseña esta pantalla", "púlelo", "haz que funcione mejor en móvil", or "promuévelo al sistema estable". This skill is the architectural brain of the design system: it understands the need, inspects the existing system, classifies the request, designs adaptively for desktop/tablet/mobile, governs a persistent registry, and orchestrates the impeccable skill for critique, simplification, adaptation, and hardening. It is project-agnostic: all design-system, token, path, and stack specifics live in a project profile, not in the skill; on a new repo it initializes a profile and scaffolds the Design Hub/registry before designing (see reference/first-run.md). Not for backend logic or non-UI tasks.
license: MIT
metadata:
  author: skill-architect
  version: "1.0"
  orchestrates: impeccable
---

# Adaptive UI System Architect

The architectural brain of the design system. It turns simple, natural-language UI requests into complete, reusable, adaptive design-system pieces — never accidental one-offs.

**Governing principle:**

> This skill *designs and governs* the system. `impeccable` *critiques and refines* it. The Design Hub is the *laboratory*. The registry holds the *truth*. Production consumes *only approved pieces*.

**Project-agnostic core.** The skill itself contains no design-system, color, path, or stack specifics. Those live in the active **project profile** (see [reference/project-profile.md](reference/project-profile.md)). Load the active profile first, every session.

**First run in a new project.** If there is no active profile yet (a fresh repo, or `profiles/` holds only `_TEMPLATE.md` and `examples/`), **initialize before designing**: generate a profile and scaffold the folders it points to (Design Hub, registry, optional QA harness). Run the guided flow or the one-command bootstrap in [reference/first-run.md](reference/first-run.md) / [scripts/init-project.sh](scripts/init-project.sh). A completed profile from a real project is kept as a reference at [profiles/examples/manik-lustre.md](profiles/examples/manik-lustre.md) — it is an example of a filled profile, never a default for other repos.

## Natural language is the interface

The user speaks plainly; you infer the process. Never require flags or a command grammar.

- "Créame el WebKit de Buttons." → new `button` component, full lifecycle in the Hub.
- "Ahora haz Inputs." · "Necesito un DatePicker." → classify, check registry, design.
- "Rediseña la navegación." → redesign a navigation pattern.
- "Púlelo" / "no me convence" → refine loop on the current piece.
- "Haz que funcione mejor en móvil." → adaptive pass for mobile.
- "Ya me gusta, promuévelo al sistema estable." → stabilize: harden (lima) + audit (delegated to coco) + stable gate, then offer production.

Optional `/` shortcuts, never required: `/design`, `/critique`, `/polish`, `/harden`, `/adapt`, `/promote`, `/deprecate`. They resolve to the same workflows the router derives.

## How much to ask

No mandatory interview. If the request implies the piece and its purpose, inspect the system and start. Ask only when a **product decision that changes the experience** is missing (e.g. "should this destructive action be undoable?"), never a design detail (e.g. radius, spacing) — those are inferred from tokens and existing patterns. Authoritative rule: [reference/source-of-truth.md](reference/source-of-truth.md).

## Squad flow — lima is the governance step

In the Fruti Squad every member owns one activity, and work moves in one direction:

```text
🥝 kiwi  → STRUCTURE     brief, user flow, wireframes F0–F2 (neutral kit)
🟢 lima  → GOVERNANCE    classify, reuse, register, fix the contract, decide status   ← this skill
🥥 coco  → CONSTRUCTION  high fidelity with the real system (F3), implementation (R3), audit (R0)
🫐 mora  → DOCUMENTATION publish only what is implemented and verified
```

**What lima receives (from kiwi):** an approved structure round (`<hub_root>/lab/<surface>/rNN/` with `brief.md`, `index.html`, `declaracion.md`) and its handoff: pieces, adaptation matrix, required states, data proposal. If there is no kiwi round and the request is structural (a new screen, flow, or feature), hand it to kiwi first. For a well-known primitive (e.g. a button), kiwi's abbreviated brief is enough.

**What lima does (governance only):**

1. **Classify** each piece: primitive · pattern · template · `product-application` (request-router.md).
2. **Reuse first:** check the registry and existing components; mark each piece `reuse` / `extend` / `new` / `local`.
3. **Register** new system pieces as `draft` in the registry (registry.md) with owner and source round.
4. **Fix the contract** of each piece (ui-artifact-contract.md, component-api.md): states, variants, adaptive behavior, a11y target — derived from kiwi's frozen structure, never redesigned.
5. **Hand coco a build order:** pieces, classification, contract, tokens/primitives to reuse, and which pieces are local vs system.
6. **Gates:** when coco returns its compliance declaration, lima evaluates the Candidate/Stable gates (quality-gates.md) using **coco's audit as evidence**, records status/version/QA in the registry, and applies lifecycle transitions with user approval.
7. **Release to mora:** only after the registry reflects the new status. mora documents what the registry and the real code say.

**What lima does not do in the squad:** it does not author structure (kiwi), does not produce visual designs or code (coco), does not run a parallel audit (coco), and does not write Hub pages (mora). The impeccable passes (critique, distill, adapt, polish, harden) run in **review mode**: lima runs them against coco's output, records findings, and coco applies the changes.

**Returns:** structural or flow defects → kiwi (new round). Visual, code, or QA defects → coco. Documentation drift → mora.

**Standalone fallback:** if kiwi or coco are not installed in the project, lima runs the full pipeline below by itself and says so in one line.

## The pipeline

Two phases separated by user review. Design and light refinement happen before `candidate`; final hardening happens only after the user decides to stabilize a direction they have accepted.

```text
DRAFT
  design the experience first (purpose → task → hierarchy → UX principles)  (design-process.md)
  design → critique → distill → adapt → polish        (impeccable-bridge.md)
  → architectural review (this skill)
  → Candidate Gate (evaluate)                         (quality-gates.md)
  → transition draft → candidate                      (lifecycle.md)
  → registry: status=candidate, qa.candidate=true     (registry.md)
CANDIDATE
  → user review / iterations
  → user requests stabilization
  → harden (lima, impeccable-bridge.md)
  → audit  (DELEGATED TO coco — design + component-architecture audit)
  → Stable Gate (evaluate)                            (quality-gates.md)
  → explicit user approval
  → transition candidate → stable                     (lifecycle.md)
  → registry: status=stable, qa.stable=true           (registry.md)
STABLE
  → optional explicit production approval
  → production implementation (real stack)            (promotion.md)
```

`harden` and `audit` run **after** candidate, on purpose: never spend the final hardening pass on a direction the user can still reject or redesign. Evaluate → transition → persist are three separate responsibilities and never collapse into one.

**Audit is coco's job, not lima's.** lima owns the lifecycle (gates, registry, versioning), the design pipeline, and the refinement passes up to `harden`. When the Stable Gate needs an `audit` (design compliance + component-architecture governance), lima **requests it from coco** and consumes coco's compliance report as the evidence — it does not run its own parallel audit. This keeps a single, canonical auditor (coco) and makes the architect→coco dependency explicit.

## Phase map

| Request is about... | Read |
|---|---|
| First run in a new project (no profile yet) — initialize | [reference/first-run.md](reference/first-run.md) + [scripts/README.md](scripts/README.md) |
| The exact inputs to ask for on first run (fixed intake form + formats + mapping) | [reference/intake.md](reference/intake.md) |
| The active project's system, tokens, paths, stack | the active profile in `profiles/` via [reference/project-profile.md](reference/project-profile.md) (example: [profiles/examples/manik-lustre.md](profiles/examples/manik-lustre.md)) |
| Understanding + classifying + intent | [reference/request-router.md](reference/request-router.md) |
| Designing for purpose/experience before appearance (universal UX process) | [reference/design-process.md](reference/design-process.md) |
| States, transitions, promotion gates | [reference/lifecycle.md](reference/lifecycle.md) |
| Verifiable candidate/stable criteria | [reference/quality-gates.md](reference/quality-gates.md) |
| Reuse rules, truth, ask-vs-infer, source precedence | [reference/source-of-truth.md](reference/source-of-truth.md) |
| Reading/writing the persistent registry | [reference/registry.md](reference/registry.md) |
| Real per-breakpoint adaptation | [reference/adaptive-design.md](reference/adaptive-design.md) |
| The contract of a piece (varies by type) | [reference/ui-artifact-contract.md](reference/ui-artifact-contract.md) |
| Orchestrating impeccable | [reference/impeccable-bridge.md](reference/impeccable-bridge.md) |
| Building demos + responsive comparison | [reference/design-hub.md](reference/design-hub.md) |
| Documenting an artifact as a living reference page | [reference/component-documentation.md](reference/component-documentation.md) |
| Running real-browser QA (implemented → runtime-verified) | [reference/runtime-qa.md](reference/runtime-qa.md) |
| Expressing a stable contract as a reusable component API | [reference/component-api.md](reference/component-api.md) |
| Promoting a stable piece into production | [reference/promotion.md](reference/promotion.md) |

## Hard rules

- On a repo with no active profile, initialize first (first-run.md): **present the fixed intake form (intake.md) and ask the user for those inputs in that exact format** — do not roam the repo guessing a design system or invent tokens. Map the answers 1:1 to the profile, scaffold its Hub/registry, and confirm before any design. Never design against an assumed system, and never silently reuse another project's profile.
- **The profile is LIVE — update it on request, any time.** If the user provides or changes system facts in natural language ("mi design system es X", "el color de acción ahora es #…", "cambia la fuente a …", "usamos React", "agrega el breakpoint 1280"), rewrite the matching field in `profiles/<project>.md` (`design_system`, `color_law`, `type_law`, `truth_sources`, `production.*`, `breakpoints`, `anti_references`) and confirm in one line. If the profile was initialized as `design_system: NEW`, this is how it gets promoted to the real system: when the user finally tells you their system, replace `NEW`/placeholder values with the real ones. Never require re-running init or the wizard for this — the profile file is the single living source of truth and editing it is a normal operation.
- Design purpose, behavior, context, and experience before appearance; a request never jumps straight to visual variants (design-process.md). The skill is domain-agnostic — domains are input context, never rules.
- Every piece is part of the system. A product-specific screen is legitimate, but it must be classified as `product-application` — it must not pretend to be reusable.
- Never invent tokens/colors/type outside the active profile's design system; that system is the single visual truth.
- Never treat the first version as finished; always run the refine pipeline.
- Never add a variant that only adds complexity; detect and cut it.
- Never run the final hardening pass before the user has accepted the direction (candidate).
- Never modify production automatically; production requires explicit promotion approval.
- Never rely on conversation memory for system state; the registry is the persistent truth.
- The skill is stack-agnostic; the real technology comes from the profile and project inspection at promotion time.
