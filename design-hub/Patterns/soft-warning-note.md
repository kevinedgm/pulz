# Aviso con nota · `soft-warning-note`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/fermentacion/r01` |
| Código | `apps/web/src/shared/ui/AvisoNota.vue` · textos en `shared/supabase/errores.ts` (`AVISOS`) |
| Demo real | `Components/demo/index.html#soft-warning-note` |
| Pruebas | `fermentacion-ui.test.ts` (2 casos) · `rpc.test.ts` (todos los códigos de `rpc_warn` tienen texto) |
| Evidencia | `qa/evidence/fermentacion-r01/revisar-aviso-*` |

## Para qué

Un **aviso blando** (§2.1) no bloquea: con una nota, la misma captura pasa.
Brix o % Alc. fuera de rango, ordinario y colas juntos, capacidad flexible
excedida, cierre con saldo, diferencia de volumen. La pieza muestra el
aviso y pide la nota **antes** de enviar cuando la interfaz ya sabe (rangos
de la empresa); si el servidor responde `REQUIERE_NOTA:<código>`, la misma
pieza aparece con ese código (rama «Corregir» de la cola offline).

## Uso

- `codigo` = código de `rpc_warn` (0014–0019); `null` = oculto.
- El consumidor bloquea su primaria mientras haya `codigo` y la nota esté
  vacía, y manda la nota como `p_nota`.
- Si no hay aviso, el formulario ofrece su «Nota (opcional)» normal (no
  ambas a la vez).

## Anatomía

`p[role=alert]` (título en negrita = primera frase del texto; detalle
opcional) + `text-field` «Nota (obligatoria por el aviso)» requerido.

## Estados

oculto · aviso sin nota (primaria bloqueada por el consumidor) · aviso con
nota.

## Accesibilidad

`role=alert` al aparecer; borde 2 px `--pend` + fondo `--pend-bg` con texto
`--text` (nunca color solo); campo requerido con etiqueta explícita.

## API real

```ts
props: { codigo: string | null; modelValue: string; detalle?: string; disabled? }
emits: { "update:modelValue": [string] }
```

Textos (`AVISOS`): `brix_fuera_rango`, `abv_fuera_rango`, `mezcla_clases_2a`,
`excede_capacidad`, `cierre_con_saldo`, `diferencia_volumen`, `contraparte`,
`anular_medicion`; código desconocido → «Esta captura necesita una nota…».

## Implementación

Tokens: `--pend`, `--pend-bg`, `--text`, `--r-md`, `--sp-*`, `--font`.
Dependencias: `text-field`.

## QA y ciclo de vida

runtime-verified en la evidencia (Brix 19 → aviso → nota → RPC con nota).
**Pendiente para Stable:** rama «Corregir» desde la cola con un
`REQUIERE_NOTA` real del servidor (hoy por prueba unitaria).
