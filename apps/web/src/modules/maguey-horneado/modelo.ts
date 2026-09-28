export interface Opcion {
  id: string
  nombre: string
  active?: boolean
}
export interface Horno extends Opcion {
  capacidad: number | null
}
export interface LoteSolido {
  id: string
  folio: string
  material: "maguey" | "agave_cocido"
  inicial: number
  saldo: number
  contexto: string
  nota: string
  cuando: string
  quien: string
}
export interface Horneada {
  id: string
  folio: string
  hornoId: string
  horno: string
  estado: "abierta" | "cerrada"
  inicio: string
  fin: string | null
  cargados: number
  cocidos: number | null
  combustible: string
  origenes: string
  quien: string
}
export interface DatosMH {
  lotes: LoteSolido[]
  horneadas: Horneada[]
  hornos: Horno[]
  especies: Opcion[]
  predios: Opcion[]
  proveedores: Opcion[]
}
export interface BaseCaptura {
  idem: string
  fecha: string | null
  folio: string
  nota: string
}
export interface Recepcion extends BaseCaptura {
  tipo: "recepcion"
  kg: number
  pinas: number | null
  especie: string
  predio: string
  proveedor: string
}
export interface Apertura extends BaseCaptura {
  tipo: "abrir"
  horno: string
  lotes: { id: string; kg: number }[]
}
export interface Cierre extends BaseCaptura {
  tipo: "cerrar"
  horneada: string
  kg: number
  combustible: string
}
export interface EntradaCocido extends BaseCaptura {
  tipo: "cocido"
  kg: number
}
export type CapturaMH = Recepcion | Apertura | Cierre | EntradaCocido
export interface BorradorCocido {
  idem: string
  kg: number | null
  combustible: string
  nota: string
  folio: string
  fecha: string | null
}
export const nuevoBorradorCocido = (): BorradorCocido => ({
  idem: crypto.randomUUID(),
  kg: null,
  combustible: "",
  nota: "",
  folio: "",
  fecha: null,
})
export const kilos = (n: number) =>
  `${new Intl.NumberFormat("es-MX", { maximumFractionDigits: 3 }).format(n)} kg`
export const positivo = (n: number | null) => n !== null && Number.isFinite(n) && n > 0
export function errorCaptura(c: CapturaMH): string | null {
  if (
    c.fecha &&
    (!Number.isFinite(Date.parse(c.fecha)) || Date.parse(c.fecha) > Date.now() + 60000)
  )
    return "Revisa la fecha: no puede estar en el futuro."
  if (c.tipo === "abrir") {
    if (!c.horno || !c.lotes.length || c.lotes.some((l) => !l.id || !positivo(l.kg)))
      return "Elige horno y kilos positivos por lote."
    if (new Set(c.lotes.map((l) => l.id)).size !== c.lotes.length)
      return "Cada lote debe aparecer una sola vez."
  } else if (!positivo(c.kg)) return "Indica kilos mayores a cero."
  if (c.tipo === "recepcion" && c.pinas !== null && (!Number.isInteger(c.pinas) || c.pinas < 0))
    return "Las piñas deben ser un entero no negativo."
  return null
}
