# Cambio obligatorio de contraseña · `acceso-cambio-contrasena`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/modules/acceso/pages/CambiarContrasenaPage.vue`, `components/PantallaAcceso.vue`, `api.ts` (`fijarContrasena`) |
| Ruta | `/e/:slug/cambiar-contrasena` (privada) |
| Pruebas | `qa/evidencia-acceso.mjs` (tomas.h → redirección obligatoria, aun pidiendo `/inicio`) |
| Evidencia | `qa/evidence/acceso-r01/cambiar-contrasena-*` |

## Propósito

Quien entró con una **contraseña dictada** (`mis_membresias.must_change_password`)
pone una suya antes de cualquier otra cosa.

## Ruta, entradas y salidas

- El guardia del router manda aquí a cualquier ruta privada mientras la
  bandera esté en `true`.
- «Guardar contraseña» → `POST /functions/v1/set-password` con la sesión
  (`{contrasena}`); **la bandera la baja el servidor**. Éxito → recarga
  membresías → `/inicio`.
- Única salida alternativa: «Cerrar sesión» (quiet) → portal. **No hay
  Cancelar ni Volver** (contrato).

## Componentes usados

`password-field` ×2 (`new-password`; ayuda «Mínimo 8 caracteres.») ·
`button` (Guardar contraseña = primary page-primary submit; Cerrar sesión =
quiet; Reintentar = secondary) · `banner` (offline) · `state-block` (error de
red).

## Estructura por dispositivo

Misma tarjeta de `PantallaAcceso` que el portal: ancho completo + barra
inferior en compact; 440 px centrada en el resto.

## Estados

| Estado | Disparador | Qué se ve |
|---|---|---|
| Inválido | al salir del campo: <8 o no coinciden | error bajo el campo («Mínimo 8 caracteres.» / «No coinciden. Escríbela igual dos veces.»); Guardar no envía |
| Enviando | submit válido | `loading`, campos deshabilitados |
| Rechazo del servidor | `set-password` 4xx | `role=alert` con el mensaje de la función |
| Sin red | fetch falla | `state-block error` + Reintentar; lo escrito se conserva |
| Sin conexión | `onLine=false` | banner; Guardar deshabilitado con motivo |

## Criterios de aceptación verificados

- Con `must_change_password=true` no se puede llegar a `/inicio` (Playwright
  8/8 con `tomas.h`).
- Sin desborde en 4 anchos y al 200 %.

## No verificado

El envío real desde la pantalla (cambiaría la contraseña de la semilla; la
función tiene smoke por `curl`, commit `83d4a3c`).
