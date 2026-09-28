// Contratos cerrados del sistema PULZ (design-hub/system/registry.json).
// La API expresa intención, nunca estilo: el sistema decide cómo se pinta.

export type BotonIntent = "primary" | "secondary" | "quiet" | "danger"
export type BotonAdapt = "default" | "page-primary"
export type CampoSize = "md" | "lg"
export type ChipVariante = "on" | "draft" | "off" | "partial"
export type AvisoVariante = "offline" | "readonly"
export type BloqueEstadoVariante = "empty" | "error" | "denied"

// Símbolos reales del sprite apps/web/src/shared/ui/iconos.svg (un solo set)
export type IconoNombre =
  | "i-maguey"
  | "i-horno"
  | "i-molienda"
  | "i-tina"
  | "i-destila"
  | "i-lote"
  | "i-home"
  | "i-medir"
  | "i-mas"
  | "i-bell"
  | "i-clock"
  | "i-tanque"
  | "i-traza"
  | "i-ajustes"
  | "i-menu"
  | "pulz-mark"

export interface OpcionSegmento<T extends string = string> {
  valor: T
  etiqueta: string
  ayuda?: string
}

export interface AccionFila {
  id: string
  etiqueta: string
  intent?: Extract<BotonIntent, "secondary" | "danger">
}

// Ítem de navegación (registry: bottom-nav, side-nav). Sin dominio: el
// consumidor (app/destinos.ts) decide qué destinos existen y quién los ve.
export interface ItemNav {
  id: string
  etiqueta: string
  icono: IconoNombre
  to: string
}
