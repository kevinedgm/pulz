# Flujo por pasos · `step-flow`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/fermentacion/r01` |
| Código | `apps/web/src/shared/ui/FlujoPasos.vue` |
| Demo real | `Components/demo/index.html#step-flow` |
| Pruebas | `fermentacion-ui.test.ts` (1 caso: Paso n de N, Cancelar/Atrás, una primaria, foco al primer control) |
| Evidencia | `qa/evidence/fermentacion-r01/medir-1-*`, `medir-3-*`, `revisar*` |

## Para qué

Una captura larga partida en **un concepto por pantalla** para hacerla con
una mano: la medición diaria (§13.2 #4). Cabecera con contexto y «Paso n de
N», un paso visible, barra Atrás / Siguiente en la zona del pulgar.

## Uso

- El consumidor guarda los valores de todos los pasos (Atrás no pierde nada)
  y decide `paso`, `total`, la etiqueta de la primaria (verbo en el último
  paso: «Guardar medición») y cuándo deshabilitarla (con motivo).
- Cancelar solo existe en el primer paso (`cancelarTo` o evento).
- No es un asistente de configuración: para listas de decisiones usa
  tarjetas (arranque/r01).

## Anatomía

`section.flujo` → `header` (slot `cabecera` + `p[role=status]` «Paso n de N»)
→ `div` (slot del paso) → barra con `button` quiet (Cancelar/Atrás) y
`button` primary.

## Comportamiento

Al cambiar `paso`, el foco va al primer control del paso (`input`,
`radio`, `select`, `textarea`). `ocupado` marca `aria-busy` y pone la
primaria en carga.

## Responsive

<600: la barra es **fija** sobre la navegación inferior del shell
(`bottom: 64px + área segura`) y el contenido deja hueco. ≥600: barra bajo el
contenido, todo centrado a 520 px. Misma instancia.

## Accesibilidad

`role=status` en el progreso; una primaria por vista; foco gestionado;
targets 44 px; funciona con teclado (Tab entre campo y barra).

## API real

```ts
props: { paso: number; total: number; etiquetaSiguiente?: string ("Siguiente"); ocupado?; siguienteDeshabilitado?; motivoDeshabilitado?; cancelarTo?: string }
emits: { atras: []; siguiente: []; cancelar: [] }
slots: cabecera · default (el paso)
```

## Implementación

Tokens: `--surface`, `--border`, `--muted`, `--sp-*`, `--font`.
Dependencias: `button`.

## QA y ciclo de vida

viewports, teclado y touch emulado runtime-verified (evidencia y e2e
offline). **Pendiente para Stable:** teclado virtual real sobre la barra fija.
