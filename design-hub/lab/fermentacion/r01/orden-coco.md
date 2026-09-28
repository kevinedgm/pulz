# Orden de construcción para coco · fermentacion/r01 · lima · 2026-09-27

Estructura congelada en `brief.md`, `index.html` (69 combinaciones · 0
hallazgos), `hallazgos.md`, `declaracion.md`. Aprobación en automático
(`CLAUDE.md` §4) registrada en `docs/DECISIONES.md`.

## Clasificación y reutilización

| Pieza | Clase | Decisión | Contrato (registry) |
|---|---|---|---|
| `big-number-field` | component (primitive) | **new** · `CampoGrande.vue` | number-field en grande: valor `number \| null`, `inputmode` decimal/numeric, unidad y rango como texto, `autofocus` opcional; 2.75 rem en compact/medium, tabular; sin spinners; valida al salir (min/max → `error`). Hereda el contrato de `number-field`. |
| `scale-choice` | component (primitive) | **new** · `EscalaOpciones.vue` | `radiogroup` de N valores enteros consecutivos (aquí 1–6) con etiqueta por valor; botones iguales ≥44 px en una fila; la etiqueta del valor elegido se lee en `aria-live`; flechas mueven; selección por forma (borde 3 px + fondo), nunca solo color. `modelValue: number \| null`. |
| `datetime-field` | component (primitive) | **new** · `CampoCuando.vue` | «¿Cuándo pasó?»: estado «ahora» (por defecto) o fecha y hora elegidas (`datetime-local` nativo), botón «cambiar»/«ahora»; `modelValue: string \| null` (ISO; `null` = ahora al guardar); nunca futuro (error al salir). |
| `step-flow` | pattern | **new** · `FlujoPasos.vue` | cabecera fija (título/contexto por slot, «Paso n de N» en `role=status`), un paso visible (slot), barra Atrás / Siguiente: en compact fija sobre la barra inferior, en ≥600 bajo el contenido; una sola primaria; Atrás conserva el estado (el consumidor guarda los valores); Cancelar solo en el primer paso; el foco va al primer control del paso al cambiar. |
| `soft-warning-note` | pattern | **new** · `AvisoNota.vue` | aviso blando conocido (texto del código en `AVISOS`) + campo de nota **obligatoria** mientras el aviso aplique; `role=alert` al aparecer; el consumidor bloquea la primaria hasta que hay nota; misma pieza para «Corregir» un fallo de cola (`requiereNota`). |
| `status-chip` | component | **extend** | variantes nuevas `pending` (pendiente de enviar: contorno discontinuo + reloj en texto) y `failed` (falló: tachado no — es futuro, no pasado: borde doble + texto). Se agregan a `ChipVariante`. |
| `banner` | pattern | **extend** | variante `cola`: «N capturas pendientes de enviar · M fallaron» con acción «Reintentar» (slot de acción, única excepción a «sin botón»). Prioridad entre banners: offline > cola > readonly. |
| `app-shell` | pattern | **extend** | banner de cola con `useCola`; FAB con acción: `app/fab.ts` expone `fabAccion` (ref) que la página fija al montar y limpia al salir; el shell llama a la acción al pulsar. |
| `fermentacion` | product-application | **new** | ver abajo |
| `list-stack`, `row-menu`, `state-block`, `task-layer`, `button`, `number-field`, `select`, `text-field`, `page-header`, `fab` | — | **reuse** | sin cambios |

Registro: `big-number-field`, `scale-choice`, `datetime-field`,
`step-flow`, `soft-warning-note`, `fermentacion` entran como `draft` 0.1.0
(`sourceRound: lab/fermentacion/r01`).

## Orden de construcción

1. **Sistema (`apps/web/src/shared/ui/`)**: `CampoGrande.vue`,
   `EscalaOpciones.vue`, `CampoCuando.vue`, `FlujoPasos.vue`,
   `AvisoNota.vue`; `ChipEstado.vue` (+`pending`, `failed`), `Aviso.vue`
   (+`cola` con slot `accion`); `tipos.ts`, `index.ts`; demos en
   `apps/web/hub/DemoHub.vue`; pruebas en `shared/ui/__tests__/`.
2. **Shell**: `app/fab.ts` (`fabAccion`), `AppShell.vue` (banner de cola con
   `useCola` y `usarEmpresa(org)` al cambiar la membresía; FAB → acción);
   `app/destinos.ts` sin `proximamente` en fermentación.
3. **Módulo `apps/web/src/modules/fermentacion/`**:
   - `api.ts`: lecturas (`tinas_en_uso`, `mediciones_del_ciclo`, ajustes,
     tinas libres, lotes de cocido con saldo (`solid_lot_balances`),
     insumos, molinos) con **instantánea** al tener señal y lectura de la
     instantánea sin señal; escrituras: `encolarMedicion` (cola),
     `anularMedicion`, `declararLista`, `cerrarCiclo`, `registrarFormulacion`,
     `tinaQueYaFermentaba` (directas, requieren señal); funciones **puras**
     con prueba: `diaDelCiclo(started_at, hoy)`, `tocaMedirHoy(uso, hoy)`,
     `agrupar(usos, hoy)`, `avisoBrix(brix, ajustes)`, `lecturasParaRpc(...)`
     (arreglos paralelos).
   - `routes.ts`: `/e/:slug/fermentacion` (shell, destino `fermentacion`,
     `fab: {etiqueta: "Medir", icono: "i-medir"}`), `/…/fermentacion/formular`,
     `/…/fermentacion/:ciclo`, `/…/fermentacion/:ciclo/medir`.
   - `pages/FermentacionPage.vue` (grupos, FAB → primera por medir, pie
     admin/productor, banner de instantánea, capa «tina que ya fermentaba»),
     `pages/UsoTinaPage.vue` (KPIs, tabla, anular con motivo, declarar lista,
     cerrar ciclo con diálogo destructivo), `pages/MedirPage.vue`
     (`FlujoPasos` con pasos por modo; revisar con `AvisoNota`, nota, foto;
     guardar → `encolar` → «Guardada · enviada/pendiente» → «Medir la
     siguiente» o volver), `pages/FormularPage.vue`; `components/FilaUso.vue`,
     `components/TinaFermentabaCapa.vue`, `components/ConfirmarCierre.vue`.
   - `data_contract` del perfil: UsoTina, Medicion, NuevaMedicion,
     Formulacion, TinaFermentaba, Ajustes (bloque `coco:`).
4. **Verificación**: `vue-tsc`, eslint, prettier, Vitest (api puras, cola,
   piezas nuevas); `pnpm --filter @pulz/web build:hub`; Playwright
   `qa/evidencia-fermentacion.mjs` (Aurelia en Cuatro Vientos: lista, detalle
   Tina 2, medición mínima REAL de Tina 2 → aparece en «ya medidas hoy»;
   anular esa medición con motivo; formulación NO se ejecuta en Cuatro
   Vientos (no hay tinas libres con cocido: solo se captura la página);
   4 anchos × 2 temas) y `qa/e2e-offline.mjs` (`context.setOffline(true)`:
   3 mediciones (Tina 2, Tina 3 y la Tina 2 otra vez con día corregido) →
   contador → `setOffline(false)` → 3 operaciones una sola vez y en orden;
   los cortes se agregan en la ronda de destilación). `db reset --linked`
   deja Cuatro Vientos como la semilla.
5. Declaración de cumplimiento en `coco-declaracion.md` → lima evalúa la
   compuerta → mora documenta y regenera el sitio.
