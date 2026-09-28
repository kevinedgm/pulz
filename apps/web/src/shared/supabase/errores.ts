// Errores tipados del acceso y de las Edge Functions (PULZ_MAESTRO.md §7.5,
// §12.1). Regla dura: TODO rechazo de inicio de sesión muestra el mismo
// texto, sin distinguir causa.

export const MENSAJE_RECHAZO = "Usuario o contraseña incorrectos"
export const MENSAJE_ENLACE = "El enlace no es válido o ya se usó"
export const MENSAJE_RED = "No pudimos conectar. Revisa tu señal."

export type CodigoAcceso = "RECHAZO" | "RED" | "ENLACE" | "SERVIDOR"

export class ErrorAcceso extends Error {
  readonly codigo: CodigoAcceso
  constructor(codigo: CodigoAcceso, mensaje: string) {
    super(mensaje)
    this.name = "ErrorAcceso"
    this.codigo = codigo
  }
}

// Respuesta de error de las Edge Functions: { error: { codigo, mensaje } }
export interface ErrorFuncion {
  codigo: string
  mensaje: string
}

// Cualquier fallo de signInWithPassword (usuario inexistente, contraseña
// mala, cuenta suspendida, empresa que no coincide) → el mismo texto. Solo
// un fallo de red se distingue, porque la persona puede hacer algo distinto.
export function rechazoDeLogin(e: unknown): ErrorAcceso {
  if (esErrorDeRed(e)) return new ErrorAcceso("RED", MENSAJE_RED)
  return new ErrorAcceso("RECHAZO", MENSAJE_RECHAZO)
}

export function esErrorDeRed(e: unknown): boolean {
  if (e instanceof ErrorAcceso) return e.codigo === "RED"
  const detalle = e as { message?: string; code?: string; rpc?: { codigo: string } } | null
  // PostgREST devuelve objetos planos. Un error de permisos/dominio recibido
  // del servidor sigue siendo tal aunque el teléfono pierda señal después.
  if (detalle?.rpc) return detalle.rpc.codigo === "RED"
  if (detalle?.code && /^(?:[0-9A-Z]{5}|PGRST\d+)$/.test(detalle.code)) return false
  if (typeof navigator !== "undefined" && navigator.onLine === false) return true
  const msg = e instanceof Error ? e.message : (detalle?.message ?? String(e ?? ""))
  return /fetch|network|Failed to fetch|NetworkError|timeout/i.test(msg)
}

// ---------------------------------------------------------------------
// Errores de las RPC de dominio (§12.1): prefijos estables para el cliente.
// Un solo traductor para todas las pantallas de captura y para la cola.
// ---------------------------------------------------------------------
export type CodigoRpc = "RED" | "SALDO" | "CAPACIDAD" | "PERMISO" | "PLAN" | "NOTA" | "SERVIDOR"

export interface ErrorRpc {
  codigo: CodigoRpc
  mensaje: string
  // REQUIERE_NOTA:<código>: el aviso blando que pide nota (o el dato que falta)
  requiereNota?: string
}

// Texto para la persona por cada aviso blando (rpc_warn de 0014–0019). El
// aviso no bloquea: con una nota, la misma captura pasa (§2.1).
export const AVISOS: Record<string, string> = {
  brix_fuera_rango:
    "El Brix está fuera del rango habitual de la empresa. Agrega una nota y vuelve a guardar.",
  abv_fuera_rango: "El % Alc. está fuera del rango habitual. Agrega una nota y vuelve a guardar.",
  mezcla_clases_2a:
    "Ordinario y colas juntos en la segunda pasada. Agrega una nota y vuelve a guardar.",
  excede_capacidad:
    "Se pasa de la capacidad del recurso (política flexible). Agrega una nota y vuelve a guardar.",
  cierre_con_saldo:
    "La corrida se cierra con líquido sin cortar. Agrega una nota y vuelve a guardar.",
  diferencia_volumen:
    "El volumen declarado no cuadra con lo que había; se registrará la diferencia. Agrega una nota y vuelve a guardar.",
  contraparte: "Este movimiento pide con quién fue (cliente, laboratorio, proveedor).",
  anular_medicion: "Para anular una medición hay que dar el motivo.",
}

const mensajeDe = (e: unknown) =>
  e instanceof Error ? e.message : ((e as { message?: string })?.message ?? String(e ?? ""))

export function traducirErrorRpc(e: unknown): ErrorRpc {
  if (esErrorDeRed(e)) return { codigo: "RED", mensaje: MENSAJE_RED }
  const msg = mensajeDe(e).trim()
  const m =
    /^(SALDO_INSUFICIENTE|CAPACIDAD_EXCEDIDA|NO_PERMITIDO|LIMITE_PLAN|REQUIERE_NOTA):\s*(.*)$/s.exec(
      msg,
    )
  if (m) {
    const resto = m[2].trim()
    switch (m[1]) {
      case "SALDO_INSUFICIENTE":
        return { codigo: "SALDO", mensaje: `No alcanza: ${resto}` }
      case "CAPACIDAD_EXCEDIDA":
        return { codigo: "CAPACIDAD", mensaje: `No cabe: ${resto}` }
      case "NO_PERMITIDO":
        return { codigo: "PERMISO", mensaje: resto }
      case "LIMITE_PLAN":
        return { codigo: "PLAN", mensaje: resto }
      case "REQUIERE_NOTA":
        return {
          codigo: "NOTA",
          requiereNota: resto,
          mensaje: AVISOS[resto] ?? "Esta captura necesita una nota para guardarse.",
        }
    }
  }
  if (/permission denied|row-level security/i.test(msg))
    return { codigo: "PERMISO", mensaje: "No tienes permiso para registrar esto." }
  return { codigo: "SERVIDOR", mensaje: msg || "Algo falló en el servidor." }
}

// Lee { error: { codigo, mensaje } } de una respuesta de Edge Function.
export async function errorDeFuncion(res: Response): Promise<ErrorAcceso> {
  try {
    const body = (await res.json()) as { error?: ErrorFuncion }
    if (body.error?.mensaje) {
      const codigo = body.error.codigo === "ENLACE" ? "ENLACE" : "SERVIDOR"
      return new ErrorAcceso(codigo, body.error.mensaje)
    }
  } catch {
    /* sin cuerpo JSON */
  }
  return new ErrorAcceso("SERVIDOR", `Algo falló en el servidor (${res.status}).`)
}
