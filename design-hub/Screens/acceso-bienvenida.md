# Bienvenida por enlace · `acceso-bienvenida`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/modules/acceso/pages/BienvenidaPage.vue`, `components/PantallaAcceso.vue`, `api.ts` (`fijarContrasena(contrasena, token)`) |
| Ruta | `/e/:slug/bienvenida#<token>` (pública, sin sesión) |
| Pruebas | `qa/evidencia-acceso.mjs` (formulario con token de ejemplo; sin token → inválido) |
| Evidencia | `qa/evidence/acceso-r01/bienvenida-*`, `bienvenida-invalido-*` |

## Propósito

La persona que recibió un enlace por WhatsApp elige su contraseña. El token
viaja en el **fragmento** (`#`): nunca llega al servidor del portal; solo
`set-password` lo canjea (72 h, un solo uso).

## Ruta, entradas y salidas

- Entrada: el enlace que el administrador copió desde Equipo.
- «Crear contraseña y entrar» → `POST set-password` `{contrasena, token}` →
  éxito: el token sale de la URL (`replaceState`) y se muestra «Listo, ya
  tienes contraseña» + botón «Ir a entrar» → portal.
- Sin token, token inválido, usado o vencido → **un solo mensaje**: «El
  enlace no es válido o ya se usó» + «Pídele a tu encargado que te mande uno
  nuevo.» + «Ir al inicio de sesión». Sin distinguir causa.

> **No hecho:** la pantalla **no deja a la persona dentro**; después de crear
> la contraseña tiene que entrar en el portal con su usuario. El botón
> conserva el texto de la ronda («…y entrar»). Decisión pendiente en
> `docs/DUDAS.md` #11 (que `set-password` devuelva el correo de acceso).

## Componentes usados

`password-field` ×2 (`new-password`) · `button` (primary page-primary submit;
«Ir a entrar» primary; «Ir al inicio de sesión» secondary con `to`) ·
`state-block` (error: enlace inválido; error de red) · `banner` (offline).
No se muestra nombre ni usuario (no se pueden consultar sin canjear el token).

## Estructura por dispositivo

Tarjeta de `PantallaAcceso`; en compact el bloque de error no se estira
(corregido en la ronda).

## Estados

| Estado | Disparador | Qué se ve |
|---|---|---|
| Formulario | hay token en `#` | título «Te dieron acceso a {empresa}», dos campos |
| Inválido | sin token / respuesta `ENLACE` | state-block error con el mensaje único |
| Listo | `ok` | «Listo, ya tienes contraseña» + «Ir a entrar» |
| Sin red | fetch falla | state-block error + Reintentar; lo escrito se conserva |
| Validación | <8 / no coinciden | error bajo el campo |

## Criterios de aceptación verificados

Formulario y estado inválido en 4 anchos × 2 temas; sin desborde al 200 %;
mensaje único en texto exacto.

## No verificado

El canje real de un enlace desde la pantalla (crea/usa invitaciones en el
proyecto alojado; la función tiene smoke por `curl`).
