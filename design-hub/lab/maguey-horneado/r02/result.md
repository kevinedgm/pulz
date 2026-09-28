# Maguey/Horneado r02 · RECHAZADO · 2026-09-28

Kiwi conserva propiedad exclusiva del F2 y geometría. Lima devuelve el control
a Kiwi; **Coco no autorizado, Mora no elegible**. No se construyeron módulos ni
se publicó una pantalla histórica como resultado nuevo.

## Seis dimensiones

| Dimensión | Resultado | Evidencia / límite |
| --- | --- | --- |
| technical | PARTIAL | `check_artifact.py`: 0 errores, 0 warnings; prototipo navegable, sin RPC ni prueba de producción. |
| structural | FAIL | Recepción oculta datos precargados; volver desde revisión pierde cantidades; cierre anterior al inicio. |
| visual | FAIL | Acciones expanded y rail medium rompen palabras/jerarquía; ausencia de overflow no acredita composición. |
| accessibility | FAIL | Capas sin ciclo completo de foco; mensajes/relaciones ARIA no sincronizados con corrección de saldo. |
| design_system | PENDING | F2 neutral; producción debe consumir Foundations actuales. Reparación de assets separada no aprueba este F2 ni su futura F3. |
| documentation | PASS acotado | Brief, decisiones, contrato, hallazgos y evidencia trazables. No es una ficha de implementación. |

## Conservar

Dos destinos Maguey/Horneado; separación de horneadas abiertas y cocido;
saldo restante visible; agotados plegados; continuidad hacia Formulación;
RPC existentes; cantidades de apertura inicialmente vacías; revisión de lote,
horno y cantidades antes del consumo. CTA disponible también en vacíos compact.

## Devolución a Kiwi

- **MH-MINIMAL-02 (P1):** recepción aparenta mínima pero oculta 60 piñas,
  Tobalá, predio y proveedor ya elegidos. Quitar elección silenciosa; botón
  no debe asumir una especie oculta.
- **MH-STATE-02 (P2):** «Volver a cantidades» reconstruye el formulario y
  pierde la selección. Conservar el borrador.
- **MH-DATA-02 (P2):** HOR-003 inicia hoy 09:00, cierre propone hoy 08:00.
  Hacer coherentes fechas y validación.
- **MH-ADAPT-02 (P2):** columna de acciones de 12 rem comprime «Cerrar
  horneada» y parte «Más»; rail de 96 px corta palabras. Kiwi debe resolver
  agrupación, ancho y composición, no solo overflow.
- **MH-ERROR-02 (P2):** corregir 1500 a 1000 habilita acción, pero conserva
  error «Solo 1300»; otros excesos no tienen mensaje y `aria-describedby`
  apunta a un nodo ausente. Unificar error, saldo y descripción.
- **MH-A11Y-02 (P2):** definir foco inicial, contención y devolución de foco.
- **MH-UNIT-02 (P3):** el total reactivo pierde la unidad kg.

## Evidencia y límites

Dos revisores independientes autorizados por el usuario. Primera pasada de
r01: ambos usaron navegador. Segunda pasada de r02: el agente principal
capturó 9 vistas nuevas (1440/1024/768/390 y estados compact); revisor A
contrastó imágenes y revisor B inspeccionó fuente porque sus navegadores no
estaban disponibles. **No equivale a dos verificaciones runtime de r02.**

Capturas y evaluación B: `docs/plan/evidence/maguey-r02-20260928/`.
Se revisaron collision, crowding, hierarchy, grouping, alignment, density,
action dominance, responsive composition y adecuación futura a Foundations.
Persisten problemas de crowding, action dominance y composición adaptativa;
no se certifica WCAG ni calidad visual global.

Se alcanzó el límite de dos pasadas de Impeccable para este ciclo. No se
retoca r02 después de evaluarla. Siguiente trabajo: Kiwi abre r03 con estos
rule_ids y decisiones preservadas; Lima vuelve a evaluar antes de F3.
