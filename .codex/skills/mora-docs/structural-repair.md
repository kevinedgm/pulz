# Política de reparación estructural

Usa esta matriz después del inventario. “Estructural” describe el documento o el Hub; no autoriza a cambiar el producto que la documentación representa.

## AUTO-CORREGIR

Se requieren las cuatro condiciones: resultado inequívoco, fuente propietaria disponible, cambio reversible y ausencia de impacto en contrato de producto.

Casos habituales:

- enlace, anchor o ruta relativa rota con destino único comprobable;
- IDs duplicados, `aria-controls` huérfano o estado activo que no coincide con el ID de página;
- sección existente fuera del orden relativo del estándar;
- entrada de índice que no corresponde a una sección real;
- import duplicado o referencia a un shell declarado como deprecado cuando el perfil identifica el shell activo;
- metadata repetida que contradice el registry;
- API documental que contradice tipos/código público real: retirar la afirmación falsa o marcarla no disponible;
- HTML mal anidado o atributo inválido cuya intención sea inequívoca;
- elemento deprecated presentado como vigente: retirar indicadores de vigencia y enlazar migración existente;
- archivo de navegación generado que diverge de su manifiesto canónico: regenerar desde el manifiesto;
- página publicada que contradice la ronda aprobada en nombres o metadata, cuando la fuente propietaria es inequívoca.

Una discrepancia **dentro de una ronda de kiwi** (brief, prototipo y declaración que no cuentan la misma historia) no se autocorrige: se reporta a kiwi, que abre la siguiente ronda.

Registra qué regla disparó el cambio y vuelve a ejecutar la detección.

## REVISAR ANTES DE CORREGIR

- crear, fusionar o renombrar categorías;
- mover páginas o cambiar URLs públicas;
- sustituir el shell activo o alterar sus breakpoints;
- eliminar páginas o contenido histórico;
- cambiar qué artefactos son públicos/documentables;
- modificar status, versión, owner o `replacedBy` sin una decisión de gobernanza;
- resolver dos destinos igualmente plausibles.

Puedes preparar el parche o plan, pero no presentar la decisión como mecánica.

## REPORTAR O DERIVAR

- nueva variante, estado, prop, evento, slot o comportamiento;
- cambio de CSS, tokens, layout o interacción del componente de producto;
- nueva evidencia de accesibilidad o QA no ejecutada;
- preview que requiere implementar un harness inexistente;
- conflicto donde ninguna fuente posee el dato.

Deriva estructura o flujo a **kiwi**, gobernanza/lifecycle a **lima** y diseño/implementación/QA a **coco**.

## Invariantes después de una reparación

- una sola fuente para navegación y una sola instancia de navegación global;
- un solo shell activo por Hub; los shells deprecados no se importan;
- contenido contextual (“En esta página”) deriva de secciones reales y no abre otro drawer global;
- IDs únicos y enlaces resolubles;
- secciones aplicables, sin stubs vacíos;
- metadata y API trazables a su fuente propietaria;
- ningún fallback crea una segunda implementación visual del componente.
- las páginas publicadas mantienen el alcance, la nomenclatura y los estados de la ronda aprobada, y no declaran más evidencia de la que existe.
