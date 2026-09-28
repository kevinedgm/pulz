<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { onBeforeRouteLeave, useRouter } from "vue-router"
import {
  BloqueEstado,
  BloqueMarca,
  Boton,
  CampoColor,
  CampoTexto,
  CapaTarea,
  SelectorArchivo,
} from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import {
  guardarMarca,
  marca as cargarMarca,
  quitarLogo,
  slugValido,
  subirLogo,
  urlLogoPublico,
  type Marca,
} from "../api"
import SoloAdmin from "../components/SoloAdmin.vue"

// Portal y marca (§7.1, §7.3; ronda configuracion/r01). Nombre, estado,
// mensaje ≤140, color (solo acento), logo (recorte cuadrado a 512 en el
// navegador → Storage branding/<org>/logo.<ext>), enlace del portal con
// confirmación; vista previa con el mismo brand-block que ve la gente.
const HEX_RE = /^#[0-9A-Fa-f]{6}$/
const MAX_MSG = 140
const acceso = useAcceso()
const router = useRouter()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")

const original = ref<Marca | null>(null)
const f = ref({ name: "", state: "", brand_color: "", welcome_message: "" })
const logoPath = ref<string | null>(null)
const errorCarga = ref<string | null>(null)
const errorGuardar = ref<string | null>(null)
const guardado = ref(false)
const ocupado = ref(false)
const tocado = ref({ name: false, color: false, msg: false })

const errores = computed(() => ({
  name: tocado.value.name && !f.value.name.trim() ? "Falta el nombre." : undefined,
  color:
    tocado.value.color && f.value.brand_color && !HEX_RE.test(f.value.brand_color)
      ? "Debe ser #RRGGBB."
      : undefined,
  msg: f.value.welcome_message.length > MAX_MSG ? `Máximo ${MAX_MSG} caracteres.` : undefined,
}))
const valido = computed(
  () => f.value.name.trim().length > 0 && !errores.value.color && !errores.value.msg,
)
const cambiado = computed(
  () =>
    original.value !== null &&
    (f.value.name.trim() !== original.value.name ||
      (f.value.state.trim() || null) !== original.value.state ||
      (f.value.brand_color || null) !== original.value.brand_color ||
      (f.value.welcome_message.trim() || null) !== original.value.welcome_message),
)
const vistaPrevia = computed(() => ({
  nombre: f.value.name.trim() || "Tu empresa",
  mensaje: f.value.welcome_message.trim() || null,
  logoUrl: urlLogoPublico(logoPath.value),
  acento: HEX_RE.test(f.value.brand_color) ? f.value.brand_color : null,
}))

