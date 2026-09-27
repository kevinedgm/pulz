# Source of truth — design system + registry (authoritative policy)

Authoritative owner of three rules: reuse-before-create, ask-vs-infer, and source precedence. Other files reference this instead of restating it. All concrete visual facts come from the active profile (project-profile.md), never hardcoded here.

## The design system is the single visual truth

Every visual decision (color, type, radius, shadow, spacing, iconography) is taken against the profile's `truth_sources`, obeying its `color_law` and `type_law`. Never invent tokens outside it; if one is missing, propose it as a candidate token addition rather than hardcoding a value.

## Reuse before create (hard rule)

Before creating: read the registry, read the profile's truth sources, scan the Hub for adjacent solutions. Reuse existing tokens/surfaces/components/patterns; never duplicate. Propose extraction only under the restraint criteria (two contexts / domain-agnostic / removes relevant duplication).

## Ask product decisions; infer design decisions

> Ask only when a product decision changes the experience. Infer design/architecture decisions from tokens, foundations, and existing patterns.

| Ask (product) | Infer (design) |
|---|---|
| Should this destructive action be undoable? | radius, spacing step, shadow level |
| Can a user act anonymously here? | which color a non-action element takes |
| Inline edit or modal? | hover/focus/pressed treatment |
| Does this flow need confirmation? | icon size, type step, grid columns |

If the answer changes *what the user can do or must decide*, it is product — ask. If it only changes *how it looks or is built*, infer it.

## Source precedence

When two sources conflict, resolve in this order (highest wins):

```text
1. Explicit current user instruction
2. Active project profile
3. Registry + stable contracts
4. Stable foundations / tokens / policies
5. Stable components / patterns / navigation
6. Candidate artifacts
7. Product applications and templates
8. Wireframes / explorations / deprecated
9. Skill inference
```

Two rules govern this order:

- **An exploration or candidate never silently overwrites a stable contract.** Lower-precedence work yields to stable truth.
- **If an explicit user instruction changes a stable rule, treat the change as a system evolution** and route the affected piece back through the lifecycle (lifecycle.md). A stable rule is not immutable, but it evolves through the lifecycle rather than by silent override.
