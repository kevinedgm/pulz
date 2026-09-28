# coco · Declaración de cumplimiento — ronda fermentacion/r01 (R3 + F3)

```text
Ruta: R3 (5 piezas nuevas del sistema + 3 extensiones + product-application fermentacion) — orden de lima
Brief funcional: el de kiwi, vigente. data_contract registrado en el perfil: UsoTina, Medicion, NuevaMedicion, Formulacion, TinaFermentaba, Ajustes, ElementoCola
Reglas aplicadas:
  · toda medición entra por la cola (encolarMedicion → shared/offline/cola) con idempotency_key y occurred_at; con señal se envía enseguida y la pantalla dice «enviada»; sin señal «pendiente de enviar»; la lista y la medición se abren desde la instantánea (cargarUsos/cargarMediciones con conInstantanea)
  · día del ciclo y «toca medir hoy» calculados en el navegador (api.ts, funciones puras con 12 pruebas); el día se puede corregir en la cabecera
  · un concepto por paso (FlujoPasos): mínimo Temperatura → Brix → Actividad → Revisar (4); completo T. superficie (3) → T. fondo (3) → Brix superficie (3) → Brix fondo (3) → Actividad · Dulzor · Acidez → Revisar (6); promedio en vivo, nunca guardado (lecturas como filas: arreglos paralelos)
  · aviso de Brix conocido ANTES de enviar con los rangos de organization_settings (AvisoNota); la primaria espera la nota; si el servidor aun así pide nota, la fila queda en fallo con «Corregir» que reabre Revisar con la misma clave
  · una primaria por vista: Medir (FAB del shell en compact vía app/fab.ts; botón en la cabecera en ≥600; el FAB abre la primera «toca medir hoy» y la cabecera permite «otra tina»); en el detalle «Medir hoy» page-primary
  · operador: mide y ve; no ve declarar lista, cerrar, formular ni «tina que ya fermentaba» (rpc_guard 0017/0016/0015); por URL, state-block sin permiso en Formular
  · cerrar ciclo: diálogo destructivo (danger) con Cancelar como primaria; anular medición pide motivo; declarar lista inline con nota opcional; todo con «¿Cuándo pasó?» (CampoCuando)
  · escala 1–6 con etiqueta viva (EscalaOpciones, radiogroup, botones 52 px); número grande 2.75 rem con teclado decimal (CampoGrande); chips pending/failed y banner de cola por texto + forma
  · foto opcional en Revisar: reducida a 1600 px en el navegador y encolada; sube a evidencias/<org>/<operación>/ con fila en attachments (tipo «Foto» del catálogo)
Excepciones: ninguna respecto a la ronda. Formulación no se pudo ejecutar en Cuatro Vientos (sin agave cocido con saldo): se verifica su estado vacío real y el formulario por tipos y pruebas; la RPC ya está probada por pgTAP (Fase 2)
Comprobado:
  · vue-tsc ✔ · eslint 0/0 ✔ · prettier ✔ · Vitest 90/90 ✔ (12 nuevas de api puras + 9 de piezas nuevas/extendidas + 8 de cola)
  · pnpm --filter @pulz/web build:hub ✔ (5 secciones nuevas en la demo)
  · Playwright qa/evidencia-fermentacion.mjs 8/8 ✔ (61 capturas, 1440/1024/768/390 × claro/oscuro) con Aurelia en Cuatro Vientos, escrituras REALES: medición de Tina 2 con Brix 19 → aviso conocido antes de enviar → nota → registrar_medicion por la cola → «Guardada · enviada» → Tina 2 pasa a «Ya medidas hoy» con «hoy hh:mm · 27.5 °C · 19 Brix · actividad 6» → detalle → anular con motivo (fila tachada con el motivo) → diálogo de cerrar ciclo (cancelado); FAB solo en compact; formulación (estado vacío real); capa «tina que ya fermentaba» (sin tinas libres, lo dice)
  · Playwright qa/e2e-offline.mjs ✔ (§16 Fase 5, mediciones): 390 px, context.setOffline → 3 mediciones (Tina 2, Tina 3, Tina 2 día corregido) «pendiente de enviar» ×3, banner «Sin conexión. 3 capturas pendientes…», chips en la lista → vuelve la señal → llegan las 3 (operations 13 → 16), claves únicas, recorded_at en el mismo orden que occurred_at (en_orden = true), recargar no duplica (16 → 16). Las 3 quedan anuladas por SQL con motivo (declarado) para no alterar otras evidencias
  · capturas revisadas a ojo: lista 1440/390, medir 390, revisar con aviso 1440, detalle 768 oscuro, escala 390 oscuro
Auditoría arquitectónica (manual):
  · api.ts: lecturas con instantánea encapsuladas en conInstantanea (un solo lugar decide red vs. copia local); funciones puras sin Vue; ErrorFermentacion lleva el ErrorRpc (código y requiereNota). Health: sano.
  · MedirPage: estado de los 15 números en refs planas; pasos como lista por modo; lecturas() arma los arreglos; corrigiendo reutiliza la misma pantalla. 400 líneas: aceptable para «un concepto por paso»; si crece (fotos por paso), se parte en componentes por paso. Health: sano con vigilancia.
  · FlujoPasos/CampoGrande/EscalaOpciones/CampoCuando/AvisoNota: primitivas sin dominio; AvisoNota conoce AVISOS (texto de negocio) por diseño (patrón). Health: sano.
  · useCola: estado por app; refresca también sin señal (defecto encontrado por el e2e: el banner no contaba lo recién encolado). Health: sano.
  · Findings:
    - MEDIUM · AUTO_FIX (hecho) — Boton es un fragmento: un class scoped en él no aplica (el botón «Medir» de la cabecera se veía también en compact junto al FAB); envuelto en un div. Regla: no poner clases scoped de página en Boton.
    - LOW · NO_ACTION — en dev server (Vite) los módulos se piden bajo demanda: sin señal no se puede abrir una ruta no visitada; en producción el SW precachea. El e2e visita Medir antes del modo avión y lo declara.
    - LOW · NO_ACTION — la lista muestra la verdad del servidor (instantánea) + chip «pendiente»; una tina con captura pendiente sigue en «toca medir hoy» hasta que llega (decisión: no fingir que el servidor la tiene).
    - INFO — quedan en Cuatro Vientos mediciones anuladas de las corridas de evidencia hasta el db reset.
    - INFO — una limpieza a mano tras una corrida abortada del e2e (SQL por recorded_at::date = hoy) anuló también las mediciones de la SEMILLA (todas «recorded» el día del reset): por eso las capturas de la lista dicen «nunca medida» en Tina 1 y Tina 2. Estado real, no inventado; `db reset --linked` ejecutado después para devolver la semilla. Lección: limpiar por idempotency_key/operación, nunca por fecha.
No pudo comprobarse: modo completo con la RPC real desde la pantalla (Cuatro Vientos y Prueba B están en modo mínimo; se comprobó por tipos y por lecturasParaRpc); subida real de una foto por la cola (no hay cámara en Playwright; la ruta está cubierta por la prueba unitaria de la cola con blob); formulación real; lector de pantalla; zoom nativo.
Siguiente paso: lima → mora → ronda destilacion/r01.
```
