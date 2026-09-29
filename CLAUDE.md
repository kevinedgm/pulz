# PULZ — instrucciones del proyecto

Antes de tocar código, lee **[`docs/PULZ_MAESTRO.md`](docs/PULZ_MAESTRO.md)**
(especificación completa) y **[`docs/ESTADO.md`](docs/ESTADO.md)** (qué fase
va, qué se decidió y por qué). `docs/DECISIONES.md` y `docs/DUDAS.md`
completan el cuadro cuando algo no cuadra con el maestro.

Este archivo solo trae las reglas que **no están en `PULZ_MAESTRO.md`**
porque se decidieron después, en sesión con el dueño. Cuando choquen, estas
ganan sobre lo que el maestro asumía originalmente (ver `docs/DECISIONES.md`
para el porqué de cada una).

## 1. Nunca Docker, nunca Supabase local

`PULZ_MAESTRO.md` §8.4 asume un ambiente local con `supabase start`. **Eso
se descarta por completo y de forma permanente.** No se instala Docker,
Colima, Podman ni ningún runtime de contenedores para este proyecto, ni
siquiera temporalmente para pruebas. Todo el trabajo — desarrollo, pruebas,
lo que sea — va directo contra el proyecto Supabase **alojado** cuyas
credenciales están en `apps/web/.env.local` (no versionado). El Supabase CLI
se usa solo para generar y aplicar migraciones contra ese proyecto (`supabase
link` + `supabase db push`, o el equivalente), nunca para `supabase start`.

## 2. Migraciones: la implementación vigente es la de "desde cero"

El producto **no está lanzado** — no hay usuarios ni datos reales que
proteger todavía. Mientras eso sea cierto:

- El esquema se trata como **una sola implementación limpia**, no como una
  pila de migraciones históricas que se acumulan para siempre. Lo que importa
  es el estado final correcto, no el historial de cómo se llegó ahí.
- Si algo del esquema necesita cambiar (un error de sintaxis al aplicarlo, un
  ajuste de diseño, una corrección de `PULZ_MAESTRO.md` §10.2), **se edita o
  se reescribe la migración correspondiente** para que el conjunto de
  migraciones siga representando la versión correcta y actual del esquema —
  no se apila una migración nueva de "fix" arriba de una vieja con el bug.
- Aplicar el esquema actualizado contra el proyecto alojado puede implicar
  rehacerlo desde cero ahí (no hay datos de producción que proteger).
- **Esto cambia el día que el producto tenga usuarios reales.** A partir de
  ese momento las migraciones sí se vuelven aditivas e inmutables, como
  manda cualquier proyecto en producción. Anotar ese cambio de régimen en
  `docs/DECISIONES.md` cuando llegue.

## 3. Cualquier trabajo de interfaz empieza por `kiwi`

`PULZ_MAESTRO.md` §13.4 ya lo dice ("ninguna pantalla se construye sin su
ronda de kiwi aprobada"); se refuerza aquí porque es fácil saltárselo. Ante
**cualquier** pedido de diseñar, prototipar, crear, rediseñar o corregir una
pantalla, componente, flujo o mockup — aunque no se diga la palabra
"wireframe" —, el primer paso es invocar la skill **`kiwi`** (estructura
F0–F2: brief, user flow, wireframe). Nunca se empieza directo en `lima` o
`coco` para algo que parte de cero.

Flujo completo, en orden, sin saltarse pasos:

```
kiwi (estructura, F0–F2) → lima (gobernanza, registro, contrato)
  → coco (alta fidelidad + implementación + auditoría) → mora-docs (Design Hub)
```

Perfil de diseño activo del proyecto: `.claude/skills/lima/profiles/pulz.md`
(ya completo con los valores de §13.4 — no reinventar tokens ni colores).

## 4. Trabajo autónomo: decidir y seguir, no detenerse a preguntar

Decidido por el dueño el 2026-09-27 (Fase 4): Claude Code **trabaja de forma
automática**. Las compuertas del protocolo (aprobar un plan de fase, aprobar
una ronda de kiwi, decidir una duda de diseño o de alcance) **las resuelve
Claude** con base en `PULZ_MAESTRO.md`, el esquema real y las decisiones
previas, y **continúa** con el siguiente paso del squad sin esperar al dueño.
Reglas:

- Cada decisión tomada así se anota en `docs/DECISIONES.md` (qué, por qué,
  cómo revertirla) y, si cambia una duda, en `docs/DUDAS.md`. El dueño
  revisa después y puede pedir una ronda `rNN+1`; nunca se reescribe una
  ronda ya evaluada.
- Lo que sigue **sin** decidirse solo: cambios de **reglas de negocio** de
  `PULZ_MAESTRO.md` (precio, límites de plan, roles de §11.1), gastos,
  contratación de servicios externos, y todo lo que §0.3 marca como
  innegociable. Ahí se implementa el supuesto ya documentado y se avisa.
- Lo demás sigue igual: kiwi → lima → coco → mora, un commit por tarea,
  verificación real, `docs/ESTADO.md` vivo.

<!-- fruti-squad:start -->
## 🍓 Fruti Squad (kiwi → lima → coco → mora)

Este proyecto incluye el Fruti Squad en `./.claude/skills`. Cada carpeta tiene su `SKILL.md`/`AGENT.md`; léelos cuando la tarea lo pida:

- **kiwi** — estructura: brief, user flow y wireframes F0–F2 adaptativos con traspaso a lima → `./.claude/skills/kiwi/`
- **lima** — gobierna: clasifica, reutiliza, registra y decide el estado de cada pieza → `./.claude/skills/lima/`
- **coco** — construye: alta fidelidad con el sistema real, implementación y auditoría → `./.claude/skills/coco/`
- **mora-docs** — documenta lo implementado y sincroniza el Design Hub (último paso del flujo) → `./.claude/skills/mora-docs/`

Flujo: **kiwi estructura → lima gobierna → coco construye → mora documenta.** Cada uno se dedica a una actividad y todos usan el perfil de proyecto de lima (`./.claude/skills/lima/profiles/<proyecto>.md`).

Política de ejecución (rutea primero, lee después; fuentes aprobadas; handoffs compactos):

@.fruti/policy.md

Rutas reales de skills/agentes: `.fruti/paths.yaml`. Los contratos `.fruti/runtime/*.yaml` citan rutas relativas al paquete (`skills/...`, `agentes/...`); resuélvelas con ese mapa o con `fruti path <ruta>` (imprime la ruta real). Invoca cada miembro con la herramienta Skill (`kiwi`, `lima`, `coco`, `mora-docs`) y haz las preguntas de producto con AskUserQuestion.
<!-- fruti-squad:end -->
