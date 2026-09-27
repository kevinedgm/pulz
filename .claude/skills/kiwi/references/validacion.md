# Matriz de validación

Proporcional a la fidelidad: F0 valida flujo y errores; F1 añade navegación y jerarquía; F2 añade todo lo siguiente.

| Caso | Qué comprobar |
|---|---|
| Datos largos | Nombres/títulos de 2–3× lo normal no rompen la huella |
| Datos faltantes | `null`, 0, sin foto, sin reseñas: no parecen error |
| Vacío inicial | Explica qué falta y ofrece la siguiente acción útil |
| Vacío por filtros | Muestra filtros activos + limpiar en un paso |
| Carga | Skeleton con la misma huella; lo ya visible sigue operativo |
| Error recuperable | Causa + `Reintentar`; no se pierde lo capturado |
| Sin conexión | Distingue contenido guardado de estado actual; qué se encola |
| Objeto ya modificado | Conflicto explicado; conserva selección y ofrece alternativa |
| Abandono de formulario | Aviso solo si hay cambios; borrador si aplica |
| Permisos | Sin permiso: explica, no oculta sin motivo |
| Listas grandes | Paginación/virtualización declarada; búsqueda |
| Acción repetida | Doble envío bloqueado; idempotencia declarada |
| Localización | Textos +30 %, formatos de fecha/moneda, RTL con propiedades lógicas |
| Responsive | compact/medium/expanded; misma tarea completable en cada modo |
| Teclado | Orden lógico, foco visible, Esc cierra overlays, foco vuelve al disparador |

Para cada estado responde: **qué lo dispara, qué pasa si falla, se puede volver.**

## Comprobaciones automáticas mínimas

- `scripts/check_artifact.py` sin errores.
- Navegador: 0 errores JS, 0 desborde horizontal en el cuerpo, targets ≥ 24 px (≥ 44 px en controles principales).
