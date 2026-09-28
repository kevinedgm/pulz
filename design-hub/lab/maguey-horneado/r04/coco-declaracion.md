# Coco · implementación r04

2026-09-28 · F3 local · product-application · **draft, no release**.
Construcción autorizada por `lima-contract.yaml`; geometría de Kiwi sin rediseño.

## Implementado

Dos destinos: Maguey y Horneado; recepción mínima, revisión de consumo antes
de abrir, cierre y entrada de cocido sin historia. Admin/productor escriben
con señal y suscripción; operador consulta. Cuatro RPC existentes, sin nuevas
migraciones ni escrituras remotas durante esta ronda.

Arquitectura: `modelo.ts` valida/formatea; `api.ts` pagina lecturas y adapta RPC;
`intencion.ts` conserva envíos inciertos; `ProcesoSolidoPage` integra acceso,
conexión e instantáneas; `SuperficieMH` coordina listas y formularios locales.
`RecepcionForm`, `AperturaForm`, `CocidoForm` y `ListasMH` reutilizan controles
del sistema. No se promovieron estos componentes locales como nuevas primitivas.

Fuente visual: `.fruti/tokens.json` → `shared/ui/tokens.css`; Manrope local,
Lucide, color primary aprobado y roles semánticos; sin cambios a valores base.

## Corrección y verificación

- Revisión independiente A: idempotencia, persistencia, conexión y hora.
- Revisión independiente B: paridad de insets/rail, contraste y foco.
- Lote de corrección: intención persistida antes de RPC, errores tipados,
  reintento original sin editar cantidad/fecha, reconexión, insets16/24,
  rail160/240, encabezado único, foco de ida/vuelta/resultado y danger-text.
- 28 pruebas del módulo; 168 pruebas locales de app PASS. Los cinco tests
  alojados se ejecutaron antes y fallaron por RED; no se convierten en PASS
  al excluirlos de la batería local.
- Build app/types/PWA y build demo PASS. ESLint del alcance PASS.
- Browser real: cierre simulado4321kg, apertura120.5kg, borradores,
  error de saldo corregible, foco inicial/Tab/Escape/devolución, estados y
  medidas320/390/768/1024/1440. Evidencia en `evidence/`.

## Límites

No sesión/RPC end-to-end real, lector de pantalla, touch físico, forced-colors
ni zoom nativo200%. No se escribió Supabase ni se editó FilaUso. Registros
simulados son explícitos. No hubo despliegue ni certificación global.
La partición local de intención no es cola offline ni se envía sola: necesita
reintento manual. Borrar los datos del navegador elimina esta protección local.
El rail a768 conserva el texto pero su corte de palabra necesita otra ronda
de pulido. Dictamen: `lima-f3-verdict.yaml`, no Candidate/Stable.
