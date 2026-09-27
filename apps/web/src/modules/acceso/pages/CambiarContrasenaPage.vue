<script setup lang="ts">
import { computed, ref } from "vue"
import { useRouter } from "vue-router"
import { BloqueEstado, Boton, CampoContrasena } from "../../../shared/ui"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import { fijarContrasena } from "../api"
import PantallaAcceso from "../components/PantallaAcceso.vue"
import { useAcceso } from "../store"

// Cambio obligatorio (§7.6): la persona entró con una contraseña dictada.
// Sin Cancelar ni Volver; solo Guardar contraseña y Cerrar sesión. La
// bandera must_change_password la baja el servidor (set-password).
const MIN = 8
const acceso = useAcceso()
const router = useRouter()
const nueva = ref("")
const repetida = ref("")
const tocado = ref({ nueva: false, repetida: false })
const ocupado = ref(false)
const errorRed = ref(false)
const errorServidor = ref<string | null>(null)

const errorNueva = computed(() =>
  tocado.value.nueva && nueva.value.length < MIN ? `Mínimo ${MIN} caracteres.` : undefined,
)
const errorRepetida = computed(() =>
  tocado.value.repetida && repetida.value !== nueva.value
    ? "No coinciden. Escríbela igual dos veces."
    : undefined,
)
const valido = computed(() => nueva.value.length >= MIN && repetida.value === nueva.value)

async function guardar() {
  tocado.value = { nueva: true, repetida: true }
  if (!valido.value || ocupado.value) return
  ocupado.value = true
  errorRed.value = false
  errorServidor.value = null
  try {
    await fijarContrasena(nueva.value)
    await acceso.cargarSesion(true)
    await router.replace({ name: "inicio", params: { slug: acceso.slug! } })
  } catch (e) {
    if (e instanceof ErrorAcceso && e.codigo === "RED") errorRed.value = true
    else errorServidor.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}

async function salir() {
  await acceso.cerrarSesion()
  await router.replace({ name: "portal", params: { slug: acceso.slug! } })
}
</script>

<template>
  <PantallaAcceso :portal="acceso.portal ?? undefined">
    <template #default="{ enLinea }">
      <h2 class="titulo">Elige tu contraseña</h2>
      <p class="texto">
        Tu encargado te dio una contraseña temporal. Antes de seguir, pon una tuya.
      </p>
      <form id="form-cambio" class="form" novalidate @submit.prevent="guardar">
        <CampoContrasena
          v-model="nueva"
          etiqueta="Nueva contraseña"
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
        <p v-if="errorServidor" class="rechazo" role="alert">{{ errorServidor }}</p>
        <BloqueEstado
          v-if="errorRed"
          variante="error"
          titulo="No pudimos conectar"
          texto="Revisa tu señal. Lo que escribiste se conserva."
        >
          <Boton intent="secondary" :disabled="!enLinea" @click="guardar">Reintentar</Boton>
        </BloqueEstado>
      </form>
      <Boton intent="quiet" @click="salir">Cerrar sesión</Boton>
    </template>
    <template #primaria="{ enLinea }">
      <Boton
        intent="primary"
        adapt="page-primary"
        type="submit"
        form="form-cambio"
        :loading="ocupado"
        :disabled="!enLinea"
        :motivo-deshabilitado="!enLinea ? 'Para guardar necesitas señal.' : undefined"
      >
        Guardar contraseña
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
.rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
  color: var(--text);
  font-weight: 600;
}
</style>
