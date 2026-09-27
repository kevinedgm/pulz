# Universal design process — purpose and experience before appearance

Authoritative owner of **how any artifact is designed as an experience**, before it is shaped visually. Domain-agnostic and platform-aware: the same process applies to SaaS, mobile, dashboards, industrial systems, ecommerce, banking, health, education, admin, internal tools — any digital product. Concrete domains (bookings, ovens, medical records…) are input context and test scenarios, never part of the skill's rules.

## Three layers (never conflate)

```text
Project Profile        → how THIS system looks and behaves (branding, tokens, identity)
Universal guidelines   → the UX/quality questions we must never forget (this file)
Adaptive UI Architect  → decides how to apply both to the current problem
```

The profile governs identity (colors, type, tokens, iconography, density, brand). This file governs **experience quality**, not branding. It never overwrites a valid, explicit Design System decision — see source precedence below.

## Governing principle

> Do not design the component's appearance first. Design its purpose, behavior, context, and experience first — then its form.

"Diseña Cards" must NOT immediately produce Card A/B/C/D. First answer: what does it exist for · what does it communicate · what can the user do · what must they understand first · what situations must it support · on what devices · what states can it have. Then shape it.

## Universal workflow

Every new component/pattern runs this; simple pieces pass quickly, complex interactions iterate. It layers on top of the lifecycle (candidate-gate at the end) and reuses impeccable via impeccable-bridge.md.

```text
DISCOVER → UNDERSTAND → DEFINE PURPOSE → DEFINE USER TASK
→ INFORMATION HIERARCHY → ACTION HIERARCHY → APPLY UX PRINCIPLES
→ DESIGN → EXPLORE → CRITIQUE → DISTILL → ADAPT → STATES → FEEDBACK
→ EDGE CASES → ACCESSIBILITY → MOTION → VALIDATE → DOCUMENT → CANDIDATE
```

### Discover / Understand
Read profile, registry, foundations, tokens, existing components/patterns/navigation — reuse before create (source-of-truth.md). Determine who interacts, what they want, in what context, how often, what info/actions, and the risk of a mistake. Ask only when a missing decision changes the experience — never a visual detail tokens can resolve.

### Purpose
Every artifact must complete: "This component exists to ______." If it can't, it isn't understood yet. Each element must serve a real goal.

### User task
Name the real task (select, confirm, compare, edit, navigate, search, filter, create, delete, expand, check status…). Optimize the task, not the aesthetics first.

### Information hierarchy
Classify content: Primary · Secondary · Supporting · Contextual · Optional · Hidden-until-needed. Ask what shows first / later / can be hidden / is surplus. Apply hierarchy, chunking, progressive disclosure, recognition over recall (≤4 competing items at a decision point).

### Action hierarchy
Classify actions: Primary · Secondary · Tertiary/Quiet · Overflow · Destructive. One primary per context; the rest must not compete; destructive needs confirmation/recovery per the profile's rules.

### Apply UX principles (gate before approving a direction)
- **Clarity** — is it obvious what it is and what you can do?
- **Agency** — does the user keep control (back, cancel, undo, close, recovery)?
- **Familiarity** — reuse recognizable patterns when a convention fits.
- **Flexibility** — works across viewports, inputs, languages, content lengths, preferences, capabilities.
- **Simplicity** — is there anything to remove?
- **Feedback** — every action yields a perceptible response.
- **Error prevention** — prevent errors before showing messages after.
- **Recovery** — an exit when something goes wrong.

### Design / Explore
Design the first solution (anatomy, content, hierarchy, actions, states, interaction, layout, feedback) using the profile's tokens/type/color/surfaces/icons — never a new identity. Explore alternatives only when a real decision is unresolved, and only when they change something significant (hierarchy, composition, interaction, density, action placement, navigation model) — not radius/shadow/2px padding.

### Critique / Distill / Adapt
The seven-question quick review: is it clear · fast · consistent · accessible · calm · specific · recoverable? Then critique redundancy/hierarchy/chrome/noise/complexity/affordance/feedback (impeccable when available). Distill: the second version is usually clearer, not merely more decorated. Adapt: rethink per input context (desktop pointer+keyboard / tablet touch / mobile thumb+small viewport) — composition, density, action placement, popover→sheet, table→list, actions into thumb reach. See adaptive-design.md.

### States / Feedback / Edge cases
States (when applicable): default, hover, focus, pressed, selected, open, loading, disabled, error, success, empty — N/A the rest with a reason. Feedback: immediate → progress → success → failure → recovery, especially async. Edge cases: very short/long content, empty, few/many items, loading, error, unexpected content, slow op, disabled, offline.

### Accessibility / Motion
A11y from the first design: semantic HTML, keyboard, focus-visible, screen-reader labels, contrast, touch targets ≥44px, text scaling to 200%, reduced motion, RTL when applicable, meaning never carried by color alone. Motion scaled to frequency: frequent → instant/minimal, occasional → subtle, rare/onboarding → more expressive; always honor `prefers-reduced-motion`. Never animate just because you can.

### Platform conventions
Before inventing an interaction, ask if a recognizable convention exists and prefer it absent a strong reason. Use interaction conventions and user expectations — not the visual identity of Apple/Material (the profile owns identity).

### Validate / Document / Reusability
Validate in representative scenarios by the component's function (generic, not tied to one product). Document as a living page (component-documentation.md), showing only what really exists. Then ask: specific or reusable? already exists? should it be a component, a pattern, or stay product-specific? Do not force everything into the Design System.

## Universal quality checklist (before the Candidate Gate)

```text
Purpose ✓ · User task ✓ · Hierarchy ✓ · Actions ✓ · States ✓ · Feedback ✓
Error prevention ✓ · Recovery ✓ · Responsive ✓ · Accessibility ✓
Long content ✓ · Edge cases ✓ · Reduced motion ✓ · Documentation ✓
Plus: semantic color/type? · targets ≥44? · text scales? · every interaction has feedback?
· errors recoverable? · navigation predictable? · works across devices?
```

This complements (does not replace) the Candidate Gate in quality-gates.md.

## Source precedence (extends source-of-truth.md)

```text
1. Explicit current user instruction
2. Project profile
3. Design System / registry stable contracts
4. Universal UI/UX guidelines (this file)
5. Platform conventions
6. Candidate artifacts
7. Skill inference
```

Universal guidelines never overwrite a valid explicit Design System decision. They exist to surface UX problems, accessibility problems, interaction problems, missing states, poor feedback, cognitive overload, and error-prone flows — not to replace the product's identity.

## Optional external reference

If the project supplies a universal design guide (e.g. `guia-diseno-interfaces-apple-hig.md`), treat it as a **decision framework for UX/quality**, not a visual recipe that makes every app look like Apple. Its principles (Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight) plus Nielsen heuristics and Norman principles inform this process; the profile still governs branding. This file stays self-contained so the process works whether or not that guide is present.

## The skill is

```text
domain-agnostic · platform-aware · project-aware · user-centered · systematic · adaptive · accessible
```

Not tina-aware, horno-aware, booking-aware, or medical-aware. Domains are input context, never architecture.
