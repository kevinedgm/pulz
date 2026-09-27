// Utilidades compartidas por las Edge Functions de PULZ (Deno).
// Mensajes en español para la persona; códigos estables para el cliente.

export const SLUG_RE = /^[a-z0-9]([a-z0-9-]{1,38}[a-z0-9])$/
export const USERNAME_RE = /^[a-z0-9]([a-z0-9._-]{1,28}[a-z0-9])$/
export const CONTRASENA_MIN = 8
export const MENSAJE_RECHAZO = "Usuario o contraseña incorrectos"

export function ok(data: unknown, status = 200): Response {
  return Response.json(data, { status })
}

export function fallo(status: number, codigo: string, mensaje: string): Response {
  return Response.json({ error: { codigo, mensaje } }, { status })
}

export async function leerJson<T>(req: Request): Promise<T> {
  try {
    return (await req.json()) as T
  } catch {
    throw new Error("CUERPO_INVALIDO")
  }
}

// Mismo cálculo que member_login_email() en Postgres (0012_portal.sql):
// usa el id de la empresa, no el slug, para que renombrar el portal no
// toque ninguna cuenta (§7.2).
export function correoSintetico(organizationId: string, username: string): string {
  return `${username.toLowerCase()}@${organizationId}.usuarios.pulz.mx`
}

export async function sha256hex(texto: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(texto))
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
}

export function tokenAleatorio(bytes = 32): string {
  const arr = new Uint8Array(bytes)
  crypto.getRandomValues(arr)
  return btoa(String.fromCharCode(...arr))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "")
}

export function urlPublica(): string {
  return (Deno.env.get("PULZ_PUBLIC_URL") ?? "http://localhost:5173").replace(/\/+$/, "")
}

// Traduce los errores con prefijo de las RPC (§12.1) a HTTP.
export function desdeErrorPg(mensaje: string): Response {
  if (mensaje.startsWith("NO_PERMITIDO:"))
    return fallo(403, "NO_PERMITIDO", mensaje.slice(13).trim())
  if (mensaje.startsWith("LIMITE_PLAN:")) return fallo(402, "LIMITE_PLAN", mensaje)
  if (mensaje.startsWith("REQUIERE_NOTA:")) return fallo(422, "REQUIERE_NOTA", mensaje)
  return fallo(400, "ERROR", mensaje)
}
