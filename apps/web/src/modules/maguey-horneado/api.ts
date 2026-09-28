// Contratos existentes: migraciones 0008/0009/0011/0015/0016. Sin nuevos RPC.
import { supabase } from "../../shared/supabase/client"
import { conInstantanea } from "../../shared/offline/instantanea"
import {
  ErrorAcceso,
  esErrorDeRed,
  traducirErrorRpc,
  MENSAJE_RED,
} from "../../shared/supabase/errores"
import { errorCaptura, type CapturaMH, type DatosMH, type LoteSolido, type Opcion } from "./modelo"
import { RechazoCapturaMH } from "./intencion"
type Fila = Record<string, unknown>
const texto = (r: Fila | undefined, k: string) => String(r?.[k] ?? "")
const numero = (r: Fila | undefined, k: string) => Number(r?.[k] ?? 0)
// Paginación de transporte: no truncar saldos silenciosamente al límite de PostgREST.
async function filas(org: string, tabla: string, campos: string, orden: string) {
  const result: Fila[] = []
  for (let inicio = 0; ; inicio += 500) {
    let consulta = supabase.from(tabla).select(campos).eq("organization_id", org).order(orden)
    if (tabla === "roasting_run_inputs") consulta = consulta.order("lot_id")
    const { data, error } = await consulta.range(inicio, inicio + 499)
    if (error) {
      if (esErrorDeRed(error)) throw new ErrorAcceso("RED", MENSAJE_RED)
      throw new Error(traducirErrorRpc(error).mensaje)
    }
    const pagina = (data ?? []) as unknown as Fila[]
    result.push(...pagina)
    if (pagina.length < 500) return result
  }
}
export function cargarMH(org: string) {
  return conInstantanea<DatosMH>(org, "maguey-horneado", async () => {
    const [
      lotes,
      saldos,
      recepciones,
      runs,
      entradas,
      recursos,
      especies,
      predios,
      proveedores,
      operaciones,
    ] = await Promise.all([
      filas(org, "lots", "id,folio,material,origin,initial_quantity,notes,operation_id", "id"),
      filas(org, "solid_lot_balances", "lot_id,remaining_kg", "lot_id"),
      filas(
        org,
        "maguey_receptions",
        "lot_id,species_id,predio_id,supplier_id,pina_count,quality_note",
        "lot_id",
      ),
      filas(
        org,
        "roasting_runs",
        "id,folio,oven_id,status,started_at,ended_at,cooked_kg,fuel_note,operation_id,output_lot_id",
        "id",
      ),
      filas(org, "roasting_run_inputs", "run_id,lot_id,quantity_kg", "run_id"),
      filas(org, "resources", "id,code,kind,capacity,active", "id"),
      filas(org, "species", "id,common_name,active", "id"),
      filas(org, "predios", "id,name,active", "id"),
      filas(org, "suppliers", "id,name,active", "id"),
      filas(org, "operations", "id,occurred_at,recorded_by", "id"),
    ])
    const mapa = (rows: Fila[], key = "id") => new Map(rows.map((r) => [texto(r, key), r]))
    const ls = mapa(lotes),
      ss = mapa(saldos, "lot_id"),
      rr = mapa(recepciones, "lot_id"),
      cocidos = mapa(
        runs.filter((r) => r.output_lot_id),
        "output_lot_id",
      ),
      es = mapa(especies),
      ps = mapa(predios),
      pr = mapa(proveedores),
      rs = mapa(recursos),
      os = mapa(operaciones)
    const opcion = (rows: Fila[], nombre = "name"): Opcion[] =>
      rows
        .filter((r) => r.active === true)
        .map((r) => ({ id: texto(r, "id"), nombre: texto(r, nombre) }))
    const personas = new Map<string, string>()
    const autores = [...new Set(operaciones.map((o) => texto(o, "recorded_by")).filter(Boolean))]
    for (let i = 0; i < autores.length; i += 200) {
      // RLS limita perfiles visibles; pedir sólo autores de operaciones de esta empresa.
      const { data, error } = await supabase
        .from("profiles")
        .select("id,full_name")
        .in("id", autores.slice(i, i + 200))
      if (error) {
        if (esErrorDeRed(error)) throw new ErrorAcceso("RED", MENSAJE_RED)
        throw new Error(traducirErrorRpc(error).mensaje)
      }
      for (const p of data ?? []) personas.set(p.id, p.full_name)
    }
    const quien = (o: Fila | undefined) => personas.get(texto(o, "recorded_by")) ?? ""
    return {
      lotes: lotes
        .filter((l) => ["maguey", "agave_cocido"].includes(texto(l, "material")))
        .map((l) => {
          const id = texto(l, "id"),
            r = rr.get(id),
            o = os.get(texto(l, "operation_id"))
          return {
            id,
            folio: texto(l, "folio"),
            material: texto(l, "material") as LoteSolido["material"],
            inicial: numero(l, "initial_quantity"),
            saldo: numero(ss.get(id), "remaining_kg"),
            contexto:
              l.material === "agave_cocido"
                ? cocidos.has(id)
                  ? `De horneada ${texto(cocidos.get(id), "folio")}`
                  : l.origin === "carga_inicial"
                    ? "Carga inicial sin historia de horneado"
                    : l.origin === "compra"
                      ? "Compra de agave cocido"
                      : "Agave cocido · origen de horneado no disponible"
                : [
                    texto(es.get(texto(r, "species_id")), "common_name") ||
                      "Especie sin especificar",
                    texto(ps.get(texto(r, "predio_id")), "name"),
                    texto(pr.get(texto(r, "supplier_id")), "name"),
                    r?.pina_count != null ? `${numero(r, "pina_count")} piñas` : "",
                  ]
                    .filter(Boolean)
                    .join(" · "),
            nota: texto(l, "notes") || texto(r, "quality_note"),
            cuando: texto(o, "occurred_at"),
            quien: quien(o),
          }
        })
        .sort((a, b) => b.cuando.localeCompare(a.cuando)),
      horneadas: runs
        .map((r) => {
          const input = entradas.filter((i) => i.run_id === r.id)
          return {
            id: texto(r, "id"),
            folio: texto(r, "folio"),
            hornoId: texto(r, "oven_id"),
            horno: texto(rs.get(texto(r, "oven_id")), "code"),
            estado: texto(r, "status") as "abierta" | "cerrada",
            inicio: texto(r, "started_at"),
            fin: texto(r, "ended_at") || null,
            cargados: input.reduce((n, i) => n + numero(i, "quantity_kg"), 0),
            cocidos: r.cooked_kg == null ? null : numero(r, "cooked_kg"),
            combustible: texto(r, "fuel_note"),
            origenes: input
              .map(
                (i) =>
                  `${texto(ls.get(texto(i, "lot_id")), "folio")} · ${numero(i, "quantity_kg")} kg`,
              )
              .join(" / "),
            quien: quien(os.get(texto(r, "operation_id"))),
          }
        })
        .sort((a, b) => b.inicio.localeCompare(a.inicio)),
      hornos: recursos
        .filter((r) => r.kind === "horno" && r.active === true)
        .map((r) => ({
          id: texto(r, "id"),
          nombre: texto(r, "code"),
          capacidad: r.capacity == null ? null : numero(r, "capacity"),
        })),
      especies: opcion(especies, "common_name"),
      predios: opcion(predios),
      proveedores: opcion(proveedores),
    }
  })
}
export function parametrosMH(org: string, c: CapturaMH) {
  const base = {
    p_org: org,
    p_idem: c.idem,
    p_fecha: c.fecha ? new Date(c.fecha).toISOString() : new Date().toISOString(),
    p_folio: c.folio.trim() || null,
    p_nota: c.nota.trim() || null,
  }
  switch (c.tipo) {
    case "recepcion":
      return {
        rpc: "registrar_recepcion_maguey",
        params: {
          ...base,
          p_kg: c.kg,
          p_pinas: c.pinas,
          p_especie: c.especie || null,
          p_predio: c.predio || null,
          p_proveedor: c.proveedor || null,
        },
      }
    case "abrir":
      return {
        rpc: "abrir_horneado",
        params: {
          ...base,
          p_horno: c.horno,
          p_lotes: c.lotes.map((l) => l.id),
          p_kilos: c.lotes.map((l) => l.kg),
        },
      }
    case "cerrar":
      return {
        rpc: "cerrar_horneado",
        params: {
          ...base,
          p_horneado: c.horneada,
          p_kilos_cocidos: c.kg,
          p_combustible: c.combustible.trim() || null,
        },
      }
    case "cocido":
      return {
        rpc: "registrar_entrada",
        params: {
          ...base,
          p_material: "agave_cocido",
          p_recurso: null,
          p_cantidad: c.kg,
          p_origen: "carga_inicial",
        },
      }
  }
}
export async function guardarMH(org: string, c: CapturaMH) {
  const errorLocal = errorCaptura(c)
  if (errorLocal) throw new RechazoCapturaMH(errorLocal)
  if (!org || !navigator.onLine) throw new Error(MENSAJE_RED)
  const { rpc, params } = parametrosMH(org, c)
  const { data, error } = await supabase.rpc(rpc, params)
  if (error) {
    const mensaje = esErrorDeRed(error) ? MENSAJE_RED : traducirErrorRpc(error).mensaje
    // Sólo una excepción transaccional conocida prueba que NO hubo commit.
    // HTTP/proxy/timeout y errores desconocidos conservan la intención original.
    if (/^(P0001|22\w{3}|23\w{3}|42501)$/.test(error.code ?? ""))
      throw new RechazoCapturaMH(mensaje)
    throw new Error(mensaje)
  }
  return String(data)
}
