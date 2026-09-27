# Intake — los datos exactos que coco pide en el primer uso

coco gobierna el trabajo de interfaz contra el design system real de un proyecto. Antes de diseñar nada, necesita un **perfil**. coco **no** ronda el repo adivinando un design system ni inventa tokens — pide un conjunto fijo de datos en un formato específico y los mapea 1:1 al perfil.

coco comparte el perfil con la skill `lima`, así que el intake es: **el intake del architect, más un pequeño bloque `coco:`.**

## Cómo usa esto coco

1. En el primer uso en un repo, busca un perfil activo en `profiles/<project>.md` de la skill architect.
   - **Si existe**: reúsalo. Pide solo las adiciones `coco:` de abajo si faltan.
   - **Si no existe**: presenta el intake completo (campos del architect + bloque `coco:`), un solo mensaje, y espera.
2. Valida cada campo contra su formato. Vuelve a pedir solo los campos que fallen. Los campos marcados `AUTO` pueden rellenarse inspeccionando el repo — muestra lo que encontraste para confirmar.
3. Mapea todo al perfil (los campos del architect vía el mapeo de su `reference/intake.md`; los campos `coco:` vía la tabla de abajo).
4. Confirma el perfil terminado con el usuario antes de diseñar.

## Los campos del architect (reusar literalmente)

Usa el formulario exacto de `lima/reference/intake.md`: `project_name`, `design_system_name`, `color_law`, `type_law`, `tokens_source`, `canonical_reference`, `framework`, `styling`, `icon_library`, `router`, `component_dir`, `naming_convention`, `hub_root`, `hub_language`, `a11y_target`, `breakpoints`, `touch_min_px`, `qa_runner`, `serve_command`, `anti_references`.

## Las adiciones de coco (presentar esto literalmente)

```yaml
# === coco · governance additions (append to the project intake) ===
# data_contract: NO lo llenas tú. Déjalo en 'none-yet' (el default del setup).
# coco lo va escribiendo SOLO mientras diseñas: cada pantalla que hagas, registra
# ahí la entidad real que descubrió (Paso 1 de su protocolo). Crece solo.
# Solo si YA tienes tipos/DTOs y quieres adelantarlo, puedes pedirle a coco que lo
# genere leyendo tu código, o usar el atajo `coco add-entity` (opcional).
data_contract: none-yet

# Checks deterministas de gobernanza que coco debe correr en el paso 5. Usa AUTO para que coco
# los detecte en el repo; deja vacío si el proyecto no tiene ninguno (coco lo verifica a mano).
governance_scripts:
  scaffold_round:        # p. ej. "python3 design-hub/lab/scripts/scaffold_round.py" | AUTO | vacío
  check_prototype:       # p. ej. "python3 design-hub/lab/scripts/check_prototype.py" | AUTO | vacío
  audit_component:       # p. ej. "python3 design-hub/lab/scripts/audit_component.py" | AUTO | vacío
  coverage:              # p. ej. "python3 design-hub/lab/scripts/coverage.py" | AUTO | vacío
governance_policy:       # p. ej. "design-hub/lab/policies/component-architecture.md" | vacío
component_doc_standard:  # p. ej. "Overview→Preview→Usage→Anatomy→...→History" | vacío
```

## Formatos de campo (estrictos)

| Campo | Formato / valores permitidos | Si falta/es inválido |
|---|---|---|
| `data_contract` | `none-yet` por defecto — **no lo llenas tú**. coco lo va escribiendo mientras diseñas. Cuando tenga contenido: entidades (`Entidad = campo, campo2?`) + reglas + lista "NO reales" (ejemplos: [`examples/data_contract.example.md`](examples/data_contract.example.md)) | déjalo `none-yet`; coco trata los datos como ilustrativos y los marca, y lo puebla al ir diseñando |
| `governance_scripts.*` | string de comando de shell, `AUTO`, o vacío | `AUTO` → detecta en el repo + muestra; vacío → coco hace ese check a mano y lo etiqueta `manual` |
| `governance_policy` | ruta del repo, o vacío | vacío → coco aplica principios universales de arquitectura por revisión manual |
| `component_doc_standard` | orden en texto libre, o vacío | vacío → coco usa un orden por defecto razonable y lo dice |

## Mapeo Campo → perfil (bloque coco)

Estos aterrizan bajo una clave `coco:` en el mismo `profiles/<project>.md`:

| Campo del intake | Campo del perfil |
|---|---|
| `data_contract` | `coco.data_contract` |
| `governance_scripts.scaffold_round` | `coco.governance_scripts.scaffold_round` |
| `governance_scripts.check_prototype` | `coco.governance_scripts.check_prototype` |
| `governance_scripts.audit_component` | `coco.governance_scripts.audit_component` |
| `governance_scripts.coverage` | `coco.governance_scripts.coverage` |
| `governance_policy` | `coco.governance_policy` |
| `component_doc_standard` | `coco.component_doc_standard` |

Ver [profile-additions.md](profile-additions.md) para cómo se consume cada campo en el protocolo.

## Por qué un intake fijo

- Los campos del perfil son el contrato real de coco; pedirlos directo significa cero adivinanzas y cero deriva.
- Compartir el perfil del architect significa que un proyecto se describe **una vez** y tanto la skill de diseño como el agente de gobernanza leen la misma verdad.
- `AUTO` deja que el repo responda las preguntas mecánicas (rutas de scripts) mientras el humano posee las de juicio (contrato de datos, ley de color/tipografía).
