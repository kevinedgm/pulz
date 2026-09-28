# Maguey/Horneado r05 · cierre de aceptación

Fecha: 2026-09-28. Modo Operate. Frente único: checklist 14–17.
Autoridad: petición vigente «ejecuta todo decide … kiwi, lima y coco».
R04 es antecedente rechazado/parcial, nunca aprobación de esta ronda.

## Brief acotado de Kiwi

Productores y administradores necesitan reconocer cada destino del proceso.
Pregunta: ¿Fermentación se lee sin una letra huérfana en el rail de 160 px?
Resultado: nombre completo, corte silábico controlado, ruta y nombre accesible intactos.
No se cambian formularios, permisos, API, datos ni geometría de Maguey/Horneado.

Hechos: NavLateral es el componente compartido de app y demo; medium usa160px
en M/H, expanded240px. NavInferior ya utiliza guiones discrecionales.
Supuesto de diseño: un corte Fermenta-ción conserva comprensión mejor que
Fermentació/n; inferencia de Kiwi, no regla atribuida a WCAG.
Incógnitas externas: conectividad alojada, fixtures autorizados, hardware y
tecnologías de asistencia. Ninguna se convierte en PASS por esta aprobación.

## Geometría y adaptación congeladas

| Región | Compact <600 | Medium 600–1023 | Expanded ≥1024 |
|---|---|---|---|
| Navegación | 4 destinos + Más, cinco tracks | Rail160px | Sidebar240px |
| Insets contenido | 16px | 24px | 24px |
| Target principal | 48px alto, ≥44px mínimo | Igual | Igual |
| Texto navegación | Completo, corte discrecional | Completo, corte discrecional | Completo, sin corte si cabe |
| Contenido | Jerarquía vertical | Lista + acciones adaptadas al contenedor | Lista contenida, acciones a la derecha |

Se conservan contenido máximo960px, formulario720px, revisión640px, capa440px;
campos en dos columnas desde contenedor500px y fila expandida desde900px.
No se ocultan datos ni se duplican instancias de negocio al cambiar tamaño.
El flujo es el existente: navegar es reversible; capturas exigen validación,
apertura exige revisión; sin señal no se escribe, resultado incierto no reenvía solo.

## Brief visual de Coco

N1 tarea/saldo; N2 identificación y estado; N3 fecha/autor; opcionales bajo demanda.
Una primaria por vista. Reutilizar NavLateral/NavInferior y componentes actuales.
Sin nuevos tokens. Foundations PULZ actuales, no identidad histórica del maestro.
Alcance de F2: navegación aislada; no certifica nuevamente todo el flujo histórico.

## Verificación

320/390/600/768/1023/1024/1440, texto normal/largo; seis dimensiones separadas.
Una revisión visual por lote, un lote de corrección y una confirmación como máximo.
Pruebas remotas mutantes condicionadas a entorno y fixtures identificados.
Sin Docker, reset, deploy, modificación de FilaUso ni sobrescritura r01–r04.
