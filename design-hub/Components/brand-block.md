# Bloque de marca · `brand-block`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/configuracion/r01` (antes `MarcaPortal`, local de acceso/r01) |
| Código | `apps/web/src/shared/ui/BloqueMarca.vue` |
| Demo real | `Components/demo/index.html#brand-block` |
| Pruebas | `configuracion.test.ts` |
| Evidencia | `qa/evidence/acceso-r01/portal-*`, `configuracion-r01/portal-*` |

## Para qué
La marca de la empresa como la ve la gente: en el portal (antes de entrar) y en la vista previa de Configuración. **Una sola pieza**, sin copias.

## Anatomía y estados
Línea de acento (`--acento`, por defecto `--clay-300`) · logo 56 px **o** monograma (iniciales sobre `--clay-100`) · nombre (2 líneas, completo en `title`; `h1` en el portal, `p` en la vista previa con `nivel`) · mensaje ≤140. Sin `marca` = esqueleto (`aria-busy`).

## API real
```ts
props: { marca?: { nombre: string; mensaje?; logoUrl?; acento? }; nivel?: "h1" | "p" }
```
Dependencias: ninguna. Consumidores: `modules/acceso/components/PantallaAcceso.vue`, `modules/configuracion/pages/PortalMarcaPage.vue`.
