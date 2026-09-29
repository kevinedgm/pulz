# Inicio / Hoy · `inicio`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.3.0** · owner lima (registry) |
| Ronda de origen | `lab/inicio-hoy/r01` (antecedente: `lab/shell/r01`, 0.2.0) |
| Código | `apps/web/src/modules/inicio/pages/InicioEmpresaPage.vue`, `modules/inicio/api.ts` (`tieneLotes`, `cargarHoy`, `rotuloHora`, `resumenHoy`, `recortar`, `rutaCorregir`), `modules/inicio/components/Fila{TinaHoy,CorridaHoy,ColectorHoy,ColaHoy}.vue` |
| Ruta | `/e/:slug/inicio` (shell; destino `inicio`; `meta.fab` «Medir») |
| Pruebas | `modules/inicio/__tests__/hoy.test.ts` (10) · `qa/evidencia-inicio-hoy.mjs` (PASS, 8 corridas + operador) |
| Evidencia | `qa/evidence/inicio-hoy-r01/` (41 capturas: `hoy`, `medida-guardada`, `hoy-tras-medir`, `hoy-sin-senal`, `hoy-operador`) |

## Propósito

Destino del shell y primera pantalla del día (§13.2 #3): **qué toca hoy**
compuesto de lo que producen Fermentación y Destilación, más la cola
offline. Inicio es lectura + atajos: **no captura nada**; cada bloque lleva
a su pantalla. Cuando la empresa **no tiene lotes**, ofrece el primer
arranque (§13.2 #2).

## Anatomía

1. **Cabecera**: «Hoy» + fecha larga; con instantánea, «Mostrando datos
   guardados el <fecha>» (`<time>`).
2. **Resumen** (`role=status`): «N tinas por medir · M corridas abiertas /
   sin corridas · K capturas por enviar / nada por enviar».
3. **Toca medir** — `agrupar(tinas_en_uso).porMedir` en el orden de
   Fermentación (más días sin medir primero). Fila: tina · chip «toca medir»
   (`partial`) o «toca desde las H:00» (`draft`, antes de
   `measurement_reminder_hour`) · día N de M (`diaDelCiclo`,
   `fermentation_expected_days`) · última medición (`haceCuanto`) o «sin
   mediciones» · litros · **Medir** → `/fermentacion/:ciclo/medir?volver=inicio`
   (MedirPage vuelve a Hoy con «Medición guardada.»). 8 filas y «y N más →
   Fermentación». Contexto: «X ya medidas hoy · Y listas para destilar».
4. **Destilación** — corridas abiertas (folio · alambique · pasada · empezó ·
   L cargados / L cortados · **Cortar** → corte · «Ver corrida») y colectores
   con saldo (colector · clase · litros · % Alc. · **Pasar a granel** →
   `/granel/transferir?origen=` solo mezcal y admin/productor con señal; si
   no, «Ver»). Vacío: «Sin corridas abiertas ni colectores con líquido» +
   «Abrir corrida» (admin/productor con señal) o «Las corridas las abre el
   productor».
5. **Por enviar** — solo con cola no vacía: `resumen` · hora · chip
   `pending` («pendiente · espera señal») o `failed` + «Falló: motivo» ·
   **Reintentar** · **Corregir** (pantalla de origen con `?corregir=`) o
   **Descartar**. El banner del shell sigue dando el total.

## Estados

| Estado | Qué se ve |
|---|---|
| Cargando | tres tarjetas esqueleto (`aria-busy`) |
| Default | resumen + los tres bloques (Por enviar solo si hay elementos) |
| Todo medido | «Todo medido por hoy.» + contexto |
| Sin tinas | «Sin tinas fermentando.» + «Llenar tinas» (admin/productor con señal) |
| Nada pendiente | state-block «Hoy no hay nada pendiente» + Fermentación · Destilación · Granel |
| Sin señal | fecha de la instantánea (la más antigua de fermentación y destilación); Medir y Cortar siguen activos; lo demás deshabilitado con motivo |
| Operador | Medir y Cortar; sin Abrir corrida, Llenar tinas ni Pasar a granel |
| Solo lectura | ningún atajo de captura; solo consulta |
| Sin lotes | «¿Qué tienes hoy?» + Empezar → arranque |
| Error | «No pudimos cargar tu día» + Reintentar carga |

## Primaria y adaptación

Una sola primaria: **Medir** de la tina más atrasada. En ≥600 es el botón
`primary` de esa fila; en compact es el **FAB** del shell (`meta.fab` +
`fabAccion`, nulo sin tinas por medir) y la fila oculta su botón. ≥1024:
dos columnas (Toca medir 3fr | Destilación + Por enviar 2fr); <1024 una
columna; <600 filas apiladas con botones a todo el ancho.

## Componentes usados

`app-shell` (FAB) · `page-header` · `banner` · `state-block` (empty, error)
· `status-chip` (partial, draft, pending, failed) · `list-stack` · `button`.

## Criterios verificados

Playwright con Aurelia en Cuatro Vientos tras `db reset`: Hoy con la
semilla (Tina 3 antes que Tina 2; «1 lista para destilar»; Colector colas
16 L con «Ver» y sin «Pasar a granel»); Medir desde Hoy → medición real por
la cola → vuelta a Hoy con la Tina 2 fuera de «Toca medir»; sin señal con
instantánea y Medir activo; Tomás (operador) sin Abrir corrida ni Pasar a
granel; primaria única por espacio; 4 anchos × 2 temas sin desborde.

## No verificado

Cola con fallo en navegador real (Vitest y rondas de fermentación/
destilación), rótulo «toca desde las H:00» en navegador real (pura con
test), lector de pantalla y zoom nativo (para Stable).
