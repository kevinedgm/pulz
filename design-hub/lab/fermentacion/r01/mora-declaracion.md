# Declaración documental · PULZ Design Hub · ronda fermentacion/r01

| Campo | Valor |
|---|---|
| Superficie | 5 piezas nuevas `candidate` 0.2.0 (3 componentes, 2 patrones) + pantalla `fermentacion` + 3 extensiones (0.3.0) |
| Modo | **M2 Página** (6 fichas nuevas) + **M3 Sincronización** (status-chip, banner, app-shell, README, perfil `coco.data_contract`, sitio regenerado) |
| Fuentes | registry (estado, versión, contratos, compuerta), código real (`shared/ui/*.vue`, `modules/fermentacion/*`, `shared/offline/*`), `coco-declaracion.md`, `lima-compuerta.md`, evidencia `fermentacion-r01` y `fase5-offline` |
| Modifica producción | No |

## Verificado

- Header y lifecycle de las 6 fichas = registry (candidate 0.2.0, ronda
  `lab/fermentacion/r01`); API = `defineProps/defineEmits` reales.
- Preview: demos reales de las 5 piezas (`build:hub`, secciones nuevas) y
  galería de 61 capturas para la pantalla.
- Nada no implementado se documenta como hecho: modo completo con RPC real,
  foto real por la cola, formulación real y «Corregir» con `REQUIERE_NOTA`
  del servidor van en «No verificado» / «Pendiente para Stable».
- `pnpm build:hub-site` y `qa/enlaces-hub.mjs`: 0 enlaces rotos (ver
  resultado en `docs/plan/FASE-5.md`).

## Corregido automáticamente

- `Components/status-chip.md`: variantes `pending` y `failed`, versión 0.3.0.
- `Patterns/banner.md`: variante `cola` con acción, prioridad, versión 0.3.0.
- `Patterns/app-shell.md`: banner de cola y FAB con acción (`app/fab.ts`).
- README: fila de Screens, piezas nuevas, evidencia de la ronda y del e2e.

## Derivado fuera de mora

- Ninguno.

## No ejecutado

- Lector de pantalla y zoom nativo (para Stable).
