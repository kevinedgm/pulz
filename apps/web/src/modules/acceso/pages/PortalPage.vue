<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute, useRouter } from "vue-router"
import { BloqueEstado, Boton, CampoContrasena, CampoTexto } from "../../../shared/ui"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import { pedirRecuperacion } from "../api"
import PantallaAcceso from "../components/PantallaAcceso.vue"
import { useAcceso } from "../store"

// Portal + inicio de sesión (§7.5, ronda acceso/r01, congelada).
// Un campo "usuario o correo": con "@" es titular; sin "@" el navegador
// arma el correo sintético. TODO rechazo muestra el mismo texto.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()

const usuario = ref("")
const contrasena = ref("")
const ocupado = ref(false)
const error = ref<string | null>(null)
const errorRed = ref(false)
const ayudaAbierta = ref(false)
const recuperacion = ref<"" | "enviando" | "enviado" | "fallo">("")
const contrasenaRef = ref<InstanceType<typeof CampoContrasena> | null>(null)

const esCorreo = computed(() => usuario.value.includes("@"))
const listo = computed(() => usuario.value.trim().length > 0 && contrasena.value.length > 0)

onMounted(() => {
  usuario.value = acceso.ultimoUsuario()
})

async function entrar() {
  if (ocupado.value || !listo.value) return
  ocupado.value = true
  error.value = null
  errorRed.value = false
  try {
    await acceso.entrar(usuario.value, contrasena.value)
    const m = acceso.membresiaActual
    if (!m || m.status !== "activo") {
      // Entró a Auth pero no pertenece a ESTA empresa: el mismo 404 (§7.5)
      await acceso.cerrarSesion()
      await router.replace({ name: "no-encontrado", params: { slug: acceso.slug! } })
      return
    }
    await router.replace({
      name: m.must_change_password ? "cambiar-contrasena" : "inicio",
      params: { slug: m.slug },
    })
  } catch (e) {
    if (e instanceof ErrorAcceso && e.codigo === "RED") errorRed.value = true
    else error.value = (e as Error).message
    contrasena.value = ""
    contrasenaRef.value?.$el?.querySelector?.("input")?.focus()
  } finally {
    ocupado.value = false
  }
}

async function recuperar() {
  recuperacion.value = "enviando"
  try {
    await pedirRecuperacion(usuario.value.trim().toLowerCase(), String(route.params.slug))
    recuperacion.value = "enviado"
  } catch {
    recuperacion.value = "fallo"
  }
}
</script>

<template>
  <PantallaAcceso :portal="acceso.portal ?? undefined" :solo-lectura="acceso.portal?.read_only">
    <template #default="{ enLinea }">
      <form id="form-acceso" class="form" novalidate @submit.prevent="entrar">
        <CampoTexto
          v-model="usuario"
          etiqueta="Usuario o correo"
          size="lg"
          inputmode="email"
          autocomplete="username"
          autocapitalize="none"
          placeholder="ana.lopez"
          ayuda="Si tu encargado te dio un usuario, escríbelo tal cual. Si eres el titular, tu correo."
          :disabled="ocupado"
          name="usuario"
        />
        <CampoContrasena
          ref="contrasenaRef"
          v-model="contrasena"
          etiqueta="Contraseña"
          size="lg"
          autocomplete="current-password"
          :disabled="ocupado"
          name="contrasena"
        />
        <p v-if="error" class="rechazo" role="alert">{{ error }}</p>
        <BloqueEstado
          v-if="errorRed"
          variante="error"
          titulo="No pudimos conectar"
          texto="Revisa tu señal. Lo que escribiste se conserva."
        >
          <Boton intent="secondary" @click="entrar">Reintentar</Boton>
        </BloqueEstado>
        <div class="ayuda">
          <Boton
            intent="quiet"
            :aria-expanded="ayudaAbierta ? 'true' : 'false'"
            @click="ayudaAbierta = !ayudaAbierta"
            >¿No puedes entrar?</Boton
          >
          <div v-if="ayudaAbierta" class="ayuda__texto">
            <template v-if="esCorreo">
              <p>Te mandamos un correo para que pongas una contraseña nueva.</p>
              <Boton
                v-if="recuperacion !== 'enviado'"
                intent="secondary"
                :loading="recuperacion === 'enviando'"
                :disabled="!enLinea"
                @click="recuperar"
                >Mandar correo de recuperación</Boton
              >
              <p v-if="recuperacion === 'enviado'" role="status">Listo. Revisa tu correo.</p>
              <p v-if="recuperacion === 'fallo'" role="alert">
                No se pudo mandar. Intenta de nuevo.
              </p>
            </template>
            <p v-else>
              Pídele a tu encargado que te restablezca la contraseña o que te mande un enlace nuevo.
            </p>
          </div>
        </div>
      </form>
    </template>
    <template #primaria="{ enLinea }">
      <Boton
        intent="primary"
        adapt="page-primary"
        type="submit"
        form="form-acceso"
        :loading="ocupado"
        :disabled="!enLinea || !listo"
        :motivo-deshabilitado="!enLinea ? 'Para entrar necesitas señal.' : undefined"
      >
        Entrar
      </Boton>
    </template>
    <template #pie>¿Aún no tienes PULZ? <a href="https://pulz.mx">Conoce PULZ</a></template>
  </PantallaAcceso>
</template>

<style scoped>
.form {
  display: grid;
  gap: var(--sp-4);
}
.rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
  color: var(--text);
  font-weight: 600;
}
.ayuda {
  display: grid;
  gap: var(--sp-2);
  justify-items: start;
}
.ayuda__texto {
  display: grid;
  gap: var(--sp-2);
  font-size: 0.9375rem;
  color: var(--muted);
}
.ayuda__texto p {
  margin: 0;
}
a {
  color: var(--ink-900);
}
</style>
