// Equipo (PULZ_MAESTRO.md §7.6, §11.1): solo el administrador. Lectura por
// la función equipo_miembros (0023); escrituras por la Edge Function
// manage-member. Contrato de datos: coco.data_contract del perfil.
import { supabase } from "../../shared/supabase/client"
import {
  ErrorAcceso,
  errorDeFuncion,
  esErrorDeRed,
  MENSAJE_RED,
} from "../../shared/supabase/errores"
import type { EstadoMiembro, Rol } from "../acceso/api"

export interface MiembroEquipo {
  organization_id: string
  user_id: string
  full_name: string
  username: string | null
  role: Rol
  status: EstadoMiembro
  must_change_password: boolean
  locked_until: string | null
  invitation_expires_at: string | null
  invitation_used: boolean | null
}

// Reglas de presentación (perfil): derivadas, no campos.
export const estaBloqueado = (m: MiembroEquipo) =>
  Boolean(m.locked_until && new Date(m.locked_until) > new Date())
export const enlaceVigente = (m: MiembroEquipo) =>
  m.invitation_used === false &&
  Boolean(m.invitation_expires_at) &&
  new Date(m.invitation_expires_at!) > new Date()
export const esTitular = (m: MiembroEquipo) => m.username === null

export async function equipoMiembros(organizationId: string): Promise<MiembroEquipo[]> {
  const { data, error } = await supabase.rpc("equipo_miembros", { p_org: organizationId })
  if (error)
    throw new ErrorAcceso(
      esErrorDeRed(error) ? "RED" : "SERVIDOR",
      esErrorDeRed(error) ? MENSAJE_RED : error.message,
    )
  return (data ?? []) as MiembroEquipo[]
}

export type AltaAcceso =
  | { modo: "enlace"; username: string; nombre: string; rol: Rol }
  | { modo: "dictada"; username: string; nombre: string; rol: Rol; contrasena: string }

export interface AltaCreada {
  user_id: string
  username: string
  enlace: string | null
}

async function llamar<T>(cuerpo: Record<string, unknown>): Promise<T> {
  const { data } = await supabase.auth.getSession()
  const jwt = data.session?.access_token
  if (!jwt) throw new ErrorAcceso("SERVIDOR", "Inicia sesión")
  let res: Response
  try {
    res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/manage-member`, {
      method: "POST",
      headers: {
        apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        authorization: `Bearer ${jwt}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(cuerpo),
    })
  } catch (e) {
    throw new ErrorAcceso("RED", esErrorDeRed(e) ? MENSAJE_RED : String(e))
  }
  if (!res.ok) throw await errorDeFuncion(res)
  return (await res.json()) as T
}

export const darDeAlta = (organization_id: string, alta: AltaAcceso) =>
  llamar<AltaCreada>({ accion: "alta", organization_id, ...alta })
export const cambiarRol = (organization_id: string, user_id: string, rol: Rol) =>
  llamar<{ ok: true }>({ accion: "rol", organization_id, user_id, rol })
export const cambiarEstado = (organization_id: string, user_id: string, estado: EstadoMiembro) =>
  llamar<{ ok: true }>({ accion: "estado", organization_id, user_id, estado })
export const desbloquear = (organization_id: string, user_id: string) =>
  llamar<{ ok: true }>({ accion: "desbloquear", organization_id, user_id })
export const reenviarEnlace = (organization_id: string, user_id: string) =>
  llamar<{ enlace: string }>({ accion: "reenviar", organization_id, user_id })
