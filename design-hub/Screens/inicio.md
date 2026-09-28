# Inicio · `inicio`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/shell/r01` |
| Código | `apps/web/src/modules/inicio/pages/InicioEmpresaPage.vue`, `modules/inicio/api.ts` (`tieneLotes`) |
| Ruta | `/e/:slug/inicio` (shell; destino `inicio`) |
| Pruebas | `qa/evidencia-shell.mjs` |
| Evidencia | `qa/evidence/shell-r01/inicio-*` |

## Propósito

Destino del shell. "Hoy" con datos reales (tinas por medir, corridas
abiertas, capturas pendientes) es **Fase 5** (§13.2 #3): aquí se muestran
las tres tarjetas rotuladas *Fase 5*, sin inventar datos. Cuando la empresa
**no tiene lotes**, ofrece el primer arranque (§13.2 #2).

## Ruta, entradas y salidas

- Llega el guardia tras entrar; también desde cualquier destino.
- `tieneLotes(org)`: `lots?select=id&count=exact&head=true` bajo RLS.
- Sin lotes → `state-block empty` «¿Qué tienes hoy?» con la primaria
  «Empezar» (oculta en solo lectura). Hoy lleva a **Granel**; la ronda
  `arranque/r01` la redirige al flujo real.

## Componentes usados

`app-shell` · `state-block` (empty, error) · `button`.

## Estados

| Estado | Qué se ve |
|---|---|
| Cargando | tres tarjetas esqueleto con la misma huella (`aria-busy`) |
| Con lotes | tarjetas «Tinas que toca medir hoy», «Corridas abiertas y colectores», «Capturas pendientes» rotuladas Fase 5 |
| Sin lotes | «¿Qué tienes hoy?» + Empezar |
| Error | «No pudimos cargar tu empresa» + Reintentar |

## Criterios verificados

Inicio en 4 anchos × 2 temas para admin y productora; sin desborde al 200 %.

## No verificado

El estado «sin lotes» con datos reales (Cuatro Vientos ya tiene lotes; una
empresa nueva lo mostrará — prueba de punta a punta de la Fase 4, tarea 5).
