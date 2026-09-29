// correoDeAcceso: mismo cálculo que member_login_email() en Postgres (0012).
import { describe, expect, it, vi } from "vitest"
import { correoDeAcceso } from "../api"

// api.ts importa el cliente de Supabase, que exige VITE_* al cargar: en CI
// no hay .env.local y estas pruebas son puras.
vi.mock("../../../shared/supabase/client", () => ({ supabase: {} }))

const ORG = "b66cf468-47f7-51ee-a8f2-994d907440b9"

describe("correoDeAcceso", () => {
  it("con @ es el titular: su correo real, normalizado", () => {
    expect(correoDeAcceso(ORG, "  Benito@CuatroVientos.mx ")).toBe("benito@cuatrovientos.mx")
  })

  it("sin @ es colaborador: correo sintético con el id de la empresa, no el slug", () => {
    expect(correoDeAcceso(ORG, "Tomas.H")).toBe(`tomas.h@${ORG}.usuarios.pulz.mx`)
  })
})
