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

2. **Autenticación del CLI para `supabase link`.** `supabase link
   --project-ref ypgeiyorgktshgbzhgfh` pide `supabase login` (interactivo, no
   se puede completar en una sesión no interactiva) o
   `SUPABASE_ACCESS_TOKEN`. Pendiente de que el dueño corra `supabase login`
   en su propia terminal (recomendado) o dé un personal access token para
   exportarlo en la sesión. Bloquea las tareas 6–9 de `docs/plan/FASE-1.md`,
   no las tareas 1–5 (escribir las migraciones sí se puede hacer sin estar
   enlazado).

## De negocio (§18 de `PULZ_MAESTRO.md`)

Las 9 preguntas de §18 (escala de actividad/dulzor/acidez, precio del plan,
límites del plan Gratis, si el operador registra maguey, rangos de aviso de
% Alc. y Brix, folio de certificado, dominio definitivo, hook de intentos de
Supabase) se resuelven con el supuesto que ya trae esa tabla. No se repiten
aquí; se referencian por número cuando una fase los toque de verdad
(Fase 1 para escalas y esquema, Fase 7 para precio y límites, Fase 3 para el
hook de intentos).
