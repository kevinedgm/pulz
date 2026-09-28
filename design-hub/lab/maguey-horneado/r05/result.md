# Maguey/Horneado r05 · resultado

**PARTIAL · draft0.2.1 · 2026-09-28. No Candidate, Stable ni release.**
Ronda independiente: Kiwi → Lima → Coco → Lima → Mora.
Decisiones autónomas autorizadas; ninguna aprobación de r04/current reutilizada.
Un solo frente, sin modificar FilaUso ni Foundations.

## Resuelto

- Navegación sin letra huérfana; rail160/240 e insets16/24 intactos.
- Cambio de persona invalida permisos/datos e intención; descarta membresías antiguas.
- Intenciones incompletas se conservan para revisión y no se reenvían ni rompen la vista.
- Cocido identifica horneada, carga inicial o compra desde relaciones existentes.
- Instantánea offline muestra fecha/hora; escritura sigue bloqueada.
- Test del menú comprueba guion discrecional y nombre accesible.

## Verificaciones nuevas

| Verificación | Resultado |
|---|---|
| Aplicación local |183/183 PASS; excluye `**/*.integracion.test.ts` |
| Módulo M/H (incluido arriba) |34/34 PASS |
| Acceso alojado |5/5 PASS, ejecución separada autorizada explícitamente |
| Tipos + build app/PWA |PASS |
| Demo Vue + lint del alcance |PASS |
| Kiwi checker acotado |0 errores,1 aviso de panel de estados; excepción documentada |
| Navegador |320/390/600/768/1023/1024/1440 CSS reales, normal/largo |
| Teclado demo |Recepción123.456kg, apertura120.5kg, cierre100.25kg, entrada9.75kg; revisión/retorno, Más/detalle/Escape/foco |

Primer conjunto:174/175 por expectativa antigua del menú; corregida antes del
resultado final183/183. Clicks iniciales del arnés no cambiaron viewport:
medición invalidada y repetida con Enter. Capturas expanded recortadas se
completaron. No se usaron intentos fallidos como evidencia de aceptación.

## Seis dimensiones

| Dimensión | Resultado | Alcance |
|---|---|---|
| technical |PARTIAL |Local + acceso alojado PASS; negocio real pendiente |
| structural |PASS |Geometría actual en demo y componente compartido |
| visual |PASS |Corrección y composición local en7anchos, no sólo overflow |
| accessibility |PARTIAL |Teclado/DOM parciales; pruebas físicas/nativas pendientes |
| design_system |PASS |Foundations preservadas; tokens, Manrope y Lucide consumidos |
| documentation |PASS |Hub48fichas;121 enlaces/recursos,0 rotos,0 IDs duplicados; preview Vue real |

## No resuelto / criterio de desbloqueo

1. E2E alojado de operaciones, roles/RLS, linaje, Formulación, respuesta perdida
   postcommit y recuperación de señal. Requiere fixtures persistentes aislados
   autorizados y limpieza por IDs; permiso actual cubre sólo los cinco tests de acceso.
2. Touch físico, teclado virtual, texto200% nativo, forced-colors y lector de
   pantalla. Se necesita hardware/entorno apropiado; CSS/mocks no los sustituyen.
3. Barrido integral de accesibilidad y ciclo formal de refinamiento para Candidate.
   Stable no elegible sin Candidate. Autonomía de diseño no suprime gates.

Sin operaciones de negocio remotas, resets, migraciones, deploy ni otro frente.
Evaluación de gate completada no equivale a gate aprobado.

## Artefactos

- [Kiwi F2](kiwi-f2.html), [decisiones](kiwi-decisions.yaml), [brief](brief.md).
- [Contrato Lima](lima-contract.yaml), [dictamen](lima-f3-verdict.yaml).
- [Declaración](declaracion.md), [matriz de aceptación](acceptance-matrix.md).
- [Compliance](compliance-current.json), [evidencias](evidence/).
- [Ficha canónica](../../../Screens/maguey-horneado.md), [página Hub](../../../site/Screens/maguey-horneado.html).

Código cambiado: navegación compartida + helper; adaptador/intención/página/superficie
M/H; store de acceso; pruebas de esos módulos. Documentación: r05, registry,
ficha/sitio Hub, checklist, ESTADO, DECISIONES y FASE-5. Lista exacta en manifest.

Mora M3 completada: ficha draft0.2.1 visible por HTTP con preview del bundle final.
36 archivos protegidos comparados con baseline,0 cambios (Foundations, FilaUso y r04).
Checklist:22/43 ítems evaluados/resueltos,21 abiertos. Entre los22 se cuentan
dictámenes completados cuyo resultado es PARTIAL/no elegible; no son22 gates PASS.
