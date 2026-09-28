# Declaración documental · PULZ Design Hub · ronda destilacion/r01

| Campo | Valor |
|---|---|
| Superficie | patrón `origin-allocation` y pantalla `destilacion`, ambos `candidate` 0.2.0 |
| Modo | **M2 Página** (2 fichas nuevas) + **M3 Sincronización** (`Screens/fermentacion.md` por la extracción, README, perfil `coco.data_contract`, sitio regenerado) |
| Fuentes | registry, código real (`AsignacionOrigenes.vue`, `modules/destilacion/*`), `coco-declaracion.md`, `lima-compuerta.md`, evidencia `destilacion-r01` y `fase5-offline` |
| Modifica producción | No |

## Verificado

- Header y lifecycle de las 2 fichas = registry; API = props/emits/expose
  reales.
- Preview: demo real de `origin-allocation` (`build:hub`) y galería de 37
  capturas para la pantalla.
- Nada no implementado como hecho: puntas encendidas, varios colectores de
  la misma clase, foto real de un corte y operador real quedan en «No
  verificado».
- `pnpm build:hub-site` y `qa/enlaces-hub.mjs`: 0 enlaces rotos.

## Corregido automáticamente

- `Screens/fermentacion.md`: la formulación ahora usa `origin-allocation`.
- README: piezas y evidencia nuevas.

## Derivado fuera de mora

- `DUDAS.md` #15 (vinazas; anulación de cortes).

## No ejecutado

- Lector de pantalla y zoom nativo (para Stable).
