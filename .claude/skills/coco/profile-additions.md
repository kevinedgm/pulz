# Adiciones al perfil para coco

coco reutiliza el **mismo perfil de proyecto** que la skill `lima` (`profiles/<project>.md`: `name`, `design_system`, `color_law`, `type_law`, `truth_sources`, `hub_root`, `registry_path`, `production.*`, `icon_library` dentro del stack, `a11y_target`, `breakpoints`, `anti_references`). **No** los duplica.

Encima de ese perfil, coco lee un pequeño bloque `coco:` para las cosas que un *protocolo de gobernanza* necesita y una *skill de diseño* no. Si el bloque está ausente, coco cae a revisión manual y lo dice en su declaración de cumplimiento.

## El bloque `coco:` (añadir al perfil activo)

```yaml
coco:
  # Contrato de datos del dominio — las entidades/campos REALES que coco puede renderizar.
  # coco nunca inventa campos; lo que no esté aquí es a lo sumo una "propuesta futura", marcada.
  data_contract: >
    p. ej. DirectorioItem = usuarioId, nombreNegocio, profesion?, ciudad?, bio?,
    fotoPerfil?, precioDesde?, calificacionPromedio?, totalResenas?.
    Regla de presentación: estrellas de rating solo si totalResenas >= 3.
    NO reales (nunca diseñar como reales): distancia/geolocalización, "disponible hoy",
    galería de fotos, dirección exacta, anticipo/pago en la tarjeta.

  # Scripts de gobernanza — checks deterministas que coco corre en el paso 5. Omite los que
  # el proyecto no tenga; coco entonces hace ese check a mano y lo etiqueta.
  governance_scripts:
    scaffold_round:  # p. ej. "python3 <hub>/lab/scripts/scaffold_round.py"  (crea carpetas de ronda rNN)
    check_prototype: # p. ej. "python3 <hub>/lab/scripts/check_prototype.py" (HTML del Hub: ley de color/etiquetas)
    audit_component: # p. ej. "python3 <hub>/lab/scripts/audit_component.py" (arquitectura de componentes)
    coverage:        # p. ej. "python3 <hub>/lab/scripts/coverage.py"        (todo componente censado/documentado)

  # Policy de gobernanza de arquitectura que coco aplica junto con audit_component.
  governance_policy: # p. ej. "<hub>/lab/policies/component-architecture.md" ; omite si no hay

  # Estándar de doc para una página viva de componente en el Hub (orden de secciones).
  component_doc_standard: > # p. ej. "Overview→Preview→Usage→Anatomy→Variants→...→History" ; omite si no hay
```

## Qué activa cada adición en el protocolo

| Campo de coco | Se usa en | Efecto |
|---|---|---|
| `data_contract` | Paso 1 (§ contrato de datos) | coco solo renderiza campos reales; el resto se marca como "propuesta futura". |
| `governance_scripts.scaffold_round` | Paso 2 (rondas R2/R3) | Crea la carpeta de ronda de forma determinista; si no, coco la hace a mano. |
| `governance_scripts.check_prototype` | Paso 5.1 | Valida el HTML del Hub contra la ley de color/etiquetas; si no, manual. |
| `governance_scripts.audit_component` + `governance_policy` | Paso 5.4 | Corre el detector de arquitectura + aplica la policy; si no, revisión manual etiquetada `manual`. |
| `governance_scripts.coverage` | Paso 5.4 | Confirma que todo componente está censado/documentado; si no, se omite y se declara. |
| `component_doc_standard` | Paso 4 (documentar un componente de dominio nuevo) | Ordena la página viva del componente en el Hub. |

## Regla de honestidad

Todo paso de gobernanza que coco no pueda correr (porque el perfil no declara el script, o la herramienta no está disponible) debe reportarse como `manual` o `no pudo comprobarse` en la declaración de cumplimiento — nunca se pasa en silencio. Los scripts son la parte *verificable estáticamente*; nunca reemplazan el criterio de coco.
