# Tina en fermentación · `fermentation-vat`

## Para qué

Resume una tina con ciclo activo para que el operador identifique el objeto,
detecte si necesita una medición y abra el registro sin perder el contexto de
la última lectura. Es una pieza de dominio basada en `UsoTina`; no es una card
genérica.

La implementación y esta ficha proceden de la ronda inmutable
`.fruti/tests/r01`. La preview se compila desde el componente Vue real.

## Uso

- Úsala dentro de la lista de tinas activas de fermentación.
- El consumidor entrega el día del ciclo, permisos y `slug`; la pieza no
  consulta APIs ni infiere permisos.
- No la uses para tinas libres, tanques de granel ni resúmenes arbitrarios.
- Solo existe una acción primaria: **Registrar medición**. Las operaciones de
  gestión permanecen en el menú secundario.

## Anatomía

1. **Contexto:** nombre de tina, folio, litros, día, estado y antigüedad de la
   última medición.
2. **Métricas:** temperatura, Brix y actividad de una misma lectura.
3. **Footer de acción:** CTA primario y menú de gestión. El footer es una región
   independiente y nunca comparte track con las métricas.

Estas regiones materializan `GEO-CONTEXT-001`, `GEO-METRICS-001` y
`GEO-ACTION-001`, decisiones congeladas por Kiwi en r01.

## Estados

| Estado | Disparador real | Resultado |
|---|---|---|
| Al día | medición ≤ 24 h | antigüedad y últimos valores |
| Atrasada | medición > 24 h | “Medición atrasada” con texto, peso y borde semántico |
| Sin mediciones | `ultima_medicion_at = null` | “Registra la primera medición”; métricas como `—` |
| Solo lectura | `puedeMedir = false` | oculta el CTA y explica la falta de permiso |
| Registrando | `registrando = true` | CTA con `aria-busy` y repetición bloqueada |
| Pendiente | `pendiente = true` | chip “pendiente de enviar” |
| Falló | `fallo` con texto | chip, motivo y acción **Corregir** |
| Contenido largo | nombre o folio extendido | wrap sin truncado ni scroll horizontal |

Los estados de carga, vacío y error de la colección pertenecen a la página que
obtiene la lista. No se falsifican dentro de una tina individual.

## Comportamiento

`Registrar medición` navega a
`/e/:slug/fermentacion/:cycle_id/medir`. El menú emite `ver`, `lista`, `cerrar`
y `corregir`; el consumidor ejecuta los efectos.

El atraso usa la regla estricta
`ahora - ultima_medicion_at > 24 h`: exactamente 24 horas no es atraso.
`ahoraMs` permite pruebas deterministas. Actividad conserva la escala real 1–6
y ninguna métrica ausente recibe un valor inventado.

## Responsive

| Espacio real del componente | Composición | Invariantes |
|---|---|---|
| Compact `0–599` | una columna; métricas como filas; CTA full-width y menú debajo | contexto, 3 métricas y acción |
| Medium `600–1023` | contexto apilado; métricas en tres columnas; footer alineado al final | misma jerarquía y lectura |
| Expanded `≥1024` | contexto `min 280 px` a la izquierda; métricas `min 480 px` a la derecha; footer abarca ambas regiones | CTA nunca es cuarta columna |

La pieza usa container queries. Por eso un viewport de 1024 px con padding deja
992 px al componente y conserva correctamente la composición medium; expanded
aparece cuando el contenedor real alcanza 1024 px.

## Ejemplos

- **Operación vencida:** la preview muestra una medición de hace 28 horas.
- **Primera medición:** `ultima_medicion_at` y las tres métricas en `null`.
- **Solo lectura:** `puedeMedir=false`; lectura intacta y motivo visible.
- **Repeated action:** `registrando=true`; enlace ocupado y deshabilitado.

## Accesibilidad

- `li` nombrado por el `h3`; métricas en `dl` con nombre accesible.
- El CTA es un enlace de router y el menú es un botón; el orden de foco real es
  CTA → Acciones.
- CTA y menú miden 44 CSS px como mínimo; el CTA usa 48 px en compact.
- Foco visible verificado por teclado y reflow verificado con zoom nativo 200 %.
- El atraso no depende del color: conserva texto explícito, peso y borde.
- Contrastes medidos sobre Foundations: texto 16.76:1, muted 6.33:1,
  blanco/primary 5.15:1 y danger-text 6.54:1.

Pendiente para Stable: dispositivo táctil físico y revisión específica en
`forced-colors`.

## API real

```ts
props: {
  uso: UsoTina
  dia: number
  esperados: number
  slug: string
  pendiente?: boolean
  fallo?: string | null
  puedeMedir: boolean
  puedeGestionar: boolean
  ahoraMs?: number
  registrando?: boolean
}
emits: {
  ver: []
  lista: []
  cerrar: []
  corregir: []
}
slots: none
```

## Haz / No hagas

| Haz | No hagas |
|---|---|
| Mantén el CTA en un footer separado. | No conviertas acciones en una cuarta columna. |
| Muestra `—` para valores ausentes. | No inventes una lectura previa. |
| Usa texto además del color para el atraso. | No dependas solo del rojo. |
| Oculta el CTA sin permiso y explica el motivo. | No dejes una acción inerte sin explicación. |

## Implementación

- Componente: `apps/web/src/modules/fermentacion/components/FilaUso.vue`.
- Vocabulario: `apps/web/src/modules/fermentacion/dominio.ts`.
- Pruebas: `apps/web/src/modules/fermentacion/__tests__/FilaUso.test.ts`.
- Dependencias: `button`, `status-chip`, `row-menu`.
- Foundations: `.fruti/tokens.json` mediante
  `apps/web/src/shared/ui/tokens.css`.
- Contrato estructural: `.fruti/tests/r01/lima-contract.yaml`.

## QA y ciclo de vida

La fuente de estado, versión y facetas es el registry. La ronda r01 verificó:

- 6/6 pruebas focalizadas de Vitest;
- typecheck y build de producción;
- build de la demo y del Design Hub;
- detector Impeccable sin hallazgos;
- navegador real en 1440 / 1024 / 768 / 390 sin overflow, errores ni
  colisiones;
- evidencia nueva en
  `design-hub/qa/evidence/fermentation-vat-immutable-r01/`.

No es Stable: esa transición requiere harden/audit, uso contextual aceptado y
aprobación explícita adicional.
