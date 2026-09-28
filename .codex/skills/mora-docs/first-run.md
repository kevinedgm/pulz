# Primer uso — usar mora en un proyecto nuevo

mora es agnóstica del proyecto. En un repo que nunca ha curado no hay perfil activo, así que lo primero — antes de cualquier inventario, reestructura o documentación — es enlazar mora al proyecto. mora comparte su perfil con la skill `lima` y con coco, así que esto es rápido cuando cualquiera de los dos ya está configurado.

## Orden de resolución (compuerta 0)

1. **Busca un perfil existente** en `profiles/<project>.md` de Lima.
   - Si existe y resuelve → **reúsalo**. Luego verifica el bloque `mora:` ([profile-additions.md](profile-additions.md)); si falta, pide solo esas adiciones ([intake.md](intake.md), la parte `mora:`) y añádelas.
2. **Aún no hay perfil y el trabajo es global/persistente** → inspecciona primero las rutas mecánicas; pide solo las decisiones no inferibles y crea el perfil con el intake de Lima + el bloque `mora:`.
3. **No hay perfil, pero el usuario dio un Hub y una corrección acotada** → trabaja en ese alcance, registra los supuestos y no bloquees la tarea con un bootstrap.
4. **Override del usuario** → una instrucción explícita en la conversación gana sobre el perfil; obedécela y anota la desviación en una línea.

Nunca reestructures contra una taxonomía asumida. El inventario debe ser proporcional al alcance: completo para navegación/cobertura global; localizado para una página o defecto concreto.

## Dos formas de enlazar

### A. Guiada (por defecto, con el usuario presente)
Inspecciona primero, completa los campos mecánicos y pregunta solo lo que requiera juicio. Luego escribe/extiende el perfil y confirma los supuestos relevantes.

### B. Reusar el bootstrap compartido (lo más rápido al arrancar desde cero)
Si el proyecto es totalmente nuevo, corre primero el bootstrap de Lima — crea `profiles/<project>.md`, el Hub y el registry:

```bash
# desde la raíz del repo
bash mis-agentes/skills/lima/scripts/init-project.sh \
  --intake my-intake.yaml --qa playwright
```

Luego añade el bloque `mora:` de mora (desde [intake.md](intake.md)) a ese perfil generado. mora lee el mismo archivo.

## Qué necesita mora para estar a plena potencia

Incluso con un perfil, algunas capacidades dependen del tooling del proyecto. mora degrada honestamente — sigue curando, pero etiqueta lo que no pudo correr:

| Capacidad | Necesita | Si falta |
|---|---|---|
| Inventariar registry + páginas | `registry_path`, `hub_root` en el perfil | no puede arrancar — pide el perfil |
| Contrastar páginas vs código real | `production.component_layout` | anota que no puede confirmar deriva del código |
| Censo de cobertura | `mora.coverage_script` | reporta cobertura como `manual` |
| Servir + validar páginas | `mora.serve_command` (o python3) | reporta el check de HTTP/shell como no ejecutado |
| Reusar el shell de doc real | `mora.doc_shell` | señala que las páginas no tienen shell que reutilizar (riesgo de páginas sin estilo) |
| Preview viva del componente | `mora.hub_preview` / un harness corriendo | marca la preview no disponible/no verificada; no duplica CSS |
| Orden de secciones + spec de honestidad | `mora.doc_standard` | usa el orden canónico interno de mora, declarado |

Ninguna de estas impide que mora *cure*; solo cambian qué checks son verificables vs manuales. La entrega (AGENT.md §8) siempre dice la verdad sobre cuáles corrieron.

## Resultado

- mora queda enlazada a `profiles/<project>.md` (compartido con Lima y Coco), incluyendo un bloque `mora:`.
- Desde aquí aplica AGENT.md: contexto (§1) → inventario proporcional (§2) → modo M0–M3 (§3) → propiedad de la verdad (§4) → reparación (§5) → contrato de página (§6) → verificación (§7) → entrega (§8).
