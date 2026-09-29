# PULZ · Dudas abiertas

> No bloquean el arranque (§0.1.4 y §18 de `PULZ_MAESTRO.md`). Se implementa
> el supuesto y se deja configurable o fácil de cambiar.

## De entorno (Fase 0)

1. **`supabase start` sin Docker.** ~~La máquina de desarrollo no tenía
   Docker, Colima ni Podman instalados~~ — se instaló Colima, se le dio más
   memoria/CPU y `supabase start` sí llegó a levantar el stack completo
   (Postgres, Auth, Storage, Studio, etc.) en local. Pero el dueño pidió
   explícitamente desinstalar Colima y trabajar directo contra el proyecto
   Supabase alojado (`https://ypgeiyorgktshgbzhgfh.supabase.co`, variables en
   `apps/web/.env.local`, no versionado), gestionado desde su propio panel
   web. Esto es una desviación deliberada, no temporal, de §8.4 ("local:
   `supabase start`") — ver `docs/DECISIONES.md`.

   **Resuelto** (ver `docs/plan/FASE-1.md`): el dueño decidió usar
   directamente `supabase db push`/`--linked` contra el proyecto alojado —
   es una instancia de desarrollo, no hace falta un segundo proyecto para
   pruebas. Se confirmó con `--help` real del CLI que `supabase db reset
   --linked` y `supabase test db --linked` existen y hacen exactamente lo que
   hacían sus equivalentes locales, apuntando al proyecto alojado. No se
   necesita Docker en ningún paso del ciclo de la Fase 1.

2. **Autenticación del CLI para `supabase link`.** **Resuelto**: el dueño
   corrió `supabase login` en su terminal; con eso `link`, `db reset
   --linked`, `db query --linked` y `db push` funcionan desde esta sesión.
   Nunca hizo falta la contraseña de Postgres del proyecto ni un access token
   en el chat.

3. **`supabase test db --linked` necesita Docker aunque apunte al proyecto
   alojado.** **Resuelto sin Docker**: el pgTAP se corre como función a
   través de `supabase db query --linked -f …` (ver `docs/DECISIONES.md`).
   Queda como nota para no volver a intentar `supabase test db`.

4. **Escala de actividad/dulzor/acidez** (§18 #1): se implementó 1–6 por
   CHECK. Si el dueño prefiere 1–10, es cambiar dos CHECK en
   `20260927000009_etapas.sql` y quitar el recorte de la semilla. Pendiente
   de confirmación, no bloquea.

5. **Concurrencia real (§16 Fase 2) — FAIL de infraestructura, no certificada.**
   El SQL histórico con `dblink` se bloqueó con `PRUEBA_REEMPLAZADA`: sus
   commits remotos no se revierten con el rollback exterior. No ejecutar
   transferencias contra la demo ni resetearla para limpiar una prueba.
   `pnpm test:db:concurrency` prepara un tenant desechable con UUID propios,
   dos sesiones y limpieza exacta. Los tres intentos del 2026-09-28 no
   observaron la barrera de la primera sesión; terminaron FAIL, todos con
   limpieza confirmada. No prueban un fallo ni un éxito del bloqueo de saldo.
   Una repetición directa del SQL de escritura fue rechazada por el control
   de seguridad; no se reintentó ni se eludió. Antes de nuevas escrituras,
   revisar mecanismo y obtener aprobación del alcance concreto de prueba.
   Evidencia y siguiente paso: [continuación](plan/CONTINUACION-2026-09-28.md).
   **Resuelto 2026-09-28.** La Management API no da dos sesiones (cada
   `db query` es una llamada aislada), así que la prueba se hizo por el
   camino real: dos usuarios con sesión propia (Auth) llamando a
   `transferir` por PostgREST a la vez, sobre un tenant desechable
   `qa-race-*` borrado por UUID. `pnpm test:rpc:concurrency` → 15/15: último
   litro (3 rondas), 10 simultáneas sobre 3 L → 3 OK, misma clave a la vez →
   una operación, escrituras independientes sin deadlock. Residuos 0.

9. **Hook de intentos de contraseña (§7.5, §18 #9) — RESPONDIDO: no está en
   el plan del proyecto.** `supabase config push` devolvió `402 "The
   following auth hooks cannot be configured for this organization:
   HOOK_PASSWORD_VERIFICATION_ATTEMPT"`. Queda apagado en `config.toml` (con
   el `uri` comentado, listo para cuando suban de plan) y el freno es el
   límite por IP de Supabase Auth. La función `auth_password_attempt`, la
   tabla `login_throttle` y `desbloquear_miembro` se quedan: no estorban y
   funcionan el día que el hook exista. **Consecuencia**: el criterio de
   aceptación "5 fallos bloquean y el admin desbloquea" de §16 Fase 3 **no se
   puede cumplir** en este plan; se marca como no comprobable, no como
   pasado.

10. **Protección contra contraseñas filtradas (HaveIBeenPwned).** Los
    advisors de Supabase la recomiendan (`auth_leaked_password_protection`).
    Es un ajuste de Auth en el panel del proyecto; puede depender del plan.
    Pendiente de que el dueño lo active si su plan lo permite; no bloquea.

11. **Bienvenida por enlace: la persona no queda dentro tras elegir su
    contraseña.** La Edge Function `set-password` con token fija la
    contraseña y devuelve `{ok, slug}`, pero no abre sesión (el token del
    enlace no es una sesión de Supabase Auth, y el navegador no conoce el
    usuario sintético `<username>@<org>.usuarios.pulz.mx`, y el token no
    se puede consultar sin canjearlo). Hoy la pantalla de bienvenida, al
    terminar, muestra "Listo, ya tienes contraseña. Entra con tu usuario y
    la contraseña que acabas de elegir" y un botón "Ir a entrar" que lleva
    al portal `/e/<slug>`. Es un paso extra respecto a §7.3 ("elige su
    contraseña y entra") y el botón de la ronda de kiwi dice "Crear
    contraseña y entrar" aunque no entra. Opción barata: que `set-password`
    devuelva también el correo de acceso (`login_email`) para que el
    cliente haga `signInWithPassword` de inmediato con la contraseña recién
    elegida y llegue a `/inicio` sin tocar nada más. **Resuelto (dueño,
    2026-09-27, Fase 4): sí, sesión automática.** `set-password` devuelve
    `login_email` al canjear el token y `BienvenidaPage` entra con él; si el
    inicio de sesión fallara (red), cae al portal con el usuario listo.

12. **Token `--pend` (ámbar) en modo claro no alcanza 4.5:1 como texto.**
    Al evaluar la compuerta Candidate, lima midió el contraste real de los
    pares de tokens que usan las piezas: todos pasan (claro y oscuro) salvo
    `--pend #C17A18` sobre `--pend-bg #FBEEDB` = **3.03:1** (texto necesita
    4.5). En oscuro da 7.27. Mitigación ya aplicada en las piezas: el texto
    del chip "invitado" va en `--text` y el ámbar queda en borde y punto (el
    aviso "Sin conexión" ya usaba `--text`). Decisión del dueño (es un valor
    de §13.4): si quiere ámbar como texto, cambiar `--pend` en claro a
    `#8F5A10` (5.05:1 sobre `--pend-bg`, 5.77 sobre blanco) en
    `apps/web/src/shared/ui/tokens.css`. No bloquea.

## De negocio interpretadas en la Fase 2 (implementado el supuesto; fácil de cambiar)

6. **Folios automáticos**: prefijo por material o etapa + consecutivo por
   empresa (`MAG-001`, `AC-001`, `F-001`, `FER-001`, `HOR-001`, `DES-001`,
   `MEZ/ORD/COL/PUN-001`, `G-001`). El usuario puede dar folio propio y el
   contador lo salta. La simulación usa folios "a mano" en varios lados
   (`FER-T1-001`, `G-2609-01`, `G-INI-01`); no se intentó adivinar esos
   formatos. ¿Quiere el dueño un formato por defecto distinto (p. ej. con
   tina o con fecha)?
7. **Tina "que ya fermentaba"** entra con `registrar_entrada('fermentado', tina, litros)`
   y abre un ciclo sin formulación (`formulation_id` nulo), como en la
   simulación. Confirmar que no hace falta pedir más datos ahí.
8. **`corregir_operacion`** corrige solo metadatos (nota, contraparte,
   documento, fecha en que ocurrió); los volúmenes no se tocan nunca, se
   ajustan con `registrar_movimiento_granel` (Ajuste de inventario ±). Si el
   dueño quería poder "corregir litros" de una operación, hay que decidir si
   eso es un movimiento de ajuste ligado a la original (propuesta) o algo
   más.

## De la Fase 5 (implementado el supuesto; fácil de cambiar)

13. **Recordatorio diario de medición** (`measurement_reminder_hour`): no hay
    notificaciones push en esta fase (necesitaría un servidor de push o un
    cron con tokens por dispositivo). Inicio/hoy usa la hora solo para
    ordenar «toca medir». ¿Quiere el dueño push (costo: servicio externo y
    permiso del teléfono) o basta con el recordatorio al abrir la app?
14. **Fotos como evidencia**: solo en medición y corte, opcionales, una por
    captura, reducidas a 1600 px, tipo «Foto» del catálogo `tipo_adjunto`.
    ¿Hacen falta en otras operaciones (recepción de maguey, compra de
    granel ya tiene «Remisión o factura» por Storage)?

15. **Cortes y vinazas**: un corte no se anula (no hay RPC; se corrige con
    un ajuste en Granel). La diferencia entre lo cargado y lo cortado
    (vinazas, pérdida) se ve en la corrida pero no se guarda como lote.
    ¿Quiere el dueño un campo «vinazas» al cerrar, o anular cortes con
    motivo como las mediciones? (cambio de esquema: 0009/0018).

16. **Tema oscuro perdido en Foundations 1.0.0** (detectado 2026-09-28 en r06
    de Maguey/Horneado): `apps/web/src/shared/ui/tokens.css` se regeneró
    desde `.fruti/tokens.json` y ya no trae `prefers-color-scheme: dark` ni
    `[data-theme="dark"]`; `app/tema.ts` sigue escribiendo `data-theme` sin
    efecto. El tema oscuro existe solo en `docs/referencia/pulz-tokens.css`
    (semilla anterior). Decidir: reincorporar la escala oscura a Foundations
    (ronda propia, la base está «approved») o retirar el conmutador del shell
    mientras tanto. Hasta entonces «oscuro» = «claro» en toda la app.
    **Resuelto 2026-09-28** (pedido del dueño): `tokens.css` recupera el tema
    como overrides de roles semánticos y alias (`color.dark` en
    `.fruti/tokens.json`); los roles base aprobados no cambian. Verificado con
    `design-hub/qa/tema-oscuro.mjs` (20/20).

17. **Aviso de Brix: la app avisa cualquier día, el servidor solo lo
    registra el día ≤ 1** (detectado 2026-09-28 en el E2E de Fase 5).
    `registrar_medicion` (0017) marca `brix_fuera_rango` solo cuando
    `p_dia <= 1` («Brix inicial», §2.1); `MedirPage` (`avisoBrix`) pide la
    nota en cualquier día, así que del día 2 en adelante la nota viaja en la
    operación pero no queda como aviso. Decidir: que la app avise solo el
    día 1 (como el servidor) o que el servidor registre el aviso todos los
    días. Hasta entonces se implementa lo que hay.
    **Resuelto 2026-09-28** (decisión del dueño): la app se alinea al
    servidor — `avisoBrix(brix, ajustes, dia)` solo avisa con día ≤ 1.

## De negocio (§18 de `PULZ_MAESTRO.md`)

Las 9 preguntas de §18 (escala de actividad/dulzor/acidez, precio del plan,
límites del plan Gratis, si el operador registra maguey, rangos de aviso de
% Alc. y Brix, folio de certificado, dominio definitivo, hook de intentos de
Supabase) se resuelven con el supuesto que ya trae esa tabla. No se repiten
aquí; se referencian por número cuando una fase los toque de verdad
(Fase 1 para escalas y esquema, Fase 7 para precio y límites, Fase 3 para el
hook de intentos).
