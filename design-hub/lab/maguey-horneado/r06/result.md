# Maguey/Horneado r06 · resultado

**PARTIAL · draft 0.2.1 · 2026-09-28. No Candidate, Stable ni release.**
Ronda de aceptación sobre r05 (Coco prueba, Lima dictamina); nada de r05 se
reescribe. Un solo frente; FilaUso y Foundations sin cambios.

## Resuelto en r06

- Bloque 15 completo: 37/37 pruebas de negocio alojadas con tenants
  desechables (`evidence/hosted-api.json`) y 19/19 de interfaz para
  instantánea/reconexión e intenciones particionadas
  (`evidence/ui-15-12-15-13.json`).
- Bloque 16 salvo hardware/AT: 132/132 en `evidence/a11y-14-03-16.json`
  (`node design-hub/qa/a11y-mh-r06.mjs`): recorridos completos por teclado con
  escrituras reales, 200 %, forced-colors, contraste y movimiento, contenido
  extremo. 14.03 cerrado en el shell autenticado.
- Defectos encontrados y corregidos con evidencia posterior: sin señal la
  página pedía volver a entrar en lugar de mostrar la instantánea
  (`ProcesoSolidoPage`); chip `on`/`partial` y borde del botón secundario por
  debajo de AA (`ChipEstado`, `Boton`).

## Verificaciones

| Verificación | Resultado |
|---|---|
| Aplicación local | 183/183 PASS (excluye `**/*.integracion.test.ts`); tipos y lint PASS |
| Negocio alojado (API) | 37/37 PASS, limpieza 0 restantes, huella previa idéntica |
| Interfaz alojada 15.12/15.13 | 19/19 PASS |
| Accesibilidad 14.03 + 16.02/05/06/08/09 | 132/132 PASS |
| 16.03 touch físico · 16.04 teclado virtual · 16.07 lector de pantalla | **BLOCKED**: sin medio real; «no disponible» no es PASS. Simulador de iOS descartado (ver `pruebas-fisicas.md`); guion para el dueño listo |

## Seis dimensiones

| Dimensión | Resultado | Alcance |
|---|---|---|
| technical | PASS | Local + negocio alojado + interfaz alojada |
| structural | PASS | Geometría r05 intacta; 14.03 en shell autenticado |
| visual | PASS | Sin regresión de composición; dos correcciones de contraste |
| accessibility | PARTIAL | Teclado, zoom, forced-colors, contraste, extremos PASS; tacto/teclado virtual/lector pendientes |
| design_system | PASS con nota | `ChipEstado` y `Boton` cambian por medición; fichas del Hub actualizadas; sin tema oscuro en Foundations 1.0.0 (DUDAS #16) |
| documentation | PASS | Checklist, ESTADO, DECISIONES, DUDAS y fichas sincronizados |

## Dictamen (17.09)

Se **devuelve con aceptación parcial**: no queda ningún ítem abierto que
pueda cerrarse desde este entorno. La aceptación completa exige 16.03, 16.04
y 16.07 con hardware y tecnología de asistencia reales. Candidate y Stable
siguen no elegibles hasta entonces; el frente no abre otro ni despliega.

## Residuos y limpieza

Escrituras en cuatro-vientos durante r06 (recepciones de 123 kg y de 1 kg,
horneadas HOR-002/003, cierre 0.5 kg, cocido 0.25 kg) se retiran con
`supabase db reset --linked --yes` al cerrar la ronda (CLAUDE.md §2).
