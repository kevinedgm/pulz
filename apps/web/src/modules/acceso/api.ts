// Acceso (PULZ_MAESTRO.md §7): lo único que el navegador hace con el
// servidor para entrar. Contrato de datos: coco.data_contract del perfil.
import { supabase } from "../../shared/supabase/client"
import {
  ErrorAcceso,
  errorDeFuncion,
  esErrorDeRed,
  MENSAJE_RED,
  rechazoDeLogin,
} from "../../shared/supabase/errores"

export interface PortalBranding {
  organization_id: string
  slug: string
  name: string
  logo_path: string | null
  brand_color: string | null
  welcome_message: string | null
  read_only: boolean
  redirect_to: string | null
}

export type Rol = "admin" | "productor" | "operador"
export type EstadoMiembro = "invitado" | "activo" | "suspendido"

export interface MiMembresia {
  organization_id: string
  slug: string
  name: string
  brand_color: string | null
  logo_path: string | null
  role: Rol
  status: EstadoMiembro
  username: string | null
  must_change_password: boolean
  read_only: boolean
  cancelled: boolean
}

const url = import.meta.env.VITE_SUPABASE_URL
const publishable = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

// Mismo cálculo que member_login_email() en Postgres (0012): usa el id de
// la empresa, no el slug (§7.2).
export function correoDeAcceso(organizationId: string, usuarioOCorreo: string): string {
  const v = usuarioOCorreo.trim().toLowerCase()
  return v.includes("@") ? v : `${v}@${organizationId}.usuarios.pulz.mx`
}

export function urlLogo(logoPath: string | null): string | null {
  return logoPath ? `${url}/storage/v1/object/public/branding/${logoPath}` : null
}

// Sin fila = empresa inexistente o cancelada: el mismo 404 (§7.4).
export async function portalBranding(slug: string): Promise<PortalBranding | null> {
  const { data, error } = await supabase.rpc("portal_branding", { p_slug: slug })
  if (error)
    throw new ErrorAcceso(
      esErrorDeRed(error) ? "RED" : "SERVIDOR",
      esErrorDeRed(error) ? MENSAJE_RED : error.message,
    )
  const filas = (data ?? []) as PortalBranding[]
  return filas[0] ?? null
}

// DIRECTO contra Auth, sin función intermedia (§7.5): cada intento cuenta
// contra la IP real de quien lo hace. Cualquier rechazo → el mismo texto.
export async function entrar(
  organizationId: string,
  usuarioOCorreo: string,
  contrasena: string,
): Promise<void> {
  const { error } = await supabase.auth.signInWithPassword({
    email: correoDeAcceso(organizationId, usuarioOCorreo),
    password: contrasena,
  })
  if (error) throw rechazoDeLogin(error)
}

export async function cerrarSesion(): Promise<void> {
  await supabase.auth.signOut()
}

export async function haySesion(): Promise<boolean> {
  const { data } = await supabase.auth.getSession()
  return Boolean(data.session)
}

export async function misMembresias(): Promise<MiMembresia[]> {
  const { data, error } = await supabase.from("mis_membresias").select("*")
  if (error)
    throw new ErrorAcceso(
      esErrorDeRed(error) ? "RED" : "SERVIDOR",
      esErrorDeRed(error) ? MENSAJE_RED : error.message,
    )
  return (data ?? []) as MiMembresia[]
}

// Recuperación del titular: el flujo estándar de Auth por correo (§7.2).
export async function pedirRecuperacion(correo: string, slug: string): Promise<void> {
  const { error } = await supabase.auth.resetPasswordForEmail(correo, {
    redirectTo: `${location.origin}/e/${slug}/cambiar-contrasena`,
  })
  if (error)
    throw new ErrorAcceso(
      esErrorDeRed(error) ? "RED" : "SERVIDOR",
      esErrorDeRed(error) ? MENSAJE_RED : error.message,
    )
}

// set-password (Edge Function): con token de bienvenida (sin sesión) o con
// sesión (cambio obligatorio). La bandera must_change_password la baja el
// servidor.
export async function fijarContrasena(
  contrasena: string,
  token?: string,
): Promise<{ slug: string | null; loginEmail: string | null }> {
  const { data } = await supabase.auth.getSession()
  const jwt = data.session?.access_token
  let res: Response
  try {
    res = await fetch(`${url}/functions/v1/set-password`, {
      method: "POST",
      headers: {
        apikey: publishable,
        "content-type": "application/json",
        ...(jwt && !token ? { authorization: `Bearer ${jwt}` } : {}),
      },
      body: JSON.stringify(token ? { contrasena, token } : { contrasena }),
    })
  } catch (e) {
    throw new ErrorAcceso("RED", esErrorDeRed(e) ? MENSAJE_RED : String(e))
  }
  if (!res.ok) throw await errorDeFuncion(res)
  const body = (await res.json()) as {
    ok: boolean
    slug?: string | null
    login_email?: string | null // solo al canjear un token (DUDAS #11)
  }
  return { slug: body.slug ?? null, loginEmail: body.login_email ?? null }
}
