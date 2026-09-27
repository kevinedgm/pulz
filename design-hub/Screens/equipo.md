# Equipo · `equipo`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/modules/equipo/pages/EquipoPage.vue`, `api.ts`, `routes.ts`; base: `supabase/migrations/20260927000023_equipo_miembros.sql`; escritura: Edge Function `manage-member` |
| Ruta | `/e/:slug/equipo` (privada; solo el administrador ve la lista) |
| Pruebas | `supabase/tests/equipo_miembros.test.sql` (12/12), `qa/evidencia-acceso.mjs` |
| Evidencia | `qa/evidence/acceso-r01/equipo-*`, `equipo-menu-*`, `equipo-alta-*`, `equipo-sin-permiso-*` |

## Propósito

El administrador ve quién puede entrar a su empresa y qué puede hacer, da de
alta a una persona en **un solo paso** eligiendo cómo le entrega el acceso, y
cambia rol, suspende/reactiva, desbloquea o manda un enlace nuevo.

## Ruta, entradas y salidas

- Desde Inicio: enlace «Equipo» (solo visible al admin) · ruta «Inicio /
  Equipo» arriba.
- Lectura: `equipo_miembros(p_org)` (función security definer; rechaza si no
  eres admin activo).
- Escritura: `manage-member` con `accion` = alta | rol | estado | desbloquear
  | reenviar. Tras cada cambio se recarga la lista.
- No admin por URL → estado **«Solo el administrador puede ver el equipo»**
  (no es un guardia del router; excepción aceptada por lima).

## Componentes usados

`list-stack` · `row-menu` · `status-chip` · `task-layer` ×4 · `segmented-choice`
×2 · `text-field` ×3 (búsqueda, nombre, usuario) · `password-field` (dictada)
· `button` · `state-block` (vacío, error, sin permiso) · `banner` (offline,
readonly) · `Icono i-mas`.

## Lista

Columnas: Nombre (con nota: «titular · entra con su correo» / «debe cambiar
la contraseña dictada») · Usuario (`code`, «—» para el titular) · Rol · Estado
(chip + nota «enlace vigente · vence en N días» / «enlace vencido o usado» /
«bloqueado por intentos») · Acciones. Filtro local «Buscar por nombre o
usuario».

Menú por fila — solo las acciones que aplican: «Cambiar rol…» siempre;
«Mandar enlace nuevo» si invitado; «Desbloquear» si `locked_until` > ahora;
«Reactivar» si suspendido; «Suspender…» (danger) si activo/invitado.

## Capas de tarea

| Capa | Contenido | Resultado |
|---|---|---|
| **Agregar persona** | Nombre · Usuario para entrar (ayuda: minúsculas, números, punto o guion, 3–30; no es un correo) · Rol (segmento 3, con ayuda por rol) · ¿Cómo le entregas el acceso? (Enlace por WhatsApp / Contraseña dictada → campo de contraseña temporal) · Crear acceso + Cancelar | → capa «Listo: acceso para {nombre}» |
| **Listo: acceso para {nombre}** | enlace: «Mándale este enlace por WhatsApp. Sirve una vez y vence en 72 horas.» + la URL + «Copiar enlace» (primary) + «Compartir…» (solo si `navigator.share` existe) + «Copiado ✓» (`role=status`); dictada: «Dile su usuario y la contraseña que escribiste. La primera vez que entre tendrá que cambiarla.» | Cerrar |
| **Rol de {nombre}** | segmento de rol + Guardar rol | recarga |
| **¿Suspender a {nombre}?** | confirmación corta: Suspender (danger) + Cancelar | recarga |

Cerrar la alta con datos escritos pregunta «¿Descartar lo que escribiste?»
(`confirm` nativo).

## Estructura por dispositivo

| | compact (<600) | medium (600–1023) | expanded (≥1024) |
|---|---|---|---|
| Lista | apilada (tarjeta por persona) | apilada | tabla de 5 columnas |
| Agregar persona | primaria page-primary; capa = hoja inferior | en cabecera; capa = drawer 420 | igual |
| Menú de fila | hoja inferior | popover | popover |

Sin menú lateral de la app en esta ronda (la navegación de la app es otra
ronda; kiwi lo declaró).

## Estados

| Estado | Qué se ve |
|---|---|
| Cargando | esqueleto con la misma huella de la lista (`aria-busy`) mientras responde `equipo_miembros` |
| Vacío | `state-block empty` «Solo estás tú» con la primaria dentro; la de cabecera baja a secundaria |
| Error de carga | `state-block error` «No pudimos cargar al equipo» + Reintentar |
| Sin permiso | `state-block denied` con «Pídele a quien administra {empresa}…» |
| Sin conexión | banner; sin acciones de escritura |
| Solo lectura | banner «puedes ver el equipo, no cambiarlo»; sin menú de fila ni alta |
| Formato de usuario inválido | error bajo el campo «Minúsculas, números, punto o guion (3 a 30).» al salir del campo |
| Rechazo de `manage-member` (p. ej. usuario duplicado, 409) | mensaje de la función en `role=alert` dentro de la capa; lo escrito se conserva |

## Criterios de aceptación verificados

Lista real con la semilla (3 personas) en 4 anchos × 2 temas; menú por fila
con acciones condicionales y Esc devolviendo el foco; alta hasta «Crear
acceso» con confirmación de descarte; productora sin enlace «Equipo» y con
estado «Sin permiso» por URL; sin desborde al 200 %.

## No verificado

- Alta, cambio de rol, suspensión, reactivación, desbloqueo y reenvío **desde
  la pantalla** (escriben en el proyecto alojado; `manage-member` tiene smoke
  por `curl`, 13 casos).
- «Desbloquear» nunca aparece con la semilla: el bloqueo por intentos depende
  de un hook que **no está en el plan** (`docs/DUDAS.md` #9).
- Vacío real («Solo estás tú») solo en el Hub; `Compartir…` depende del
  navegador; paginación por 50 no implementada.
