// signup-company · Alta de empresa en autoservicio (PULZ_MAESTRO.md §1.4,
// §7.2, §12.2 provision_organization, §16 Fase 3).
//
// La llama la página pública de registro con la llave publishable. Crea la
// cuenta del titular en Auth (correo real, pendiente de confirmar), crea la
// empresa con provision_organization (service_role) y manda el correo de
// confirmación. Si la empresa no se puede crear (slug reservado o tomado),
// borra la cuenta recién creada: nada queda a medias.

import { withSupabase } from "npm:@supabase/server"
import { CONTRASENA_MIN, SLUG_RE, desdeErrorPg, fallo, leerJson, ok } from "../_shared/util.ts"

interface Cuerpo {
  nombre: string
  slug: string
  correo: string
  contrasena: string
  nombre_titular: string
  estado?: string
  color?: string
  mensaje?: string
}

export default {
  fetch: withSupabase({ auth: "publishable" }, async (req, ctx) => {
    if (req.method !== "POST") return fallo(405, "METODO", "Usa POST")
    let b: Cuerpo
    try {
      b = await leerJson<Cuerpo>(req)
    } catch {
      return fallo(400, "CUERPO_INVALIDO", "El cuerpo debe ser JSON")
    }

    const nombre = (b.nombre ?? "").trim()
    const slug = (b.slug ?? "").trim().toLowerCase()
    const correo = (b.correo ?? "").trim().toLowerCase()
    const titular = (b.nombre_titular ?? "").trim()
    if (!nombre || !titular)
      return fallo(422, "FALTAN_DATOS", "Faltan el nombre de la empresa o del titular")
    if (!SLUG_RE.test(slug) || slug.includes("--")) {
      return fallo(
        422,
        "SLUG_INVALIDO",
        "El nombre del portal solo lleva minúsculas, números y guiones (3 a 40 caracteres)",
      )
    }
    if (!correo.includes("@"))
      return fallo(422, "CORREO_INVALIDO", "El correo del titular no es válido")
    if ((b.contrasena ?? "").length < CONTRASENA_MIN) {
      return fallo(
        422,
        "CONTRASENA_CORTA",
        `La contraseña debe tener al menos ${CONTRASENA_MIN} caracteres`,
      )
    }
    if (b.color && !/^#[0-9A-Fa-f]{6}$/.test(b.color))
      return fallo(422, "COLOR_INVALIDO", "El color va como #RRGGBB")

    // 1) Cuenta del titular, pendiente de confirmar el correo
    const creado = await ctx.supabaseAdmin.auth.admin.createUser({
      email: correo,
      password: b.contrasena,
      email_confirm: false,
      user_metadata: { full_name: titular },
    })
    if (creado.error || !creado.data.user) {
      return fallo(409, "CUENTA", "No se pudo crear la cuenta con ese correo")
    }
    const userId = creado.data.user.id

    // 2) Empresa + membresía admin + ajustes + suscripción gratis + catálogos
    const prov = await ctx.supabaseAdmin.rpc("provision_organization", {
      p_nombre: nombre,
      p_slug: slug,
      p_admin: userId,
      p_admin_nombre: titular,
      p_estado: b.estado ?? null,
      p_color: b.color ?? null,
      p_mensaje: b.mensaje ?? null,
    })
    if (prov.error) {
      await ctx.supabaseAdmin.auth.admin.deleteUser(userId)
      return desdeErrorPg(prov.error.message)
    }

    // 3) Correo de confirmación (lo manda Auth; el titular sí recibe correos, §7.2)
    await ctx.supabase.auth.resend({ type: "signup", email: correo })

    return ok({ organization_id: prov.data, slug }, 201)
  }),
}
