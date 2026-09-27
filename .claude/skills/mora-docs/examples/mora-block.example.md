# Ejemplos del bloque `mora:`

Estos ejemplos son neutrales. No contienen rutas, clases, breakpoints ni estilos de un proyecto anterior.

## Hub con estándar, shell y preview reales

```yaml
mora:
  doc_standard: AUTO   # o la ruta INSTALADA, p. ej. .agents/skills/lima/reference/component-documentation.md (Kiro)
                       #   .claude/skills/lima/reference/… (Claude) · .codex/skills/lima/reference/… (Codex)
  doc_shell:
    - design-hub/assets/hub-shell.css
    - design-hub/assets/hub-navigation.js
  serve_command: "python3 -m http.server 4321 --directory design-hub"
  coverage_script: "python3 design-hub/scripts/check_coverage.py"
  hub_preview: "iframe http://localhost:5173/qa/<component>?raw=1"
```

Mora reutiliza ese único shell, muestra el componente real y ejecuta los checks declarados. Las rutas son ilustrativas: deben existir en el proyecto antes de guardarlas en el perfil.

## Hub sin harness

```yaml
mora:
  doc_standard: skills/lima/reference/component-documentation.md
  doc_shell:
    - design-hub/assets/hub-shell.css
    - design-hub/assets/hub-navigation.js
  serve_command: "python3 -m http.server 4321 --directory design-hub"
  coverage_script:
  hub_preview:
```

Mora documenta el contrato comprobado y marca la preview como no disponible/no verificada. No copia CSS del componente para simular otra implementación.

## Configuración mínima

```yaml
mora:
  doc_standard:
  doc_shell: AUTO
  serve_command: AUTO
  coverage_script: AUTO
  hub_preview:
```

`AUTO` autoriza detección, no invención. Si encuentra varios shells o scripts plausibles, Mora los presenta como conflicto en vez de escoger uno silenciosamente.
