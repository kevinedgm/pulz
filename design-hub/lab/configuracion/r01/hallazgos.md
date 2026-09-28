# Hallazgos · CONFIGURACIÓN · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | Desactivar un recurso con saldo (tanque) o ciclo abierto (tina) debería avisarlo; no hay vista/RPC que lo diga al admin | Confirmación genérica corta en esta ronda; se propone `recurso_en_uso(p_org)` (función solo-lectura como `equipo_miembros`) para r02 | lima → coco (base) | decidir si entra en esta fase (Claude: **sí, entra como función mínima** — es barato y evita apagar una tina con fermentado dentro) |
| Alta | 14 catálogos con un solo patrón (select + lista + capa con campos por catálogo): riesgo de que la capa sea genérica y acoplada | La capa es UNA por tabla real (`tipo_*` comparten campos; conceptos, especies, predios, proveedores, insumos tienen la suya) — no un formulario dinámico por JSON | lima | fijar en el contrato: `catalog-form` local por tabla, no pieza del sistema |
| Media | El productor puede editar predios/proveedores/insumos (RLS), pero Configuración es solo admin (shell/r01) | Supuesto 1 del brief: siguen en Configuración (admin); el productor los captura desde Maguey en Fase 5 | kiwi (declarado) | revisar en la ronda de Maguey |
| Media | Piezas nuevas para el sistema: `select` (nativo, estilizado con tokens, ≥44px), `number-field` (inputmode decimal/numeric + unidad), `switch` (role=switch, texto + forma), `color-field` (input type=color + hex visible), `file-picker` (subir + recorte) | Candidatas al sistema; lima decide sistema vs local | lima | registrar como draft con contrato |
| Media | El recorte del logo en el navegador (canvas) es lógica nueva sin librería; hay que probarlo con PNG con transparencia y JPG grandes de cámara (EXIF de orientación) | Should; si la orientación EXIF da problemas, se sube sin recortar (el bucket acepta hasta 2 MB) y se declara | coco | probar con fotos reales de teléfono |
| Baja | La vista previa del portal debe ser el mismo `MarcaPortal` de acceso/r01, no una copia | Reutilizar el componente | coco | — |
| Baja | Ajustes: "hora del recordatorio" no tiene consumidor hasta Fase 5 | Se guarda igual (campo real); se rotula "Fase 5" en la ayuda | coco | — |
| Info | Reordenar catálogos (`sort_order`) no entra | Could; no bloquea | — | r02 si el dueño lo pide |
