# Declaración documental · PULZ Design Hub · ronda inicio-hoy/r01

| Campo | Valor |
|---|---|
| Superficie | pantalla `inicio` (`candidate` 0.3.0) |
| Modo | **M2 Página** (`Screens/inicio.md` reescrita) + **M3 Sincronización** (registry, sitio regenerado) |
| Fuentes | registry, código real (`modules/inicio/*`), `coco-declaracion.md`, `lima-compuerta.md`, evidencia `inicio-hoy-r01` |
| Modifica producción | No |

## Verificado

- Header y lifecycle = registry (0.3.0 candidate); anatomía, estados y
  permisos = código (`InicioEmpresaPage`, filas, `api.ts`).
- Nada no implementado como hecho: cola con fallo real, rótulo por hora en
  navegador y AT en «No verificado».
- `pnpm build:hub-site` y `qa/enlaces-hub.mjs` en verde (ver salida en el
  cierre de la ronda).

## No ejecutado

- Lector de pantalla y zoom nativo (para Stable).
