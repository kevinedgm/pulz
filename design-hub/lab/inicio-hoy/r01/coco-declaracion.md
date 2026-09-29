# coco · Declaración de cumplimiento — ronda inicio-hoy/r01 (R3)

```text
Ruta: R3 (product-application inicio 0.3.0; sin piezas nuevas del sistema) — orden de lima
Brief funcional: el de kiwi, vigente. Datos: Hoy = usos (tinas_en_uso) + ajustes + corridas abiertas + colectores_con_saldo + cola (useCola); sin data_contract nuevo (compone Fermentación, Destilación y ElementoCola ya registrados)
Reglas aplicadas:
  · Inicio es lectura + atajos: ninguna captura se hace aquí; Medir → /fermentacion/:ciclo/medir?volver=inicio (MedirPage vuelve a Hoy con ?aviso=medida); Cortar → /destilacion/:corrida/corte; Pasar a granel → /granel/transferir?origen=
  · una primaria: Medir de la tina más atrasada (agrupar.porMedir en el orden de Fermentación); en compact es el FAB del shell (meta.fab + fabAccion), nulo sin tinas por medir; la fila oculta su Medir en compact para no duplicar
  · la hora del recordatorio solo rotula (rotuloHora: «toca desde las 9:00» / «toca medir»); día N de M con diaDelCiclo y fermentation_expected_days; 8 filas y «y N más»
  · sin señal: cargarHoy compone las instantáneas de fermentación y destilación y muestra la más antigua; tieneLotes sin red no tumba la página; Medir y Cortar no dependen de enLinea; Abrir corrida / Llenar tinas / Pasar a granel piden admin|productor y señal (motivo visible)
  · Por enviar solo con cola no vacía: resumen · hora · pending / failed + motivo · Reintentar · Corregir (pantalla de origen con ?corregir=) o Descartar
  · vacíos con texto: Todo medido · Sin tinas fermentando · Sin corridas ni colectores · Hoy no hay nada pendiente; sin lotes → ¿Qué tienes hoy? → arranque (se conserva)
Excepciones: ninguna respecto a la ronda
Comprobado:
  · vue-tsc ✔ · eslint 0/0 ✔ · prettier ✔ · Vitest 193/193 ✔ (10 nuevas: puras + página con cola, permisos, instantánea, sin lotes)
  · Playwright qa/evidencia-inicio-hoy.mjs PASS (8 corridas = 4 anchos × 2 temas + operador; 41 capturas) con Aurelia en Cuatro Vientos tras db reset: Hoy con la semilla («2 tinas por medir · sin corridas · nada por enviar», Tina 3 antes que Tina 2, «1 lista para destilar», Colector colas 16 L con «Ver» y sin «Pasar a granel»); Medir desde Hoy → medición REAL por la cola (27.5 °C, 12.4 Brix, actividad 6) → «Volver a Inicio» → «Medición guardada.», Tina 2 fuera de Toca medir, «1 tina ya medida hoy · 1 lista para destilar»; sin señal: «Mostrando datos guardados el …» y Medir sigue activo; Tomás (operador, tras el cambio obligatorio de contraseña): Medir sí, sin Abrir corrida ni Pasar a granel; primaria única (FAB en compact, botón en ≥600); sin desborde
  · capturas revisadas a ojo: hoy 1440 claro, 390 oscuro, sin señal 1440, tras medir 1440
Auditoría arquitectónica (manual):
  · InicioEmpresaPage: compone dos cargas existentes; sin lógica de dominio propia (agrupar/diaDelCiclo/haceCuanto vienen de sus módulos). Health: sano.
  · Filas locales (FilaTinaHoy, FilaCorridaHoy, FilaColectorHoy, FilaColaHoy): presentación pura por props; FilaColaHoy es candidata a `queue-item` si aparece un tercer consumidor (anotado por lima).
  · fabAccion se fija desde un watch (no useFab) porque depende de los datos: comentado en la página.
  · Findings:
    - MEDIUM · AUTO_FIX (hecho) — sin red, tieneLotes tumbaba Hoy antes de leer las instantáneas: ahora un fallo de red pasa directo a cargarHoy (test).
    - LOW · AUTO_FIX (hecho) — los enlaces de cabecera de bloque heredaban las mayúsculas del rótulo.
    - LOW · NO_ACTION — en la evidencia, los módulos se precargan navegando dentro de la app antes de cortar la red (el dev server no tiene SW), igual que e2e-offline.
No pudo comprobarse: cola con fallo real (se cubre por Vitest y por las rondas de fermentación/destilación); antes de la hora del recordatorio en el navegador real (pura con test); lector de pantalla; zoom nativo.
Siguiente paso: lima (compuerta Candidate) → mora → E2E proceso completo (tarea 8).
```
