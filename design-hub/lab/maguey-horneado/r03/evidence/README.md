# Evidencia r03

Primera revisión: `runtime-initial.json` y capturas sin prefijo confirm.
El host multiplicó por dos la solicitud de viewport y limitó el mínimo a
480 CSS px. Las capturas iniciales denominadas 390/320 NO son prueba de esos
viewports; algunas prueban solo el contenedor de 390 dentro de viewport 480.
Se preservan como historial de diagnóstico, no como aceptación.

Confirmación: `runtime-confirmation.json`, `confirm-h-default-{1440,1024,768}.png`
con viewport CSS medido. `qa-compact.html` contiene un iframe con viewport
CSS real 390/320; `confirm-h-default-{390,320}.png`, `confirm-long-320.png` y
`confirm-closing-390.png` corresponden al arnés. No emula un dispositivo físico.
Las capturas incluyen espacio gris del navegador host; no está en el prototipo.

Hallazgo visible: `confirm-long-320.png`, navegación inferior con etiquetas
Fermentación/Destilación demasiado juntas. Sin overflow no equivale a PASS.

Teclado confirmado en JSON: foco inicial kc, reverso a Cancelar, avance a kc,
Escape al disparador, resultado de 4,321 kg. Los tests JSDOM son complementarios,
no sustituyen la prueba de foco del navegador.
