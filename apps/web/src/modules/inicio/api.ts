// Inicio / Hoy (ronda inicio-hoy/r01, §13.2 #3): compone lo que producen
// Fermentación y Destilación sin inventar nada. `tieneLotes` decide si la
// empresa arranca (§13.2 #2); `cargarHoy` reutiliza las cargas de cada
// módulo (cada una con su instantánea) y aquí solo se derivan puras.
import { supabase } from "../../shared/supabase/client"
import { ErrorAcceso, esErrorDeRed, MENSAJE_RED } from "../../shared/supabase/errores"
import type { ConInstantanea } from "../../shared/offline/instantanea"
import type { ElementoCola } from "../../shared/offline/cola"
import { cargarUsos, type UsoTina } from "../fermentacion/api"
import { cargarDestilacion, type ColectorConSaldo, type Corrida } from "../destilacion/api"
import type { Ajustes } from "../configuracion/api"

export async function tieneLotes(organizationId: string): Promise<boolean> {
  const { count, error } = await supabase
    .from("lots")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", organizationId)
  if (error)
    throw new ErrorAcceso(
      esErrorDeRed(error) ? "RED" : "SERVIDOR",
      esErrorDeRed(error) ? MENSAJE_RED : error.message,
    )
  return (count ?? 0) > 0
}

export interface DatosHoy {
  usos: UsoTina[]
  ajustes: Pick<Ajustes, "measurement_reminder_hour" | "fermentation_expected_days">
  corridas: Corrida[] // solo abiertas
  colectores: ColectorConSaldo[]
}

// Dos instantáneas (fermentación y destilación): la fecha que se muestra es
// la más antigua, que es la peor noticia y la única honesta.
export function instantaneaMasAntigua(a: string | null, b: string | null): string | null {
  if (a && b) return a < b ? a : b
  return a ?? b
}

export async function cargarHoy(org: string): Promise<ConInstantanea<DatosHoy>> {
  const [f, d] = await Promise.all([cargarUsos(org), cargarDestilacion(org)])
  return {
    datos: {
      usos: f.datos.usos,
      ajustes: f.datos.ajustes,
      corridas: d.datos.corridas.filter((c) => c.status === "abierta"),
      colectores: d.datos.colectores,
    },
    instantanea: instantaneaMasAntigua(f.instantanea, d.instantanea),
  }
}

// La hora del recordatorio solo rotula y ordena; no oculta (DUDAS #13).
export function rotuloHora(ahora: Date, horaRecordatorio: number): string {
  return ahora.getHours() < horaRecordatorio
    ? `toca desde las ${horaRecordatorio}:00`
    : "toca medir"
}

const plural = (n: number, uno: string, varios: string) => `${n} ${n === 1 ? uno : varios}`

export function resumenHoy(n: { porMedir: number; corridas: number; cola: number }): string {
  return [
    plural(n.porMedir, "tina por medir", "tinas por medir"),
    n.corridas ? plural(n.corridas, "corrida abierta", "corridas abiertas") : "sin corridas",
    n.cola ? plural(n.cola, "captura por enviar", "capturas por enviar") : "nada por enviar",
  ].join(" · ")
}

// Hoy muestra hasta 8 filas por bloque; el resto se cuenta y se manda al destino.
export function recortar<T>(lista: T[], max = 8): { visibles: T[]; restantes: number } {
  return { visibles: lista.slice(0, max), restantes: Math.max(0, lista.length - max) }
}

export function fechaLarga(d: Date): string {
  return new Intl.DateTimeFormat("es-MX", {
    weekday: "long",
    day: "numeric",
    month: "long",
  }).format(d)
}
export function horaCorta(iso: string): string {
  return new Intl.DateTimeFormat("es-MX", { hour: "numeric", minute: "2-digit" }).format(
    new Date(iso),
  )
}

// A dónde lleva «Corregir» de un elemento de la cola (la pantalla de origen
// con la captura precargada, como en Fermentación y Destilación).
export function rutaCorregir(slug: string, e: ElementoCola): string | null {
  if (!e.requiereNota) return null
  if (e.rpc === "registrar_medicion")
    return `/e/${slug}/fermentacion/${String(e.params.p_ciclo)}/medir?corregir=${e.id}&volver=inicio`
  if (e.rpc === "registrar_corte")
    return `/e/${slug}/destilacion/${String(e.params.p_corrida)}/corte?corregir=${e.id}`
  return null
}
