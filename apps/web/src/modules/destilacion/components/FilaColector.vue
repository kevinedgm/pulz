<script setup lang="ts">
import { Boton, ChipEstado } from "../../../shared/ui"
import { cuandoCorto, litros, type ColectorConSaldo } from "../api"

// Colector con contenido (local): clase, lote vivo, litros, grado declarado
// y quién. «Pasar a granel» es transferir (ronda granel; admin/productor):
// el operador ve quién lo hace.
defineProps<{ colector: ColectorConSaldo; slug: string; puedeTransferir: boolean }>()
</script>

<template>
  <li class="col" :aria-label="colector.colector">
    <div class="col__nombre">
      <h3 class="col__titulo">{{ colector.colector }}</h3>
      <span class="col__sub"
        >clase {{ colector.liquid_class }} · {{ colector.folio
        }}<template v-if="colector.capacidad_l">
          · {{ litros(colector.capacidad_l) }} de capacidad</template
        ></span
      >
    </div>
    <div class="col__datos">
      <b>{{ litros(colector.litros) }}</b>
      <template v-if="colector.abv !== null">
        · {{ colector.abv }} % Alc. declarado<template v-if="colector.abv_by">
          ({{ colector.abv_by }}, {{ cuandoCorto(colector.abv_at) }})</template
        ></template
      >
    </div>
    <ChipEstado class="col__estado" variante="on">con saldo</ChipEstado>
    <div class="col__acciones">
      <Boton
        v-if="colector.liquid_class === 'mezcal' && puedeTransferir"
        intent="secondary"
        :to="`/e/${slug}/granel?transferir=${colector.resource_id}`"
        >Pasar a granel</Boton
      >
      <span v-else-if="colector.liquid_class === 'mezcal'" class="col__nota"
        >a granel lo pasa el productor</span
      >
      <span v-else class="col__nota">se redestila en 2ª</span>
    </div>
  </li>
</template>

<style scoped>
.col {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-areas:
    "nombre estado"
    "datos datos"
    "acciones acciones";
  gap: var(--sp-2) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  border: 1px solid var(--border);
  border-top: 0;
  background: var(--surface);
}
.col:first-child {
  border-top: 1px solid var(--border);
  border-radius: var(--r-lg) var(--r-lg) 0 0;
}
.col:last-child {
  border-radius: 0 0 var(--r-lg) var(--r-lg);
}
.col__nombre {
  grid-area: nombre;
  min-width: 0;
}
.col__titulo {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
}
.col__sub,
.col__datos,
.col__nota {
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.col__datos {
  grid-area: datos;
}
.col__datos b {
  color: var(--text);
}
.col__estado {
  grid-area: estado;
  justify-self: end;
}
.col__acciones {
  grid-area: acciones;
  display: flex;
  align-items: center;
  gap: var(--sp-2);
}
@media (min-width: 1024px) {
  .col {
    grid-template-columns: minmax(0, 1.2fr) minmax(0, 1.5fr) auto auto;
    grid-template-areas: "nombre datos estado acciones";
    min-height: 64px;
  }
  .col__estado {
    justify-self: start;
  }
  .col__acciones {
    justify-content: flex-end;
  }
}
</style>
