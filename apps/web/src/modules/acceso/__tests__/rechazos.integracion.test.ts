// Integración REAL contra el proyecto Supabase de desarrollo (CLAUDE.md:
// sin entorno local). Usa las variables de apps/web/.env.local y los usuarios
// de supabase/seed.sql. Criterio §16 Fase 3: los cuatro rechazos muestran
// exactamente el mismo texto; el titular entra.
import { afterAll, describe, expect, it } from "vitest"
import { MENSAJE_RECHAZO } from "../../../shared/supabase/errores"

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const CV = "b66cf468-47f7-51ee-a8f2-994d907440b9" // Mezcal Cuatro Vientos
const PB = "b0000000-0000-4000-8000-0000000000b0" // Palenque Prueba B

describe.skipIf(!url)("acceso contra el proyecto alojado", () => {
  afterAll(async () => {
    const { cerrarSesion } = await import("../api")
    await cerrarSesion()
  })

  it.each([
    ["empresa inexistente", "00000000-0000-4000-8000-000000000000", "aurelia", "aurelia-2026"],
    ["usuario inexistente", CV, "nadie", "loquesea"],
    ["contraseña mala", CV, "aurelia", "otra-cosa"],
    ["usuario de otra empresa", PB, "aurelia", "aurelia-2026"],
  ])("%s → mismo texto", async (_caso, org, usuario, contrasena) => {
    const { entrar } = await import("../api")
    await expect(entrar(org, usuario, contrasena)).rejects.toMatchObject({
      codigo: "RECHAZO",
      message: MENSAJE_RECHAZO,
    })
  })

  it("el titular entra con su correo y ve su membresía", async () => {
    const { entrar, misMembresias } = await import("../api")
    await entrar(CV, "Benito@CuatroVientos.mx", "benito-2026")
    const m = await misMembresias()
    expect(m.map((x) => x.slug)).toEqual(["cuatro-vientos"])
    expect(m[0]).toMatchObject({ role: "admin", status: "activo", must_change_password: false })
  })
})