async function cargar() {
  errorCarga.value = null
  try {
    const m = await cargarMarca(org.value)
    original.value = m
    f.value = {
      name: m.name,
      state: m.state ?? "",
      brand_color: m.brand_color ?? "",
      welcome_message: m.welcome_message ?? "",
    }
    logoPath.value = m.logo_path
  } catch (e) {
    errorCarga.value = (e as Error).message
  }
}
onMounted(() => {
  if (acceso.esAdmin) cargar()
})
async function guardar() {
  tocado.value = { name: true, color: true, msg: true }
  if (!valido.value || ocupado.value) return
  ocupado.value = true
  errorGuardar.value = null
  guardado.value = false
  try {
    await guardarMarca(org.value, {
      name: f.value.name.trim(),
      state: f.value.state.trim() || null,
      brand_color: f.value.brand_color || null,
      welcome_message: f.value.welcome_message.trim() || null,
    })
    guardado.value = true
    await cargar()
    await acceso.cargarSesion(true) // el shell muestra el nombre y el acento nuevos
  } catch (e) {
    errorGuardar.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
onBeforeRouteLeave(() =>
  cambiado.value && !confirm("Tienes cambios sin guardar. ¿Salir de todos modos?") ? false : true,
)

// ── Logo: recorte cuadrado a 512 con canvas ───────────────────────────────
const capa = ref<null | "logo" | "slug">(null)
const archivo = ref<File | null>(null)
const previaLocal = ref<string | null>(null)
const errorLogo = ref<string | null>(null)
const subiendo = ref(false)
function elegirLogo(file: File) {
  archivo.value = file
  errorLogo.value = null
  if (previaLocal.value) URL.revokeObjectURL(previaLocal.value)
  previaLocal.value = URL.createObjectURL(file)
  capa.value = "logo"
}
async function recortar(file: File): Promise<{ blob: Blob; ext: "png" | "jpg" | "webp" }> {
  const img = await new Promise<HTMLImageElement>((ok, ko) => {
    const i = new Image()
    i.onload = () => ok(i)
    i.onerror = () => ko(new Error("No se pudo leer la imagen."))
    i.src = previaLocal.value!
  })
  const lado = Math.min(img.naturalWidth, img.naturalHeight)
  const sx = (img.naturalWidth - lado) / 2
  const sy = (img.naturalHeight - lado) / 2
  const c = document.createElement("canvas")
  c.width = c.height = Math.min(512, lado)
  c.getContext("2d")!.drawImage(img, sx, sy, lado, lado, 0, 0, c.width, c.height)
  const tipo = file.type === "image/png" ? "image/png" : "image/webp"
  const blob = await new Promise<Blob | null>((ok) => c.toBlob(ok, tipo, 0.9))
  if (!blob) throw new Error("No se pudo recortar la imagen.")
  return { blob, ext: tipo === "image/png" ? "png" : "webp" }
}
async function usarLogo() {
  if (!archivo.value || subiendo.value) return
  subiendo.value = true
  errorLogo.value = null
  try {
    const { blob, ext } = await recortar(archivo.value)
    const path = await subirLogo(org.value, blob, ext)
    await guardarMarca(org.value, { logo_path: path })
    logoPath.value = null
    logoPath.value = path
    capa.value = null
    await acceso.cargarPortal(acceso.slug!)
  } catch (e) {
    errorLogo.value = (e as Error).message
  } finally {
    subiendo.value = false
  }
}
async function quitar() {
  if (!logoPath.value || subiendo.value) return
  subiendo.value = true
  errorLogo.value = null
  try {
    await quitarLogo(org.value, logoPath.value)
    logoPath.value = null
  } catch (e) {
    errorLogo.value = (e as Error).message
  } finally {
    subiendo.value = false
  }
}

// ── Enlace del portal (slug) ──────────────────────────────────────────────
const slugNuevo = ref("")
const errorSlug = ref<string | null>(null)
const slugTocado = ref(false)
const slugOk = computed(
  () => slugValido(slugNuevo.value) && slugNuevo.value !== original.value?.slug,
)
const errorSlugFormato = computed(() =>
  slugTocado.value && !slugValido(slugNuevo.value)
    ? "Minúsculas, números y guiones (3 a 40), sin guiones dobles."
    : undefined,
)
function abrirSlug() {
  slugNuevo.value = original.value?.slug ?? ""
  slugTocado.value = false
  errorSlug.value = null
  capa.value = "slug"
}
async function cambiarSlug() {
  slugTocado.value = true
  if (!slugOk.value || ocupado.value) return
  ocupado.value = true
  errorSlug.value = null
  try {
    await guardarMarca(org.value, { slug: slugNuevo.value })
    const nuevo = slugNuevo.value
    capa.value = null
    await acceso.cargarSesion(true)
    await router.replace(`/e/${nuevo}/configuracion/portal`)
    await cargar()
  } catch (e) {
    errorSlug.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
</script>

<template>
  <SoloAdmin v-slot="{ puedeEscribir }" seccion="Portal y marca">
    <div v-if="!original && !errorCarga" class="pm__esqueleto" aria-busy="true">
      <div v-for="n in 3" :key="n" class="pm__bloque"></div>
    </div>
    <BloqueEstado
      v-else-if="errorCarga"
      variante="error"
      titulo="No pudimos cargar la marca"
      :texto="errorCarga"
    >
      <Boton intent="secondary" @click="cargar">Reintentar</Boton>
    </BloqueEstado>
    <form v-else id="form-marca" class="pm__form" novalidate @submit.prevent="guardar">
      <fieldset class="pm__grupo">
        <legend>Cómo se ve tu portal</legend>
        <CampoTexto
          v-model="f.name"
          etiqueta="Nombre de la empresa"
          autocapitalize="words"
          :error="errores.name"
          @blur="tocado.name = true"
        />
        <CampoTexto
          v-model="f.state"
          etiqueta="Estado (dónde está el palenque)"
          autocapitalize="words"
          placeholder="Oaxaca"
        />
        <CampoTexto
          v-model="f.welcome_message"
          etiqueta="Mensaje de bienvenida"
          autocapitalize="sentences"
          :ayuda="`${f.welcome_message.length} / ${MAX_MSG}`"
          :error="errores.msg"
          @blur="tocado.msg = true"
        />
        <CampoColor
          v-model="f.brand_color"
          etiqueta="Color de la empresa"
          ayuda="Solo como acento (línea superior y monograma); nunca detrás de texto."
          :error="errores.color"
          @blur="tocado.color = true"
        />
        <SelectorArchivo
          etiqueta="Logo"
          :preview-url="urlLogoPublico(logoPath)"
          :ocupado="subiendo"
          :disabled="!puedeEscribir"
          :error="errorLogo ?? undefined"
          ayuda="PNG, JPG o WebP hasta 2 MB. Se recorta cuadrado y se guarda a 512 px."
          texto-subir="Subir logo…"
          @elegir="elegirLogo"
          @quitar="quitar"
          @rechazar="errorLogo = $event"
        />
      </fieldset>
      <fieldset class="pm__grupo">
        <legend>Enlace del portal</legend>
        <div class="pm__slug">
          <code>pulz.mx/e/{{ original?.slug }}</code>
          <Boton intent="secondary" :disabled="!puedeEscribir" @click="abrirSlug"
            >Cambiar enlace…</Boton
          >
        </div>
        <p class="pm__ayuda">
          Es el enlace que tu gente tiene guardado. Si lo cambias, el viejo sigue funcionando y
          nadie más podrá usarlo.
        </p>
      </fieldset>
      <fieldset class="pm__grupo">
        <legend>Vista previa</legend>
        <div class="pm__previa"><BloqueMarca :marca="vistaPrevia" nivel="p" /></div>
        <p class="pm__ayuda">Así lo ve la gente antes de entrar.</p>
      </fieldset>
      <p v-if="errorGuardar" class="pm__rechazo" role="alert">{{ errorGuardar }}</p>
      <p v-else-if="guardado" class="pm__ok" role="status">Cambios guardados.</p>
      <div>
        <Boton
          intent="primary"
          adapt="page-primary"
          type="submit"
          form="form-marca"
          :loading="ocupado"
          :disabled="!puedeEscribir || !cambiado"
          :motivo-deshabilitado="
            !puedeEscribir ? 'Para cambiar algo necesitas señal y suscripción vigente.' : undefined
          "
          >Guardar cambios</Boton
        >
      </div>
    </form>

    <!-- Recorte del logo -->
    <CapaTarea
      :abierta="capa === 'logo'"
      titulo="Recortar el logo"
      etiqueta-cerrar="Cancelar"
      @cerrar="capa = null"
    >
      <div class="pm__recorte">
        <img v-if="previaLocal" :src="previaLocal" alt="Vista previa del logo" />
      </div>
      <p class="pm__ayuda pm__centro">Se guarda cuadrado (centrado) a 512 px.</p>
      <p v-if="errorLogo" class="pm__rechazo" role="alert">{{ errorLogo }}</p>
      <template #acciones>
        <Boton intent="primary" :loading="subiendo" :disabled="!puedeEscribir" @click="usarLogo"
          >Usar este logo</Boton
        >
        <Boton intent="secondary" @click="capa = null">Cancelar</Boton>
      </template>
    </CapaTarea>

    <!-- Cambiar enlace -->
    <CapaTarea
      :abierta="capa === 'slug'"
      titulo="Cambiar el enlace del portal"
      etiqueta-cerrar="Cancelar"
      @cerrar="capa = null"
    >
      <form id="form-slug" class="pm__form" novalidate @submit.prevent="cambiarSlug">
        <CampoTexto
          v-model="slugNuevo"
          etiqueta="Nuevo enlace (pulz.mx/e/…)"
          autocapitalize="none"
          autocomplete="off"
          ayuda="Minúsculas, números y guiones (3 a 40)."
          :error="errorSlugFormato"
          @blur="slugTocado = true"
        />
        <p class="pm__nota">
          El enlace viejo <code>pulz.mx/e/{{ original?.slug }}</code> seguirá llevando a tu portal y
          nadie más podrá usarlo. Los accesos directos instalados siguen funcionando.
        </p>
        <p v-if="errorSlug" class="pm__rechazo" role="alert">{{ errorSlug }}</p>
      </form>
      <template #acciones>
        <Boton
          intent="primary"
          type="submit"
          form="form-slug"
          :loading="ocupado"
          :disabled="!puedeEscribir || !slugOk"
          >Cambiar enlace</Boton
        >
        <Boton intent="secondary" @click="capa = null">Cancelar</Boton>
      </template>
    </CapaTarea>
  </SoloAdmin>
</template>

<style scoped>
.pm__form {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-4);
  max-width: 640px;
}
.pm__grupo {
  display: grid;
  gap: var(--sp-4);
  margin: 0;
  padding: var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
  min-width: 0;
}
.pm__grupo legend {
  padding: 0 var(--sp-2);
  font: 700 1.0625rem/1.2 var(--font);
}
.pm__slug {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--sp-3);
}
.pm__slug code {
  font-size: 0.9375rem;
  overflow-wrap: anywhere;
}
.pm__ayuda {
  margin: 0;
  font-size: 0.8125rem;
  color: var(--muted);
}
.pm__centro {
  text-align: center;
}
.pm__previa {
  max-width: min(360px, 100%);
  padding: var(--sp-3) var(--sp-4) var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--canvas);
}
.pm__esqueleto {
  display: grid;
  gap: var(--sp-4);
  max-width: 640px;
}
.pm__bloque {
  height: 140px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.pm__recorte {
  width: min(320px, 100%);
  aspect-ratio: 1;
  margin: 0 auto;
  border: 2px dashed var(--muted);
  border-radius: var(--r-lg);
  overflow: hidden;
  display: grid;
  place-items: center;
  background: var(--canvas);
}
.pm__recorte img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.pm__nota {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
}
.pm__rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
  font-weight: 600;
}
.pm__ok {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
</style>
