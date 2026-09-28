# Maguey/Horneado r04 · resultado

2026-09-28 · **IMPLEMENTADO LOCALMENTE; ACEPTACIÓN PARCIAL.**
Kiwi F2 aprobada sólo en estructura → Coco F3 construida → Lima evaluada →
Mora autorizada únicamente a documentar el draft. **No overall PASS, Candidate,
Stable ni despliegue.** No se modificó FilaUso ni se escribió en Supabase.

## Entregables

- [F2 Kiwi](index.html) · [decisiones](kiwi-decisions.yaml) · [contrato F2](lima-contract.yaml).
- Implementación: `apps/web/src/modules/maguey-horneado/` y rutas locales.
- [Declaración Coco](coco-declaracion.md) · [dictamen F3 Lima](lima-f3-verdict.yaml).
- [Compliance](compliance-current.json) · [confirmación navegador](evidence/f3-confirmation.json).
- [Ficha draft nueva del Hub](../../../Screens/maguey-horneado.md).
- [Demo Vue real con datos simulados](../../../Components/demo/index.html?pieza=maguey-horneado&solo=1).

## Resuelto en esta continuación

Navegación compacta y nota FAB de r03; recepción sin supuestos; revisión antes
de consumir; cantidades y fecha conservadas; cierre/entrada de cocido; permisos,
lectura y reconexión; cuatro contratos RPC reales y lecturas paginadas.

Dos revisores independientes detectaron idempotencia ante HTTP ambiguo,
pérdida de intención al navegar, fecha variable al reintentar, bloqueo tras
reconectar, diferencia demo/app, errores de bajo contraste y pérdida de foco.
Se corrigieron en un lote: persistencia particionada antes del envío, rechazo
tipado, hora fijada, actualización de instantánea, insets y rail compartidos,
un h1, danger-text y foco de ida/vuelta/resultado. Pruebas nuevas verifican
reintento tras remontaje, datos inmutables, aislamiento local y almacenamiento
no disponible. No se reutilizaron aprobaciones históricas.

## Seis dimensiones

| Dimensión | Resultado | Evidencia / límite |
|---|---|---|
| Technical | PARTIAL | Build/types/demo/lint y168/168 locales PASS; pruebas alojadas y RPC E2E no aprobadas |
| Structural | PASS local | Geometría Kiwi; dos destinos, grupos, acciones y transformación por espacio; shell real inspeccionado en código |
| Visual | PARTIAL | Composición revisada en cinco anchos; corte poco natural de Fermentación en medium pendiente |
| Accessibility | PARTIAL | Teclado/foco/error asociados verificados; touch, AT, forced-colors y zoom nativo pendientes |
| Design system | PASS local | Tokens/fuentes/iconos canónicos, sin modificar valores base |
| Documentation | PASS sólo draft | Hub compila; ficha nueva, preview Vue,120 enlaces/recursos sin rotos ni IDs duplicados; no promoción |

## Verificaciones ejecutadas

- Kiwi:12/12 pruebas, checker0errores/0avisos, evidencia nueva r04.
- Módulo Vue:28/28. Aplicación local:168/168,21archivos.
- La primera batería completa dio163PASS/5FAIL por `ErrorAcceso: RED` en
  acceso alojado. Luego se añadieron cinco regresiones; batería local excluye
  explícitamente `**/*.integracion.test.ts`. No se oculta ni aprueba ese fallo.
- `pnpm --filter @pulz/web build`, `build:hub`, ESLint acotado:PASS.
- Browser:320/390CSSiframe y768/1024/1440viewport; no desborde. Cierre4321kg,
  apertura120.5kg, error2001kg sobre saldo2000, corrección, foco y borradores.
- La demo no usa la base remota. Screenshots propios en `evidence/f3-*-light.png`.
- Hub:48 fichas compiladas; página abierta por HTTP y preview cargada.
 120 enlaces/recursos locales verificados,0rotos,0IDs duplicados y una sola
 preview. Truth sources existentes y JSON parseable. Los diez artefactos
 hasheados de r03 permanecen idénticos.

## Archivos del alcance

Nuevo módulo: modelo/api/intencion/routes/ejemplo; página de proceso; cuatro
formularios/listas/coordinación y CSS; tres suites. Nuevo arnés demo y QA F3;
nuevos documentos/evidencia r04 y ficha Screens. Cambios acotados en router,
destinos, AppShell, CabeceraPagina, CapaTarea, NavInferior, CampoNumero,
CampoCuando, DemoHub, perfil de datos, registry, checklist y estado/decisiones.
Assets demo/site son generados. El árbol tenía cambios previos ajenos: no se
revocaron ni se atribuyen a esta ronda. No commit ni despliegue.

## Pendientes reales

1. Pulido de la etiqueta medium: se ve completa pero parte antes de la n final.
2. E2E autenticado de recepción→horneado→formulación con RPC reales en alcance
   de prueba autorizado; en esta ronda no se hicieron escrituras remotas.
3. Touch físico, lector de pantalla, forced-colors y zoom nativo200%.
4. Repetir acceso alojado cuando el entorno tenga conectividad habilitada.

Inicio/hoy, concurrencia y otros frentes siguen fuera de esta continuación.
El checklist no declara terminado todo el proyecto ni cierra Fase5.
