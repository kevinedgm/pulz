# coco · Declaración de cumplimiento — ronda destilacion/r01 (R3 + F3)

```text
Ruta: R3 (patrón origin-allocation extraído + product-application destilacion) — orden de lima
Brief funcional: el de kiwi, vigente. data_contract registrado en el perfil: Corrida, ColectorConSaldo, NuevaCorrida, NuevoCorte
Reglas aplicadas:
  · el colector se elige solo por la clase del corte (select si hay varios; bloqueo con enlace a Recursos si no hay); puntas solo con record_puntas (clasesDisponibles)
  · abrir y cerrar corrida van directas (señal); el corte entra SIEMPRE por la cola (encolarCorte) con idempotency_key y occurred_at; sin señal, lista y corrida desde la instantánea
  · avisos conocidos antes: capacidad estricta del alambique/colector bloquea con motivo (AsignacionOrigenes.bloqueo, avisoCapacidad); flexible pide nota (excede_capacidad); 2ª con ordinario y colas pide nota (mezcla_clases_2a) si warn_mixed_second_pass (avisosApertura)
  · AsignacionOrigenes (origin-allocation) extraída de FormularPage y reutilizada en Abrir corrida: total en vivo, «Total N de C (Alambique 1)», error por encima del saldo
  · una primaria por vista: Abrir corrida (FAB del shell en compact; botón en cabecera en ≥600, envuelto para esconderlo en compact); «Registrar corte» por corrida es secundaria; en la corrida «Registrar corte» page-primary; cerrar corrida con diálogo destructivo (Cancelar primaria) y espera del popstate de la capa antes de navegar
  · «Pasar a granel» = transferir (ronda granel): enlace a /granel?transferir=<colector> (Granel redirige a /granel/transferir?origen=); el operador ve quién lo hace
  · un corte no se anula: se dice en la corrida; un fallo de cola trae Corregir si pide nota o Descartar si no
  · fotos: cada RPC devuelve algo distinto (medición → id de la medición; corte → id del lote): fotos.ts resuelve operación y lote según la RPC
Excepciones: ninguna respecto a la ronda. segmented-choice con 3 (o 4 con puntas) opciones de clase, aceptado por lima
Comprobado:
  · vue-tsc ✔ · eslint 0/0 ✔ · prettier ✔ · Vitest 98/98 ✔ (6 nuevas de api puras + 2 de origin-allocation)
  · pnpm --filter @pulz/web build:hub ✔ (sección origin-allocation)
  · Playwright qa/evidencia-destilacion.mjs 8/8 ✔ (37 capturas, 1440/1024/768/390 × claro/oscuro) con Aurelia en Cuatro Vientos, escrituras REALES: DES-004 abierta en Alambique 1 con 290 L de la Tina 1 (lista); tres cortes por la cola (mezcal 8 @ 51 → Colector mezcal, ordinario 40 @ 24 → Colector ordinario, colas 12 @ 9 → Colector colas) «Corte guardado · enviado»; la corrida suma 60 L con los tres; colectores con contenido y «Pasar a granel»; FAB solo en compact; última corrida: cerrada con el diálogo real → «No hay corridas abiertas»
  · Playwright qa/e2e-offline.mjs ✔ (§16 Fase 5 completo: 3 mediciones y 2 cortes): con señal abre una corrida chica (20 L de Tina 1 en Alambique 2) y precarga Medir y Corte navegando dentro de la app; en modo avión 3 mediciones + 2 cortes (mezcal 2 @ 50, ordinario 5 @ 24) → «5 capturas pendientes de enviar» → señal → 5 operaciones una sola vez (count +5), claves únicas, recorded_at en el mismo orden que occurred_at, recargar no duplica; las 3 mediciones se anulan por SQL (declarado), los 2 cortes quedan hasta el db reset
  · capturas revisadas a ojo: lista 1440 claro/oscuro con corrida abierta y tres colectores
Auditoría arquitectónica (manual):
  · api.ts: puras sin Vue (clasesDisponibles, colectoresDeClase, saldoDe, avisoCapacidad, avisosApertura, resumenCortes); lecturas con instantánea en un solo conInstantanea (duplicado con fermentación: candidato a shared/offline/conInstantanea en la siguiente ronda, LOW). Health: sano.
  · CortePage: mismo esqueleto que MedirPage (pasos, corrigiendo, resultado). Health: sano; si aparece un tercer flujo por pasos, extraer el «resultado de captura» (caja enviado/pendiente/fallo + acciones) como pieza.
  · AsignacionOrigenes: sin dominio; expone total/bloqueo/aviso/conError. Health: sano.
  · Findings:
    - MEDIUM · AUTO_FIX (hecho) — CorridaPage navegaba al cerrar la corrida antes del popstate de la capa (DECISIONES shell/r01): se espera.
    - LOW · NO_ACTION — conInstantanea duplicado en fermentacion/destilacion/granel: extraer en la ronda de horneado.
    - LOW · NO_ACTION — getByText("Colectores con contenido") coincidía también con el resumen «3 colectores con contenido»: la evidencia espera el heading.
    - INFO — quedan en Cuatro Vientos DES-004 (cerrada, 60 L cortados), la corrida chica del e2e (abierta, 7 L cortados) y sus cortes hasta el db reset.
No pudo comprobarse: puntas con record_puntas (por Vitest); varios colectores de la misma clase (por tipos); foto real de un corte por la cola; lector de pantalla; zoom nativo; operador real en Playwright (Tomás debe cambiar la contraseña al entrar: por rpc_guard y tipos).
Siguiente paso: lima → mora → ronda granel/r01 (ya en construcción).
```
