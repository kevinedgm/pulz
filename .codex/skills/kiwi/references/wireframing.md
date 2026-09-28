# Wireframing F1/F2

## Material

- Kit neutral `assets/wireframe-kit.css`: grises, una familia de sistema, radios y espacios fijos.
- Base `assets/wireframe-base.html`: selector de espacio (compact/medium/expanded), panel de estados, notas.
- Nada del design system del proyecto salvo `breakpoints`.

## Jerarquía sin color

Tamaño, peso, espacio, agrupación y posición. El sólido oscuro (`.wf-btn--primary`) se reserva a **una** acción por vista. Estados de madurez o estado de negocio se distinguen por **forma + texto** (relleno, contorno, discontinuo, tachado), nunca por tono.

## Contenido

- Real o realista en cuanto la jerarquía dependa de él: nombres largos, números con formato, listas de 0, 1 y 200.
- Datos de ejemplo rotulados (`.wf-tag` "ejemplo" / "supuesto").

## Navegación

- Desde los destinos: ¿qué visita más, qué es urgente?
- Dónde estoy (título + breadcrumb), qué puedo hacer (acciones en contexto), cómo sigo, cómo regreso.
- **Volver** (historial), **Cancelar** (descarta cambios), **Cerrar** (oculta sin decidir) son tres cosas distintas.

## Por espacio

| Modo | Ancho de referencia | Tendencias |
|---|---|---|
| compact | < 600 | Una columna, acción primaria persistente abajo, filtros a pantalla completa, tablas → bloques |
| medium | 600–1023 | Dos columnas cuando aportan, drawers laterales, navegación compacta |
| expanded | ≥ 1024 | Paneles persistentes, detalle junto a lista, densidad mayor |

Declara qué **conserva**, qué **cambia** y qué **se oculta** cada elemento.

## Anotaciones

`.wf-note` para decisiones, supuestos y referencias a la spec. Nunca uses color para anotar.
