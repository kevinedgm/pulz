# Adaptive UI System Architect

El cerebro arquitectónico del design system. Convierte peticiones simples de UI, en lenguaje natural, en piezas de sistema completas, reutilizables y adaptativas — nunca soluciones sueltas accidentales. Núcleo agnóstico del proyecto; todo lo específico vive en un perfil de proyecto.

## Principio rector

> Esta skill diseña y gobierna el sistema. `impeccable` lo critica y lo refina. El Design Hub es el laboratorio. El registry guarda la verdad. Producción solo consume piezas aprobadas.

## Cómo se usa

Di lo que quieres: "Créame el WebKit de Buttons", "Ahora haz Inputs", "Necesito un DatePicker", "Rediseña la navegación", "Púlelo", "Haz que funcione mejor en móvil", "Promuévelo al sistema estable". Atajos `/` opcionales (nunca obligatorios): `/design /critique /polish /harden /adapt /promote /deprecate`.

## Qué ocurre (dos fases)

```text
Petición → clasificar + intención + inspeccionar → diseñar en el Hub (draft)
→ critique → distill → adapt → polish (impeccable)
→ revisión arquitectónica → Candidate Gate → candidate
→ (revisas / iteras; luego pides estabilizar)
→ harden → audit (impeccable) → Stable Gate → (apruebas) → stable
→ (opcional, apruebas) producción en el stack real
```

`harden` y `audit` corren solo después de `candidate` — el endurecimiento final nunca se gasta en una dirección que aún puedes rechazar. Evaluar → transicionar → persistir se mantienen separados: los gates deciden, el lifecycle transiciona, el registry registra.

## Primer uso en un proyecto nuevo

La skill es pública y reutilizable. En un repo que nunca ha visto no hay perfil activo, así que **primero se inicializa**. La skill pide un **formulario de intake fijo** (`reference/intake.md`) — cada dato que necesita, en el formato exacto en que lo consume, mapeado 1:1 al perfil — para no tener que adivinar un design system ni inventar tokens. Pegas el formulario ya rellenado; los campos marcados `AUTO` dejan que el repo responda las preguntas mecánicas (stack/rutas).

Después genera el perfil y scaffoldea las carpetas a las que apunta (Design Hub, registry, harness de QA con Playwright opcional). Para un bootstrap no interactivo de las carpetas, un comando:

```bash
bash scripts/init-project.sh \
  --name "Acme / PULZ" --design-system "PULZ" \
  --hub "design-hub" --qa playwright
```

`impeccable` viene incluido (`vendor/impeccable`), así que no hace falta `--impeccable`. Luego rellena en el perfil generado los campos que solo un humano puede dar (`color_law`, `type_law`, `truth_sources`) y confírmalo. Guía completa (guiada + por script): `reference/first-run.md`; documentación del script: `scripts/README.md`.

## Perfil de proyecto

El núcleo de la skill no tiene nada específico de design system, color, ruta ni stack. Eso vive en `profiles/`. Parte de `profiles/_TEMPLATE.md`; un perfil ya completo de un proyecto real se conserva como referencia en `profiles/examples/manik-lustre.md` (design system Lustre, Manik Design Hub, Vue 3 + Tailwind) — un ejemplo, no un default para otros repos.

## Estado

La verdad persistente vive en el registry del perfil (la ruta es el `registry_path` del perfil, p. ej. `design-hub/system/registry.json`): qué existe, estado (draft/candidate/stable/deprecated), gates de qa, dependencias, versión, ruta del demo, producción `{framework, path}`, reemplazos. Nunca depende de la memoria del chat.

## Archivos

| Archivo | Propósito |
|---|---|
| `SKILL.md` | Router de lenguaje natural, principio rector, pipeline de dos fases, mapa de fases, reglas duras. |
| `profiles/_TEMPLATE.md` | Plantilla de perfil en blanco y comentada para copiar en un proyecto nuevo. |
| `profiles/examples/manik-lustre.md` | Ejemplo de un perfil completo (Lustre + Manik Design Hub + Vue/Tailwind). |
| `scripts/init-project.sh` | Bootstrap de primera vez: genera un perfil + scaffoldea Hub/registry/QA. Acepta `--intake <archivo>` para un perfil completo. |
| `scripts/parse_intake.py` | Parser sin dependencias para un intake YAML rellenado (lo usa `--intake`; sin PyYAML). |
| `scripts/README.md` | Uso del script, flags y pasos posteriores. |
| `profiles/examples/intake.example.yaml` | Un ejemplo de intake rellenado para copiar y pasar a `--intake`. |
| `vendor/impeccable/` | Copia embebida de la skill de refinamiento `impeccable` (autocontenida; sin instalación externa). |
| `reference/first-run.md` | Playbook de inicialización (guiado + por script); los comandos de primera vez. |
| `reference/intake.md` | El formulario de intake fijo que la skill pide en el primer uso: cada dato, su formato estricto y su mapeo 1:1 al perfil. |
| `reference/project-profile.md` | Cómo se enlaza la skill a un proyecto; plantilla y selección de perfil. |
| `reference/request-router.md` | Entender, clasificar (tipo + intención + alcance), inspeccionar, detectar reuso. |
| `reference/design-process.md` | Proceso de UX universal y agnóstico del dominio: propósito/tarea/jerarquía/principios antes que apariencia. |
| `reference/lifecycle.md` | Estados, dos fases, transiciones (evaluar → transicionar → persistir). |
| `reference/quality-gates.md` | Criterios verificables de Candidate/Stable (autoritativo; solo evalúa). |
| `reference/source-of-truth.md` | Design system + registry como verdad; reuso, preguntar-vs-inferir, precedencia de fuentes. |
| `reference/registry.md` | Ubicación del registry, esquema (dependencies/qa/production), operaciones. |
| `reference/adaptive-design.md` | Replanteo real por breakpoint (autoritativo). |
| `reference/ui-artifact-contract.md` | El contrato de una pieza, según el tipo de artefacto. |
| `reference/impeccable-bridge.md` | Orquestación de impeccable; orden del pipeline repartido entre las dos fases. |
| `reference/design-hub.md` | Demos interactivos, comparación responsive, contexto de producto realista. |
| `reference/component-documentation.md` | Cómo documentar un artefacto como página de referencia viva (estilo Vuetify) alimentada por las fuentes de verdad. |
| `reference/runtime-qa.md` | QA en navegador real: pasar de "implementado" a "runtime-verified" vía el harness de QA del proyecto. |
| `reference/component-api.md` | Política autoritativa para expresar un contrato stable como API de componente reutilizable (props/slots/emits/tipos/composición). |
| `reference/promotion.md` | Orquesta la promoción de un contrato stable a producción; delega las reglas de API a component-api.md. |

## Relación con impeccable

`impeccable` es el especialista de refinamiento, orquestado aquí como critique → distill → adapt → polish (pre-candidate) y harden → audit (post-candidate), más extract bajo demanda. Todas las decisiones arquitectónicas sobre el design system se quedan en esta skill.

**Viene incluido**: una copia completa de `impeccable` se envía dentro de esta skill en `vendor/impeccable/`, así que la skill es autocontenida y no necesita instalación externa. `init-project.sh` deja por defecto el `impeccable_path` del perfil apuntando a esa copia embebida. Sobreescribe `impeccable_path` solo si quieres apuntar a un impeccable compartido o más nuevo.
