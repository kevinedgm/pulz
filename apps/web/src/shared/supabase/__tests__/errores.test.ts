// §7.5: cualquier rechazo de inicio de sesión → el mismo texto. Solo la
// falta de red se distingue (la persona puede hacer algo distinto).
import { describe, expect, it } from "vitest"
import {
  ErrorAcceso,
  errorDeFuncion,
  esErrorDeRed,
  MENSAJE_RECHAZO,
  MENSAJE_RED,
  rechazoDeLogin,
} from "../errores"

describe("rechazoDeLogin", () => {
  it.each([
    ["usuario inexistente", new Error("Invalid login credentials")],
    ["contraseña mala", { message: "Invalid login credentials", status: 400 }],
    ["cuenta bloqueada por el hook", new Error("PULZ:BLOQUEADO")],
    ["correo no confirmado", new Error("Email not confirmed")],
    ["error sin forma", undefined],
  ])("%s → %s", (_caso, e) => {
    const r = rechazoDeLogin(e)
    expect(r).toBeInstanceOf(ErrorAcceso)
    expect(r.codigo).toBe("RECHAZO")
    expect(r.message).toBe(MENSAJE_RECHAZO)
  })

  it("solo la red se distingue", () => {
    const r = rechazoDeLogin(new TypeError("Failed to fetch"))
    expect(r.codigo).toBe("RED")
    expect(r.message).toBe(MENSAJE_RED)
  })
})

describe("esErrorDeRed", () => {
  it("reconoce fallos de fetch/red y nada más", () => {
    expect(esErrorDeRed(new TypeError("Failed to fetch"))).toBe(true)
    expect(esErrorDeRed(new Error("NetworkError when attempting to fetch resource."))).toBe(true)
    expect(esErrorDeRed(new Error("Invalid login credentials"))).toBe(false)
    expect(esErrorDeRed("NO_PERMITIDO: solo el administrador")).toBe(false)
  })
})

describe("errorDeFuncion", () => {
  const respuesta = (status: number, body?: unknown) =>
    new Response(body === undefined ? null : JSON.stringify(body), { status })

  it("lee { error: { codigo, mensaje } } y marca ENLACE aparte", async () => {
    const e = await errorDeFuncion(
      respuesta(400, {
        error: { codigo: "ENLACE", mensaje: "El enlace no es válido o ya se usó" },
      }),
    )
    expect(e.codigo).toBe("ENLACE")
    expect(e.message).toBe("El enlace no es válido o ya se usó")

    const s = await errorDeFuncion(
      respuesta(400, { error: { codigo: "USUARIO_EXISTE", mensaje: "Ese usuario ya existe" } }),
    )
    expect(s.codigo).toBe("SERVIDOR")
    expect(s.message).toBe("Ese usuario ya existe")
  })

  it("sin cuerpo JSON: mensaje genérico con el estado", async () => {
    const e = await errorDeFuncion(respuesta(502))
    expect(e.codigo).toBe("SERVIDOR")
    expect(e.message).toContain("502")
  })
})
