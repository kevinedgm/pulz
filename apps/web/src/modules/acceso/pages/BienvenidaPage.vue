<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRouter } from "vue-router"
import { BloqueEstado, Boton, CampoContrasena } from "../../../shared/ui"
import { ErrorAcceso, MENSAJE_ENLACE } from "../../../shared/supabase/errores"
import { entrar, fijarContrasena } from "../api"
import PantallaAcceso from "../components/PantallaAcceso.vue"
import { useAcceso } from "../store"

// Bienvenida por enlace (§7.6): pulz.mx/e/<slug>/bienvenida#<token>. Sin
// sesión. El token vive en el fragmento (#), nunca llega al servidor del
// portal; set-password lo canjea (72 h, un solo uso). No se muestra nombre
// ni usuario: el token no se puede consultar sin canjearlo. Enlace
// inválido/usado/vencido → un solo mensaje.
const MIN = 8
const acceso = useAcceso()
const router = useRouter()
const token = ref("")
const nueva = ref("")
const repetida = ref("")
const tocado = ref({ nueva: false, repetida: false })
const ocupado = ref(false)
const enlaceInvalido = ref(false)
const errorRed = ref(false)
const listo = ref(false)

onMounted(() => {
  token.value = location.hash.replace(/^#/, "").trim()
  enlaceInvalido.value = token.value.length === 0
})

const errorNueva = computed(() =>
  tocado.value.nueva && nueva.value.length < MIN ? `Mínimo ${MIN} caracteres.` : undefined,
)
const errorRepetida = computed(() =>
  tocado.value.repetida && repetida.value !== nueva.value
    ? "No coinciden. Escríbela igual dos veces."
    : undefined,
)
const valido = computed(() => nueva.value.length >= MIN && repetida.value === nueva.value)

async function crear() {
  tocado.value = { nueva: true, repetida: true }
  if (!valido.value || ocupado.value) return
  ocupado.value = true
  errorRed.value = false
  try {
    const { loginEmail } = await fijarContrasena(nueva.value, token.value)
    history.replaceState(null, "", location.pathname) // el token ya se usó: fuera de la URL
    // DUDAS #11 (decisión del dueño): entra de inmediato con la contraseña
    // recién elegida. Si Auth no responde, queda la salida manual ("Listo").
    if (loginEmail && acceso.portal) {
      try {
        await entrar(acceso.portal.organization_id, loginEmail, nueva.value)
        await acceso.cargarSesion(true)
        const m = acceso.membresiaActual
        if (m && m.status === "activo") {
          await router.replace({
            name: m.must_change_password ? "cambiar-contrasena" : "inicio",
            params: { slug: acceso.slug! },
          })
          return
        }
      } catch {
        /* sin sesión automática: la persona entra a mano */
      }
    }
    listo.value = true
  } catch (e) {
    if (e instanceof ErrorAcceso && e.codigo === "RED") errorRed.value = true
    else enlaceInvalido.value = true
  } finally {
    ocupado.value = false
  }
}
</script>

<template>
  <PantallaAcceso :portal="acceso.portal ?? undefined">
    <template #default="{ enLinea }">
      <BloqueEstado
        v-if="enlaceInvalido"
        variante="error"
        :titulo="MENSAJE_ENLACE"
        texto="Pídele a tu encargado que te mande uno nuevo."
      >
        <Boton intent="secondary" :to="`/e/${acceso.slug}`">Ir al inicio de sesión</Boton>
      </BloqueEstado>
      <template v-else-if="listo">
        <h2 class="titulo">Listo, ya tienes contraseña</h2>
        <p class="texto">Entra con tu usuario y la contraseña que acabas de elegir.</p>
      </template>
      <template v-else>
        <h2 class="titulo">Te dieron acceso a {{ acceso.portal?.name ?? "la empresa" }}</h2>
        <p class="texto">Elige tu contraseña. Con ella vas a entrar de ahora en adelante.</p>
        <form id="form-bienvenida" class="form" novalidate @submit.prevent="crear">
          <CampoContrasena
            v-model="nueva"
            etiqueta="Tu contraseña"
            autocomplete="new-password"
            :ayuda="`Mínimo ${MIN} caracteres.`"
            :error="errorNueva"
            :disabled="ocupado"
            @blur="tocado.nueva = true"
          />
          <CampoContrasena
            v-model="repetida"
            etiqueta="Repítela"
            autocomplete="new-password"
            :error="errorRepetida"
            :disabled="ocupado"
            @blur="tocado.repetida = true"
          />
          <BloqueEstado
            v-if="errorRed"
            variante="error"
            titulo="No pudimos conectar"
            texto="Revisa tu señal. Lo que escribiste se conserva."
          >
            <Boton intent="secondary" :disabled="!enLinea" @click="crear">Reintentar</Boton>
          </BloqueEstado>
        </form>
      </template>
    </template>
    <template v-if="!enlaceInvalido" #primaria="{ enLinea }">
      <Boton
        v-if="listo"
        intent="primary"
        adapt="page-primary"
        @click="router.replace({ name: 'portal', params: { slug: acceso.slug! } })"
      >
        Ir a entrar
      </Boton>
      <Boton
        v-else
        intent="primary"
        adapt="page-primary"
        type="submit"
        form="form-bienvenida"
        :loading="ocupado"
        :disabled="!enLinea"
        :motivo-deshabilitado="!enLinea ? 'Para crear tu contraseña necesitas señal.' : undefined"
      >
        Crear contraseña y entrar
      </Boton>
    </template>
  </PantallaAcceso>
</template>

<style scoped>
.titulo {
  margin: 0;
  font: 600 1.25rem/1.3 var(--font);
}
.texto {
  margin: 0;
  color: var(--muted);
}
.form {
  display: grid;
  gap: var(--sp-4);
}
</style>
