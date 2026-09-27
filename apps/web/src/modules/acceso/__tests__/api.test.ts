// correoDeAcceso: mismo cálculo que member_login_email() en Postgres (0012).
import { describe, expect, it } from "vitest"
import { correoDeAcceso } from "../api"

const ORG = "b66cf468-47f7-51ee-a8f2-994d907440b9"

describe("correoDeAcceso", () => {
  it("con @ es el titular: su correo real, normalizado", () => {
    expect(correoDeAcceso(ORG, "  Benito@CuatroVientos.mx ")).toBe("benito@cuatrovientos.mx")
  })

  it("sin @ es colaborador: correo sintético con el id de la empresa, no el slug", () => {
    expect(correoDeAcceso(ORG, "Tomas.H")).toBe(`tomas.h@${ORG}.usuarios.pulz.mx`)
  })
})
