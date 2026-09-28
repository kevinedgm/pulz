# Primer uso — usar coco en un proyecto nuevo

coco es agnóstico del proyecto. En un repo que nunca ha gobernado no hay perfil activo, así que lo primero — antes de cualquier diseño, auditoría o prototipo — es enlazar coco al proyecto. coco comparte su perfil con la skill `lima`, así que esto es rápido cuando la skill ya está configurada.

## Orden de resolución (compuerta 0)

1. **Busca un perfil existente** en `profiles/<project>.md` de la skill architect.
   - Si existe y sus rutas resuelven → **reúsalo**. Luego verifica el bloque `coco:` (ver [profile-additions.md](profile-additions.md)); si falta, pide solo esas adiciones ([intake.md](intake.md), la parte `coco:`) y añádelas.
2. **Aún no hay perfil** → inicializa pidiendo el intake completo ([intake.md](intake.md)): los campos del architect + el bloque `coco:`, en un solo mensaje. Mapea las respuestas a `profiles/<project>.md` y confirma.
3. **Override del usuario** → una instrucción explícita en la conversación gana sobre el perfil; obedécela y anota la desviación en una línea.

Nunca diseñes, audites ni prototipes contra un design system asumido. Si no hay perfil y el usuario no ha dado el intake, pídelo primero.

## Dos formas de enlazar

### A. Guiada (por defecto, con el usuario presente)
Presenta el/los formulario(s) de intake literalmente, valida cada campo, resuelve `AUTO` inspeccionando el repo y mostrando hallazgos, luego escribe/extiende el perfil y confirma.

### B. Reusar el bootstrap del architect (lo más rápido al arrancar un proyecto desde cero)
Si estás configurando un proyecto totalmente nuevo, corre primero el bootstrap de la skill architect — crea `profiles/<project>.md`, el Design Hub y el registry:

```bash
# desde la raíz del repo
bash mis-agentes/skills/lima/scripts/init-project.sh \
  --intake my-intake.yaml --qa playwright
```

Luego añade el bloque `coco:` de coco a ese perfil generado (desde [intake.md](intake.md)). coco lee el mismo archivo; nada más que scaffoldear.

## Qué necesita coco para estar a plena potencia

Incluso con un perfil, algunas capacidades dependen de que el proyecto tenga herramientas. coco degrada honestamente — sigue gobernando, pero etiqueta lo que no pudo correr:

| Capacidad | Necesita | Si falta |
|---|---|---|
| Leer tokens / componentes / Hub | `truth_sources`, `component_layout`, `hub_root` en el perfil | no puede arrancar — pide el perfil |
| Scaffolding de rondas (R2/R3) | `coco.governance_scripts.scaffold_round` | crea la carpeta de ronda a mano |
| Check de ley del HTML del Hub | `coco.governance_scripts.check_prototype` | valida etiquetas/ley manualmente, etiqueta `manual` |
| Auditoría de arquitectura de componentes | `coco.governance_scripts.audit_component` + `governance_policy` | aplica principios universales por revisión manual, etiqueta `manual` |
| Censo de cobertura | `coco.governance_scripts.coverage` | lo omite, lo declara en el bloque de cumplimiento |
| Typecheck / build (R3) | el toolchain de `production.known_stack` del perfil | reporta el check como no ejecutado |
| QA por captura | Playwright/Chromium | reporta como no ejecutado |

Ninguna de estas impide que coco *gobierne*; solo cambian qué checks son verificables vs manuales. La declaración de cumplimiento (paso 5) siempre dice la verdad sobre cuáles corrieron.

## Resultado

- coco queda enlazado a `profiles/<project>.md` (compartido con la skill architect), incluyendo un bloque `coco:`.
- Desde aquí aplica el protocolo de 5 pasos (AGENT.md): brief → ruta → leer estándares → construir con el sistema real → verificar + declaración de cumplimiento.
