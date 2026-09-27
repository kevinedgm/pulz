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

## De negocio (§18 de `PULZ_MAESTRO.md`)

Las 9 preguntas de §18 (escala de actividad/dulzor/acidez, precio del plan,
límites del plan Gratis, si el operador registra maguey, rangos de aviso de
% Alc. y Brix, folio de certificado, dominio definitivo, hook de intentos de
Supabase) se resuelven con el supuesto que ya trae esa tabla. No se repiten
aquí; se referencian por número cuando una fase los toque de verdad
(Fase 1 para escalas y esquema, Fase 7 para precio y límites, Fase 3 para el
hook de intentos).
