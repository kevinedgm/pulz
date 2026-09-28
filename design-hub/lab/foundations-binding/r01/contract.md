# Corrección de entrega de Foundations · r01 · 2026-09-28

## Kiwi · F0 / R0

Propósito: que los componentes existentes usen los assets ya aprobados y no
fall back a tipografías/sprite anteriores. Flujo y anatomía no cambian.
Consumidor → Icono(nombre,size,titulo) → icono Lucide; decorativo oculto,
informativo con nombre. Entradas app/Hub → CSS de fuentes empaquetadas →
Manrope 400/500/600/700 e Instrument Serif 400. Si aún no cargan, fallback
explícito sin bloquear tarea. PWA precache incluye woff2 existente.

No corresponde F2 nuevo: no se decide jerarquía, navegación, densidad o flujo.
Se conservan nombres semánticos y props; cinco usos heredados de 22 px se
enlazan al tamaño canónico 24 px, sin cambiar el target o la navegación. La marca
pulz-mark conserva exactamente sus paths: es un logotipo, no un icono de UI.

## Lima · contrato autorizado

Estado: autorizado para corrección acotada; no estabilización ni promoción.
Bases: .fruti/foundations/approval.yaml y .fruti/tokens.json, sin modificación.
No nueva paleta, token, primitive o API. Icono sigue siendo helper local.
Lucide sustituye únicamente símbolos de interfaz, nunca la marca.
Mapeo semántico: maguey→Sprout, horno→Flame, molienda→Cog, tina→Barrel,
destila→FlaskConical, lote→ClipboardList, home→House, medir→Ruler,
mas→Plus, bell→Bell, clock→Clock, tanque→Cylinder, traza→GitBranch,
ajustes→SlidersHorizontal, menu→Menu. Texto de navegación se conserva.

Alcance Coco: dependencias oficiales fijadas, importaciones explícitas,
Icono.vue sin dependencia de sprite global, eliminar inyección obsoleta del
sprite en app/demo, preservar archivo histórico. Entrega local de fuentes
sin petición a CDN. No modificar FilaUso ni tokens base.

## Gate de verificación

Pruebas de 15 nombres válidos, SVG 24×24 stroke2, decorativo vs informado,
actualización reactiva de nombre, marca intacta; build app y demo con fuentes;
confirmar carga real en navegador. No confundir este gate acotado con auditoría
de todas las pantallas. Mora solo actualiza documentación de entrega verificada.

Decisión autónoma autorizada por CLAUDE.md §4 y solicitud «corrige todo»;
reversión: revertir únicamente archivos listados en el resultado de esta ronda.
