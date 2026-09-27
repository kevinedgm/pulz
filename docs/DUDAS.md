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

5. **Prueba de concurrencia (§16 Fase 2) — pendiente de dos sesiones
   reales.** `supabase/tests/rpc_concurrencia.test.sql` la hace con `dblink`,
   pero Supabase alojado exige contraseña para abrir la segunda sesión y esa
   contraseña nunca se ha pedido. Queda en **SKIP** (no en verde). Para
   probarla de verdad, el dueño puede hacerlo él mismo con dos terminales de
   `psql` contra la cadena de conexión del proyecto (Project Settings →
   Database), pegando en cada una, casi al mismo tiempo:

       select set_config('request.jwt.claims',
         '{"sub":"a88771d6-e323-5b36-991d-c42e5880e507","role":"authenticated"}', false);
       select transferir('b66cf468-47f7-51ee-a8f2-994d907440b9', gen_random_uuid(), now(),
         (select id from resources where code = 'Tanque 1'), (select id from resources where code = 'Tanque 2'),
         (select id from lots where folio = 'G-COMPRA-01'), 250, null, 'conservar');

   Una debe regresar el id del lote y la otra fallar con
   `SALDO_INSUFICIENTE:`. Después, `supabase db reset --linked` deja todo
   como estaba. Alternativa: dar la contraseña de Postgres del proyecto para
   que el test con `dblink` la use (es un secreto de cuenta; mejor la opción
   de las dos terminales).

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

## De negocio (§18 de `PULZ_MAESTRO.md`)

Las 9 preguntas de §18 (escala de actividad/dulzor/acidez, precio del plan,
límites del plan Gratis, si el operador registra maguey, rangos de aviso de
% Alc. y Brix, folio de certificado, dominio definitivo, hook de intentos de
Supabase) se resuelven con el supuesto que ya trae esa tabla. No se repiten
aquí; se referencian por número cuando una fase los toque de verdad
(Fase 1 para escalas y esquema, Fase 7 para precio y límites, Fase 3 para el
hook de intentos).
