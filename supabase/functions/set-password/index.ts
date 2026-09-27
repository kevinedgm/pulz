// set-password · Dos caminos para fijar la contraseña (PULZ_MAESTRO.md §7.6):
//   (a) con sesión y must_change_password: la persona cambia la contraseña
//       dictada y el servidor baja la bandera;
//   (b) con token de bienvenida (sin sesión): verifica hash + vigencia + un
//       solo uso, fija la contraseña, marca used_at y activa la membresía.
// Nunca revela si un token existía: mismo mensaje para cualquier fallo.

import { withSupabase } from "npm:@supabase/server"
import { CONTRASENA_MIN, fallo, leerJson, ok, sha256hex } from "../_shared/util.ts"

interface Cuerpo {
  contrasena: string
  token?: string
}

const ENLACE_INVALIDO = "El enlace no es válido o ya se usó"

export default {
  fetch: withSupabase({ auth: ["user", "publishable"] }, async (req, ctx) => {
    if (req.method !== "POST") return fallo(405, "METODO", "Usa POST")
    let b: Cuerpo
    try {
      b = await leerJson<Cuerpo>(req)
    } catch {
      return fallo(400, "CUERPO_INVALIDO", "El cuerpo debe ser JSON")
    }
    if ((b.contrasena ?? "").length < CONTRASENA_MIN) {
      return fallo(
        422,
        "CONTRASENA_CORTA",
        `La contraseña debe tener al menos ${CONTRASENA_MIN} caracteres`,
      )
    }
    const admin = ctx.supabaseAdmin

    // (b) Enlace de bienvenida
    if (b.token) {
      const hash = await sha256hex(b.token)
      const inv = await admin
        .from("member_invitations")
        .select("id, organization_id, user_id, expires_at, used_at")
        .eq("token_hash", hash)
        .maybeSingle()
      const vigente = inv.data && !inv.data.used_at && new Date(inv.data.expires_at) > new Date()
      if (!vigente) return fallo(400, "ENLACE", ENLACE_INVALIDO)

      const upd = await admin.auth.admin.updateUserById(inv.data!.user_id, {
        password: b.contrasena,
      })
      if (upd.error) return fallo(400, "ENLACE", ENLACE_INVALIDO)
      await admin
        .from("member_invitations")
        .update({ used_at: new Date().toISOString() })
        .eq("id", inv.data!.id)
      await admin
        .from("organization_members")
        .update({ status: "activo", must_change_password: false })
        .eq("organization_id", inv.data!.organization_id)
        .eq("user_id", inv.data!.user_id)
      const o = await admin
        .from("organizations")
        .select("slug")
        .eq("id", inv.data!.organization_id)
        .single()
      return ok({ ok: true, slug: o.data?.slug ?? null })
    }

    // (a) Con sesión
    const yo = ctx.userClaims?.id ?? (ctx.jwtClaims?.sub as string | undefined)
    if (ctx.authMode !== "user" || !yo)
      return fallo(401, "SIN_SESION", "Inicia sesión o usa tu enlace de bienvenida")
    const upd = await admin.auth.admin.updateUserById(yo, { password: b.contrasena })
    if (upd.error) return fallo(400, "CONTRASENA", "No se pudo cambiar la contraseña")
    await admin
      .from("organization_members")
      .update({ must_change_password: false })
      .eq("user_id", yo)
    return ok({ ok: true })
  }),
}
