# Portal e inicio de sesión (+ 404) · `acceso-portal`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` (brief, 3 user flows, wireframe F2) |
| Código | `apps/web/src/modules/acceso/pages/PortalPage.vue`, `NoEncontradoPage.vue`, `components/PantallaAcceso.vue`, `components/MarcaPortal.vue`, `store.ts`, `api.ts`, `apps/web/src/app/router.ts` |
| Rutas | `/e/:slug` (pública) · `/e/:slug/no-encontrado` · cualquier otra ruta → 404 |
| Pruebas | `acceso/__tests__/api.test.ts`, `rechazos.integracion.test.ts` (real contra el proyecto alojado), `qa/evidencia-acceso.mjs` |
| Evidencia | `qa/evidence/acceso-r01/portal-*`, `portal-rechazo-*`, `portal-ayuda-*`, `no-encontrado-*` |

## Propósito

Que cualquier persona del palenque entre en menos de 20 s con **un solo
campo** («Usuario o correo»), sin saber qué es un correo sintético, y que la
empresa se reconozca por su marca antes de entrar.

## Ruta, entradas y salidas

- Entrada: `pulz.mx/e/<slug>` (la Pages Function ya resolvió 301 de slugs
  viejos; el router repite la regla con `redirect_to`).
- Sin fila en `portal_branding` (inexistente o cancelada) → `/e/<slug>/no-encontrado`,
  **sin marca ni pistas**.
- Con sesión y membresía activa → `/inicio` (o `/cambiar-contrasena` si
  `must_change_password`).
- Entrar: `signInWithPassword` **directo** con `correoDeAcceso(org_id, valor)`
  (con «@» = correo real del titular; sin «@» = `usuario@<org_id>.usuarios.pulz.mx`).
  Éxito → `mis_membresias`; si no pertenece a **este** slug → cierra sesión y 404.
- «¿No puedes entrar?»: titular (con «@») → botón «Mandar correo de
  recuperación» (`resetPasswordForEmail`); colaborador → texto «Pídele a tu
  encargado…».
- Pie: «¿Aún no tienes PULZ? Conoce PULZ» → `https://pulz.mx` (enlace).

## Componentes usados

`text-field` (lg, `inputmode=email`, `autocomplete=username`) ·
`password-field` (lg, `current-password`) · `button` (Entrar = primary
page-primary `type=submit form=form-acceso`; quiet; secondary) · `banner`
(offline / readonly) · `state-block` (error de red con Reintentar). Marca:
bloque local `MarcaPortal` (logo 56 px o monograma, nombre, mensaje ≤140;
`brand_color` solo como línea superior y monograma).

## Estructura por dispositivo

| | compact (<600) | medium / expanded |
|---|---|---|
| Tarjeta | ancho completo, sin borde, `min-height: 100vh`, `padding-bottom` para la barra | 440 px centrada, borde, sombra |
| Entrar | barra inferior persistente (área segura) | dentro del formulario |
| Marca | logo + nombre + mensaje, texto envuelve | igual |

## Estados

| Estado | Disparador | Qué se ve |
|---|---|---|
| Rechazo | cualquier fallo de Auth (usuario inexistente, contraseña mala, otra empresa, cuenta suspendida) | **«Usuario o contraseña incorrectos»** (`role=alert`), contraseña vacía, foco en contraseña |
| Sin red | `fetch`/red falla | `state-block error` «No pudimos conectar» + Reintentar; lo escrito se conserva |
| Sin conexión (navegador) | `navigator.onLine=false` | `banner offline`; Entrar deshabilitado con motivo «Para entrar necesitas señal.» |
| Solo lectura | `portal_branding.read_only` | `banner readonly` |
| Enviando | submit | Entrar `loading`, campos deshabilitados |
| Recuperación | titular pulsa el botón | `role=status` «Listo. Revisa tu correo.» / `role=alert` si falla |
| Último usuario | `localStorage pulz:ultimo-usuario:<slug>` | el campo se precarga |

## Criterios de aceptación verificados

- Cuatro rechazos → el mismo texto exacto (Vitest integración real, 4/4).
- Titular entra y ve su membresía (integración real).
- Slug viejo → slug actual; ruta privada sin sesión → portal; 404 idéntico
  (Playwright 8/8).
- Sin desborde en 1440/1024/768/390 y con texto al 200 %.

## No verificado

Recuperación por correo de punta a punta (manda un correo real); cuenta
suspendida real (la semilla no tiene); **bloqueo por 5 intentos** — el hook
no está en el plan (`docs/DUDAS.md` #9): no existe, no se documenta.
