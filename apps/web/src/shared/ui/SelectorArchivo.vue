<script setup lang="ts">
import { ref, useId } from "vue"
import Boton from "./Boton.vue"

// Contrato: registry "file-picker". Vista previa (96px) + "Subir…" (input
// file oculto) + "Quitar" (quiet). Valida tipo y tamaño en el navegador con
// los mismos límites del bucket antes de emitir; el recorte es del consumidor.
const props = withDefaults(
  defineProps<{
    etiqueta: string
    previewUrl?: string | null
    accept?: string[]
    maxBytes?: number
    ayuda?: string
    error?: string
    ocupado?: boolean
    disabled?: boolean
    textoSubir?: string
  }>(),
  {
    accept: () => ["image/png", "image/jpeg", "image/webp"],
    maxBytes: 2 * 1024 * 1024,
    ocupado: false,
    disabled: false,
    textoSubir: "Subir…",
  },
)
const emit = defineEmits<{ elegir: [File]; quitar: []; rechazar: [motivo: string] }>()
const id = useId()
const input = ref<HTMLInputElement | null>(null)

function onCambio(e: Event) {
  const f = (e.target as HTMLInputElement).files?.[0]
  ;(e.target as HTMLInputElement).value = ""
  if (!f) return
  if (!props.accept.includes(f.type)) return emit("rechazar", "Solo PNG, JPG o WebP.")
  if (f.size > props.maxBytes)
    return emit(
      "rechazar",
      `El archivo pesa más de ${Math.round(props.maxBytes / 1024 / 1024)} MB.`,
    )
  emit("elegir", f)
}
</script>

<template>
  <div class="arch" :class="{ 'arch--error': error }">
    <span :id="`${id}-e`" class="arch__etiqueta">{{ etiqueta }}</span>
    <div class="arch__fila">
      <div class="arch__previa" :aria-busy="ocupado ? 'true' : undefined">
        <img v-if="previewUrl" :src="previewUrl" alt="" width="96" height="96" />
        <span v-else class="arch__vacio" aria-hidden="true">sin archivo</span>
      </div>
      <div class="arch__acciones">
        <input
          :id="id"
          ref="input"
          class="arch__input"
          type="file"
          :accept="accept.join(',')"
          :disabled="disabled || ocupado"
          :aria-labelledby="`${id}-e`"
          @change="onCambio"
        />
        <Boton intent="secondary" :loading="ocupado" :disabled="disabled" @click="input?.click()">{{
          textoSubir
        }}</Boton>
        <Boton
          v-if="previewUrl"
          intent="quiet"
          :disabled="disabled || ocupado"
          @click="emit('quitar')"
          >Quitar</Boton
        >
        <p v-if="ayuda && !error" class="arch__ayuda">{{ ayuda }}</p>
        <p v-if="error" class="arch__error" role="alert">{{ error }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.arch {
  display: grid;
  gap: var(--sp-1);
}
.arch__etiqueta {
  font: 600 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.arch__fila {
  display: flex;
  gap: var(--sp-4);
  align-items: flex-start;
  flex-wrap: wrap;
}
.arch__previa {
  flex: none;
  width: 96px;
  height: 96px;
  display: grid;
  place-items: center;
  border: 1px solid var(--border);
  border-radius: var(--r-xl);
  background: var(--canvas);
  overflow: hidden;
}
.arch__previa img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.arch__vacio {
  font-size: 0.75rem;
  color: var(--muted);
}
.arch__acciones {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--sp-2);
  min-width: 0;
}
.arch__input {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
  pointer-events: none;
}
.arch__ayuda,
.arch__error {
  flex-basis: 100%;
  margin: 0;
  font-size: 0.8125rem;
  line-height: 1.35;
}
.arch__ayuda {
  color: var(--muted);
}
.arch__error {
  color: var(--late);
  font-weight: 600;
}
</style>
