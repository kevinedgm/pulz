// Estado de acceso: el portal de la empresa (por slug), la sesión y las
// membresías de la persona. Las guardias del router leen de aquí.
import { defineStore } from "pinia"
import { computed, ref } from "vue"
import {
  cerrarSesion as apiCerrarSesion,
  entrar as apiEntrar,
  haySesion,
  misMembresias,
  portalBranding,
  type MiMembresia,
  type PortalBranding,
} from "./api"

const CLAVE_ULTIMO_USUARIO = (slug: string) => `pulz:ultimo-usuario:${slug}`

export const useAcceso = defineStore("acceso", () => {
  const slug = ref<string | null>(null)
  // undefined = cargando · null = sin fila (404 idéntico) · objeto = marca
  const portal = ref<PortalBranding | null | undefined>(undefined)
  const membresias = ref<MiMembresia[] | null>(null) // null = no cargadas
  const sesion = ref<boolean | null>(null) // null = no comprobada
  let revisionSesion = 0

  const membresiaActual = computed(
    () => membresias.value?.find((m) => m.slug === slug.value) ?? null,
  )
  const modoLectura = computed(() =>
    Boolean(membresiaActual.value?.read_only || portal.value?.read_only),
  )
  const debeCambiarContrasena = computed(() => Boolean(membresiaActual.value?.must_change_password))
  const esAdmin = computed(() => membresiaActual.value?.role === "admin")

  async function cargarPortal(nuevoSlug: string) {
    if (slug.value === nuevoSlug && portal.value !== undefined) return
    slug.value = nuevoSlug
    portal.value = undefined
    portal.value = await portalBranding(nuevoSlug)
  }

  async function cargarSesion(forzar = false) {
    if (sesion.value !== null && !forzar) return
    const revision = ++revisionSesion
    const activa = await haySesion()
    if (revision !== revisionSesion) return
    const actuales = activa ? await misMembresias() : []
    // Una consulta de la persona anterior nunca puede reponer sus roles.
    if (revision !== revisionSesion) return
    sesion.value = activa
    membresias.value = actuales
  }

  async function entrar(usuarioOCorreo: string, contrasena: string) {
    if (!portal.value) throw new Error("Sin portal")
    await apiEntrar(portal.value.organization_id, usuarioOCorreo, contrasena)
    try {
      localStorage.setItem(
        CLAVE_ULTIMO_USUARIO(portal.value.slug),
        usuarioOCorreo.trim().toLowerCase(),
      )
    } catch {
      /* almacenamiento no disponible */
    }
    await cargarSesion(true)
  }

  async function cerrarSesion() {
    revisionSesion++
    await apiCerrarSesion()
    sesion.value = false
    membresias.value = []
  }

  function ultimoUsuario(): string {
    try {
      return slug.value ? (localStorage.getItem(CLAVE_ULTIMO_USUARIO(slug.value)) ?? "") : ""
    } catch {
      return ""
    }
  }

  return {
    slug,
    portal,
    membresias,
    sesion,
    membresiaActual,
    modoLectura,
    debeCambiarContrasena,
    esAdmin,
    cargarPortal,
    cargarSesion,
    entrar,
    cerrarSesion,
    ultimoUsuario,
  }
})
