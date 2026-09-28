# Selector de archivo · `file-picker`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/configuracion/r01` |
| Código | `apps/web/src/shared/ui/SelectorArchivo.vue` |
| Demo real | `Components/demo/index.html#file-picker` |
| Pruebas | `configuracion.test.ts` (acepta/rechaza por tipo y tamaño; Quitar) |
| Evidencia | `qa/evidence/configuracion-r01/portal-logo-*`, `portal-con-logo-*` |

## Para qué
Elegir un archivo (hoy: el logo). Vista previa 96 px, «Subir…» (input file oculto) y «Quitar». Valida tipo y tamaño **en el navegador con los mismos límites del bucket** (2 MB; png/jpeg/webp) y emite `rechazar` con el motivo. El recorte es del consumidor (capa local de Portal y marca).

## API real
```ts
props: { etiqueta: string; previewUrl?: string | null; accept?: string[]; maxBytes?: number; ayuda?; error?; ocupado?; disabled?; textoSubir?: string }
emits: { elegir: [File]; quitar: []; rechazar: [motivo: string] }
```
Dependencias: `button`. **Pendiente para Stable:** cámara del teléfono (`capture`), fotos con EXIF.
