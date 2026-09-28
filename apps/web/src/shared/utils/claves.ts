// Clave de idempotencia generada en el teléfono (§8.3, §12.1): un UUID por
// captura, creado ANTES de intentar enviar, para que reintentar no duplique.
export const nuevaClave = () =>
  typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`
