# Kiwi F2 geometry contract

Kiwi owns structural certainty, not final visual styling. A F2 artifact is not complete until geometry is explicit enough that Coco can build F3 without re-deciding information architecture.

## Required geometry

For every major region record:
- role and dominant information;
- min/max or reference size when size affects usability;
- grid span / placement;
- spacing relationship to adjacent regions;
- density and expected content range;
- primary/secondary hierarchy;
- interactive target size;
- overflow/truncation/wrapping behavior.

## Adaptive matrix

Always describe compact (<600), medium (600–1023), expanded (>=1024):
- what is preserved;
- what changes structure;
- what is hidden or progressively disclosed;
- navigation form;
- primary-action placement;
- list/detail relationship.

Do not merely scale the same layout.

## Decision provenance

Important structural decisions use a compact record:
- id
- choice
- source: rule | product-context | inference
- because
- alternatives_rejected (when useful)
- affects: compact | medium | expanded
- status: proposed | frozen | unresolved

Never attribute an inference to a standard.

## Neutrality

F2 uses grayscale/system type. No final brand colors, decorative shadows, brand illustration or F3 motion. Geometry and hierarchy must work without color.

## Grouping rule

Do not introduce a card merely because a UI library has cards. Use a surface only when it communicates a real independent group, interaction boundary, selectable object, or elevation/layer. Prefer spacing, alignment and dividers for ordinary grouping.

## Interface standards

Configured interface guidelines (for example a project-supplied Apple HIG reference) are normative only when the actual source is available through the active profile/contracts. If the source is missing, record the gap. Do not reconstruct or paraphrase a missing normative document from memory.
