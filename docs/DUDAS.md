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

   **Sigue abierto**: cómo va a funcionar la Fase 1 (`supabase db reset` +
   pgTAP) sin un Postgres local que se pueda resetear libremente. Opciones a
   decidir cuando se llegue ahí: (a) un segundo proyecto Supabase alojado solo
   para pruebas, separado del de desarrollo; (b) retomar Colima/Docker solo
   para el ciclo de pruebas, sin usarlo para el día a día; (c) otra cosa que
   se decida entonces. No se decide ahora porque no bloquea la Fase 0.

## De negocio (§18 de `PULZ_MAESTRO.md`)

Las 9 preguntas de §18 (escala de actividad/dulzor/acidez, precio del plan,
límites del plan Gratis, si el operador registra maguey, rangos de aviso de
% Alc. y Brix, folio de certificado, dominio definitivo, hook de intentos de
Supabase) se resuelven con el supuesto que ya trae esa tabla. No se repiten
aquí; se referencian por número cuando una fase los toque de verdad
(Fase 1 para escalas y esquema, Fase 7 para precio y límites, Fase 3 para el
hook de intentos).
