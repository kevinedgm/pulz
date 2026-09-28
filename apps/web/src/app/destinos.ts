// Destinos del shell (PULZ_MAESTRO.md §13.1): el menú sigue al proceso, no
// a las tablas. Una sola lista con dos presentaciones (barra inferior en
// compact, menú lateral en medium/expanded). Decisión 2026-09-27: fijos de
// compact = Inicio · Fermentación · Destilación · Granel; Configuración solo
// admin y nunca deshabilitada.
import type { IconoNombre, ItemNav } from "../shared/ui"

export interface Destino {
  id:
    | "inicio"
    | "maguey"
    | "horneado"
    | "fermentacion"
    | "destilacion"
    | "granel"
    | "trazabilidad"
    | "configuracion"
  titulo: string
  icono: IconoNombre
  soloAdmin?: boolean
  fijoEnCompact?: boolean
  // Qué habrá aquí (destinos vacíos hasta la Fase 5): texto honesto, sin datos
  proximamente?: string
}

export const DESTINOS: Destino[] = [
  { id: "inicio", titulo: "Inicio", icono: "i-home", fijoEnCompact: true },
  {
    id: "maguey",
    titulo: "Maguey",
    icono: "i-maguey",
  },
  {
    id: "horneado",
    titulo: "Horneado",
    icono: "i-horno",
  },
  {
    id: "fermentacion",
    titulo: "Fermentación",
    icono: "i-tina",
    fijoEnCompact: true,
  },
  {
    id: "destilacion",
    titulo: "Destilación",
    icono: "i-destila",
    fijoEnCompact: true,
  },
  {
    id: "granel",
    titulo: "Granel",
    icono: "i-tanque",
    fijoEnCompact: true,
  },
  {
    id: "trazabilidad",
    titulo: "Trazabilidad",
    icono: "i-traza",
    proximamente: "seguir un lote hacia atrás",
  },
  { id: "configuracion", titulo: "Configuración", icono: "i-ajustes", soloAdmin: true },
]

export function destinosVisibles(esAdmin: boolean): Destino[] {
  return DESTINOS.filter((d) => !d.soloAdmin || esAdmin)
}

export function itemsNav(slug: string, destinos: Destino[]): ItemNav[] {
  return destinos.map((d) => ({
    id: d.id,
    etiqueta: d.titulo,
    icono: d.icono,
    to: `/e/${slug}/${d.id}`,
  }))
}

export function destinoDeRuta(nombre: unknown): Destino | undefined {
  return DESTINOS.find((d) => d.id === nombre)
}
