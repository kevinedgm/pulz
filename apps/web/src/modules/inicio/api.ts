// Inicio (shell/r01): lo único que hoy necesita saber es si la empresa ya
// tiene lotes (si no, ofrece el primer arranque, §13.2 #2). Consulta bajo
// RLS (is_member); solo cuenta, no trae filas.
import { supabase } from "../../shared/supabase/client"
import { ErrorAcceso, esErrorDeRed, MENSAJE_RED } from "../../shared/supabase/errores"

export async function tieneLotes(organizationId: string): Promise<boolean> {
  const { count, error } = await supabase
    .from("lots")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", organizationId)
  if (error)
    throw new ErrorAcceso(
      esErrorDeRed(error) ? "RED" : "SERVIDOR",
      esErrorDeRed(error) ? MENSAJE_RED : error.message,
    )
  return (count ?? 0) > 0
}
