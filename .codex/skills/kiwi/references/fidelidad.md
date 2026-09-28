# Elección de fidelidad

**La fidelidad responde a la incertidumbre.** Se elige la menor que responda la pregunta de diseño.

| Si la pregunta es… | Nivel | Quién |
|---|---|---|
| ¿En qué orden pasan las cosas? ¿Qué pasa si falla? | F0 flujo | kiwi |
| ¿Qué va primero? ¿Dónde vive cada cosa? ¿Cómo navego? | F1 lo-fi | kiwi |
| ¿Cabe el contenido real? ¿Qué pasa en vacío/error? ¿Cómo cambia por espacio? | F2 mid-fi | kiwi |
| ¿Cómo se percibe? ¿Qué microinteracción? ¿Listo para handoff visual? | F3 hi-fi | coco |
| Construirlo en producción | R3 | coco |

## Reglas

- No es una escalera: se puede ir de F0 a F3 si el sistema es maduro y el patrón conocido (en ese caso, kiwi entrega F0 y traspasa a coco).
- Se puede terminar en F2 si la pregunta era estructural.
- R2 exige diferencias de estructura, jerarquía, densidad o interacción. Cambiar colores no es una alternativa.
- Sin design system real no existe F3: se detiene en F2 y se dice.
- Si la petición es ambigua entre F2 y F3, preguntar qué se decidirá con el artefacto.

## Señales de fidelidad equivocada

- Discusión sobre colores cuando la estructura no está aprobada → bajar a F1.
- Wireframe con lorem ipsum donde el contenido decide la jerarquía → subir a F2.
- Hi-fi que "se ve bien" pero nadie sabe qué pasa en error → volver a F2 para estados.
