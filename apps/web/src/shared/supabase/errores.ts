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
  if (typeof navigator !== "undefined" && navigator.onLine === false) return true
  const msg = e instanceof Error ? e.message : String(e ?? "")
  return /fetch|network|Failed to fetch|NetworkError|timeout/i.test(msg)
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
