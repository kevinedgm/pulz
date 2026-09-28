// Vocabulario y formato puros del dominio de fermentación. Este módulo no
// conoce Supabase ni efectos, para que componentes y previews lo consuman
// sin inicializar infraestructura.
export const ETIQUETAS_ACTIVIDAD = ["quieta", "apenas", "poca", "media", "mucha", "muy activa"]
export const ETIQUETAS_DULZOR = ["nada", "poco", "algo", "medio", "dulce", "muy dulce"]
export const ETIQUETAS_ACIDEZ = ["nada", "poca", "algo", "media", "ácida", "muy ácida"]

export const litros = (valor: number) => `${new Intl.NumberFormat("es-MX").format(valor)} L`

// La capacidad es un límite duro solo bajo política estricta (§2.1).
// Flexible necesita nota en la RPC; libre no añade un límite de captura.
export function limiteDeTina(tina: {
  capacity: number | null
  capacity_policy: "estricta" | "flexible" | "libre"
}): number | null {
  return tina.capacity_policy === "estricta" ? tina.capacity : null
}
