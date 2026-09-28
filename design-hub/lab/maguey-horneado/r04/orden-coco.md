# Orden de construcción · r04

Construir Maguey/Horneado dentro del shell real PULZ, como product-application.
Entrada: brief, decisiones y lima-contract de esta ronda, no aprobaciones viejas.
Sin rediseñar F2 ni cambiar Foundations, FilaUso o servidor.

Mapa: adaptador API (lecturas aisladas y cuatro RPC existentes), composable
de carga/envío/errores, lista de lotes y horneadas, formularios de recepción,
apertura con revisión y cierre/entrada directa; páginas de composición delgadas.
Reutilizar CampoNumero, CampoTexto, CampoCuando, Selector, AsignacionOrigenes,
Boton, ChipEstado y CapaTarea. Demo Hub usa los mismos componentes con datos
de ejemplo rotulados y acciones simuladas, nunca RPC remotas.

Validación: pruebas de interacciones, permisos, errores, idempotencia y build;
revisión F3 en navegador con tokens/fuentes reales. Seis dimensiones separadas.
Lima decide elegibilidad Mora después del informe; no publicar como stable si
quedan verificaciones pendientes. Datos remotos intactos.
