// Fotos como evidencia (§8.1 bucket privado 'evidencias', 0027): se reducen
// en el navegador antes de encolarse (un blob de cámara pesa 3–8 MB; en la
// cola caben muchas) y al reconectar suben a
// evidencias/<org>/<operation_id>/<uuid>.<ext> con su fila en attachments.
import { supabase } from "../supabase/client"
import { nuevaClave } from "../utils/claves"

export interface FotoPendiente {
  blob: Blob
  tipo: string // image/jpeg | image/png | image/webp
  lot_id: string
  kind_item_id: string // catálogo tipo_adjunto ("Foto")
  caption?: string
}

export const LADO_MAXIMO = 1600

// Reduce a LADO_MAXIMO px por el lado mayor y recodifica a JPEG 0.85. Si el
// navegador no puede (sin canvas), devuelve el archivo tal cual.
export async function reducirImagen(archivo: Blob, maximo = LADO_MAXIMO): Promise<Blob> {
  if (typeof createImageBitmap !== "function" || typeof document === "undefined") return archivo
  try {
    const bmp = await createImageBitmap(archivo)
    const escala = Math.min(1, maximo / Math.max(bmp.width, bmp.height))
    if (escala === 1 && archivo.type === "image/jpeg") return archivo
    const c = document.createElement("canvas")
    c.width = Math.round(bmp.width * escala)
    c.height = Math.round(bmp.height * escala)
    c.getContext("2d")?.drawImage(bmp, 0, 0, c.width, c.height)
    return await new Promise<Blob>((resolve) =>
      c.toBlob((b) => resolve(b ?? archivo), "image/jpeg", 0.85),
    )
  } catch {
    return archivo
  }
}

const extension = (tipo: string) =>
  tipo === "image/png"
    ? "png"
    : tipo === "image/webp"
      ? "webp"
      : tipo === "application/pdf"
        ? "pdf"
        : "jpg"

export async function subirEvidencia(
  org: string,
  operationId: string,
  foto: FotoPendiente,
): Promise<void> {
  const ruta = `${org}/${operationId}/${nuevaClave()}.${extension(foto.tipo)}`
  const { error } = await supabase.storage
    .from("evidencias")
    .upload(ruta, foto.blob, { contentType: foto.tipo, upsert: false })
  if (error) throw error
  const { error: e2 } = await supabase.from("attachments").insert({
    organization_id: org,
    operation_id: operationId,
    lot_id: foto.lot_id,
    kind_item_id: foto.kind_item_id,
    storage_path: `evidencias/${ruta}`,
    caption: foto.caption ?? null,
  })
  if (e2) throw e2
}
