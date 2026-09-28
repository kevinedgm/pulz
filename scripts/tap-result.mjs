// Management API returns success when SQL executed, even if pgTAP failed.
// Treat TAP as the verdict, not the exit status of `supabase db query`.
export function evaluarTap(salida) {
  const inicio = salida.indexOf("{")
  if (inicio < 0) throw new Error("No se recibió la respuesta JSON del CLI")
  const respuesta = JSON.parse(salida.slice(inicio))
  if (!Array.isArray(respuesta.rows)) throw new Error("La respuesta no contiene rows")
  const lineas = respuesta.rows.flatMap((fila) => {
    if (typeof fila.runtests !== "string") throw new Error("Fila sin resultado runtests")
    return fila.runtests.split("\n")
  })
  const aserciones = lineas.filter((l) => /^\s*(?:not )?ok\s+\d+\b/.test(l))
  const planes = lineas.filter((l) => /^\s*1\.\.\d+\b/.test(l))
  const fallos = lineas.filter((l) => /^\s*not ok\b|Test died:|^\s*Bail out!/i.test(l))
  const omitidas = [...aserciones, ...planes].filter((l) => /#\s*(?:SKIP|TODO)\b/i.test(l))
  if (!aserciones.length || !planes.length)
    throw new Error("TAP incompleto: faltan aserciones o plan")
  // Cada subtest tiene su propio plan; un resumen raíz verde no compensa
  // líneas perdidas dentro de él. Valida también numeración y planes dobles.
  const niveles = new Map()
  const cerrar = (nivel) => {
    const grupo = niveles.get(nivel)
    if (grupo.plan === null || grupo.plan !== grupo.cantidad)
      throw new Error("TAP incompleto: un plan no coincide con sus resultados")
    niveles.delete(nivel)
  }
  for (const linea of lineas) {
    const asercion = /^(\s*)(?:not )?ok\s+(\d+)\b/.exec(linea)
    const plan = /^(\s*)1\.\.(\d+)\b/.exec(linea)
    const match = asercion ?? plan
    if (!match) continue
    const nivel = match[1].length
    for (const anterior of [...niveles.keys()].sort((a, b) => b - a))
      if (anterior > nivel) cerrar(anterior)
    const grupo = niveles.get(nivel) ?? { cantidad: 0, plan: null }
    if (asercion) {
      grupo.cantidad += 1
      if (Number(asercion[2]) !== grupo.cantidad)
        throw new Error("TAP inválido: numeración discontinua o duplicada")
    } else {
      if (grupo.plan !== null) throw new Error("TAP inválido: plan duplicado")
      grupo.plan = Number(plan[2])
    }
    niveles.set(nivel, grupo)
  }
  if (!niveles.has(0)) throw new Error("TAP incompleto: falta el plan raíz")
  for (const nivel of [...niveles.keys()]) cerrar(nivel)
  return {
    estado: fallos.length ? "FAIL" : omitidas.length ? "PARTIAL" : "PASS",
    aserciones: aserciones.length,
    fallos,
    omitidas,
    tap: lineas,
  }
}
