# Lima · compuerta Candidate · fermentation-vat/r01

## Evidencia consumida

- Contrato congelado: `.fruti/tests/current/lima-contract.yaml`.
- Cumplimiento canónico de Coco: `.fruti/reports/compliance-current.json`.
- Implementación: `apps/web/src/modules/fermentacion/components/FilaUso.vue`.
- Preview real compilada: `Components/demo/index.html?pieza=fermentation-vat&solo=1`.

Lima **no repitió la auditoría de Coco**.

## Candidate Gate

| Criterio | Resultado | Evidencia |
|---|---|---|
| Anatomía y jerarquía | PASS | contrato + componente |
| Variantes justificadas | PASS | no se añadieron variantes visuales |
| Estados aplicables | PASS | F2 + pruebas + contrato |
| Adaptación real | PASS | 390/768/1024/1440, tres composiciones |
| Base accesible | PASS con caveat | semántica/foco/44 px; color normativo ausente |
| Demo interactiva real | PASS | build Vue del Hub |
| critique → distill → adapt → polish | PASS degradado | playbooks aplicados manualmente; detector ejecutado una vez |

Resultado: **PASS → draft → candidate**. Registry actualizado a `candidate`, `qa.candidate=true`.

## Stable Gate

Resultado: **NO EVALUADO / BLOQUEADO**. Faltan aprobación explícita del usuario, touch en dispositivo físico, texto real al 200% y forced-colors. El estado no se eleva administrativamente.
