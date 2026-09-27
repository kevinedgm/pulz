// manage-member · Equipo (PULZ_MAESTRO.md §7.6, §11.1): solo el administrador
// de la empresa. Crea la cuenta en Auth (correo sintético, confirmada) y la
// membresía en una sola operación; entrega el acceso por contraseña dictada
// (must_change_password) o por enlace de bienvenida de un solo uso (72 h,
// se guarda solo el hash). También cambia rol/estado, reenvía el enlace y
// desbloquea el freno de intentos.

import { withSupabase } from "npm:@supabase/server"
import {
  CONTRASENA_MIN,
  USERNAME_RE,
  correoSintetico,
  desdeErrorPg,
  fallo,
  leerJson,
  ok,
  sha256hex,
  tokenAleatorio,
  urlPublica,
} from "../_shared/util.ts"

type Rol = "admin" | "productor" | "operador"
type Estado = "invitado" | "activo" | "suspendido"

interface Cuerpo {
  accion: "alta" | "rol" | "estado" | "desbloquear" | "reenviar"
  organization_id: string
  username?: string
  nombre?: string
  rol?: Rol
  modo?: "dictada" | "enlace"
  contrasena?: string
  user_id?: string
  estado?: Estado
}

const ROLES: Rol[] = ["admin", "productor", "operador"]
const ESTADOS: Estado[] = ["invitado", "activo", "suspendido"]

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") return fallo(405, "METODO", "Usa POST")
    const yo = ctx.userClaims?.id ?? (ctx.jwtClaims?.sub as string | undefined)
    if (!yo) return fallo(401, "SIN_SESION", "Inicia sesión")

    let b: Cuerpo
    try {
      b = await leerJson<Cuerpo>(req)
    } catch {
      return fallo(400, "CUERPO_INVALIDO", "El cuerpo debe ser JSON")
    }
    const org = b.organization_id
    if (!org) return fallo(422, "FALTAN_DATOS", "Falta la empresa")

    // ¿Es administrador de esa empresa? (has_role también rechaza si la
    // suscripción está vencida o cancelada, §11.2)
    const esAdmin = await ctx.supabase.rpc("has_role", { org, roles: ["admin"] })
    if (esAdmin.error || esAdmin.data !== true) {
      return fallo(403, "NO_PERMITIDO", "Solo el administrador de la empresa puede hacer esto")
    }
    const admin = ctx.supabaseAdmin

    const slugDe = async () => {
      const r = await admin.from("organizations").select("slug").eq("id", org).single()
      return r.data?.slug as string
    }
    const nuevoEnlace = async (userId: string) => {
      const token = tokenAleatorio(32)
      const ins = await admin.from("member_invitations").insert({
        organization_id: org,
        user_id: userId,
        token_hash: await sha256hex(token),
        created_by: yo,
      })
      if (ins.error) throw new Error(ins.error.message)
      return `${urlPublica()}/e/${await slugDe()}/bienvenida#${token}`
    }

    try {
      switch (b.accion) {
        case "alta": {
          const username = (b.username ?? "").trim().toLowerCase()
          const nombre = (b.nombre ?? "").trim()
          const rol = b.rol ?? "operador"
          const modo = b.modo ?? "enlace"
          if (!USERNAME_RE.test(username)) {
            return fallo(
              422,
              "USUARIO_INVALIDO",
              "El usuario lleva minúsculas, números, punto, guion o guion bajo (3 a 30 caracteres)",
            )
          }
          if (!nombre) return fallo(422, "FALTAN_DATOS", "Falta el nombre de la persona")
          if (!ROLES.includes(rol)) return fallo(422, "ROL_INVALIDO", "Rol desconocido")
          if (modo === "dictada" && (b.contrasena ?? "").length < CONTRASENA_MIN) {
            return fallo(
              422,
              "CONTRASENA_CORTA",
              `La contraseña debe tener al menos ${CONTRASENA_MIN} caracteres`,
            )
          }
          const dup = await admin
            .from("organization_members")
            .select("user_id")
            .eq("organization_id", org)
            .eq("username", username)
            .maybeSingle()
          if (dup.data) return fallo(409, "USUARIO_EXISTE", "Ese usuario ya existe en la empresa")

          const creado = await admin.auth.admin.createUser({
            email: correoSintetico(org, username),
            password: modo === "dictada" ? b.contrasena! : tokenAleatorio(24),
            email_confirm: true, // nunca recibe correos (§7.2)
            user_metadata: { full_name: nombre },
          })
          if (creado.error || !creado.data.user)
            return fallo(409, "CUENTA", "No se pudo crear la cuenta")
          const userId = creado.data.user.id

          const perfil = await admin.from("profiles").insert({ id: userId, full_name: nombre })
          if (perfil.error) throw new Error(perfil.error.message)
          const miembro = await admin.from("organization_members").insert({
            organization_id: org,
            user_id: userId,
            role: rol,
            username,
            status: modo === "dictada" ? "activo" : "invitado",
            must_change_password: modo === "dictada",
          })
          if (miembro.error) {
            await admin.auth.admin.deleteUser(userId)
            throw new Error(miembro.error.message)
          }
          return ok(
            {
              user_id: userId,
              username,
              enlace: modo === "enlace" ? await nuevoEnlace(userId) : null,
            },
            201,
          )
        }
        case "rol": {
          if (!b.user_id || !b.rol || !ROLES.includes(b.rol))
            return fallo(422, "FALTAN_DATOS", "Falta usuario o rol")
          const r = await admin
            .from("organization_members")
            .update({ role: b.rol })
            .eq("organization_id", org)
            .eq("user_id", b.user_id)
          if (r.error) throw new Error(r.error.message)
          return ok({ ok: true })
        }
        case "estado": {
          if (!b.user_id || !b.estado || !ESTADOS.includes(b.estado))
            return fallo(422, "FALTAN_DATOS", "Falta usuario o estado")
          if (b.user_id === yo && b.estado === "suspendido")
            return fallo(422, "NO_PERMITIDO", "No puedes suspenderte a ti mismo")
          const r = await admin
            .from("organization_members")
            .update({ status: b.estado })
            .eq("organization_id", org)
            .eq("user_id", b.user_id)
          if (r.error) throw new Error(r.error.message)
          return ok({ ok: true })
        }
        case "desbloquear": {
          if (!b.user_id) return fallo(422, "FALTAN_DATOS", "Falta el usuario")
          const r = await ctx.supabase.rpc("desbloquear_miembro", { p_org: org, p_user: b.user_id })
          if (r.error) return desdeErrorPg(r.error.message)
          return ok({ ok: true })
        }
        case "reenviar": {
          if (!b.user_id) return fallo(422, "FALTAN_DATOS", "Falta el usuario")
          const m = await admin
            .from("organization_members")
            .select("status")
            .eq("organization_id", org)
            .eq("user_id", b.user_id)
            .maybeSingle()
          if (!m.data) return fallo(404, "NO_ENCONTRADO", "Ese usuario no es de la empresa")
          return ok({ enlace: await nuevoEnlace(b.user_id) })
        }
        default:
          return fallo(422, "ACCION", "Acción desconocida")
      }
    } catch (e) {
      return desdeErrorPg((e as Error).message)
    }
  }),
}
