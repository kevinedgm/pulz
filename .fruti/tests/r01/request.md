# Fruti Squad Design Test · r01

status: ready
mode: full-squad-test
round: r01

## User request
Diseña un componente para representar una tina en fermentación. Debe mostrar nombre de la tina, día de fermentación, tiempo transcurrido desde la última medición, temperatura, Brix y actividad. Debe dejar claro cuando lleva más de 24 horas sin medición y permitir iniciar el registro de una nueva medición.

## Source artifact
none

## Required pipeline
1. Kiwi: load runtime and the required brief/wireframe/validation references. Produce a neutral grayscale F2, geometry contract, adaptive matrix, states and compact decision records. No visual styling.
2. Lima: classify reuse/extend/new/local and validate the frozen structure against approved contracts, project profile and configured interface standards. Report missing normative sources; never invent them.
3. Coco: build F3 from approved structure + real tokens/design direction, implement in the configured target, then audit and emit compliance evidence.
4. Lima: consume Coco compliance evidence for lifecycle/gate; do not rerun the audit.
5. Mora: generate/update the canonical Design Hub page from verified evidence. Preview MUST render the real implemented component or a verified preview artifact.

## Required deliverables
- .fruti/tests/r01/kiwi-f2.html
- .fruti/tests/r01/kiwi-decisions.yaml
- .fruti/tests/r01/lima-contract.yaml
- Coco implementation/component
- .fruti/reports/compliance-current.json
- Mora Design Hub documentation page with verified Preview
- result dimensions: technical, structural, visual, accessibility, design_system, documentation
- .fruti/tests/r01/result.md with PASS/PARTIAL/FAIL per stage

## Invariants
- Existing HTML/code is current-state evidence, not target visual authority.
- F2 is grayscale/neutral; no branding, final color, shadow or decorative motion.
- compact/medium/expanded must declare what is preserved, changed and hidden.
- Main touch controls >= 44 CSS px.
- Important geometry records size, spacing, hierarchy and source: rule | product-context | inference.
- Do not introduce a card merely as a generic visual container; grouping requires a functional reason.
- Missing standards/references are blockers or explicit gaps, never silently reconstructed.
- Mora Preview corresponds to Coco verified output.
- Overall PASS is forbidden unless every mandatory quality dimension passes.
- No-overflow is not evidence of collision-free or well-composed layout.
- If design_system is NEW and minimum foundations are missing, F3 visual PASS is BLOCKED until foundations are approved.
