# PULZ · Dudas abiertas

> No bloquean el arranque (§0.1.4 y §18 de `PULZ_MAESTRO.md`). Se implementa
> el supuesto y se deja configurable o fácil de cambiar.

## De entorno (Fase 0)

1. **`supabase start` sin Docker.** La máquina de desarrollo no tenía Docker,
   Colima ni Podman instalados (confirmado con
   `docker: command not found (podman also not found)` al correr
   `supabase start`). Mientras se decide si se instala Docker Desktop o
   Colima, el desarrollo apunta directo al proyecto Supabase alojado
   `https://ypgeiyorgktshgbzhgfh.supabase.co` (variables en
   `apps/web/.env.local`, no versionado). Esto es una desviación temporal de
   §8.4 ("local: `supabase start`"); se retoma el flujo local en cuanto haya
   un runtime de contenedores disponible, sobre todo para la Fase 1
   (migraciones + pgTAP necesitan Postgres local para poder resetear la base
   en cada corrida sin arriesgar el proyecto alojado).

## De negocio (§18 de `PULZ_MAESTRO.md`)

Las 9 preguntas de §18 (escala de actividad/dulzor/acidez, precio del plan,
límites del plan Gratis, si el operador registra maguey, rangos de aviso de
% Alc. y Brix, folio de certificado, dominio definitivo, hook de intentos de
Supabase) se resuelven con el supuesto que ya trae esa tabla. No se repiten
aquí; se referencian por número cuando una fase los toque de verdad
(Fase 1 para escalas y esquema, Fase 7 para precio y límites, Fase 3 para el
hook de intentos).
