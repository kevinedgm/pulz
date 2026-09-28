<script setup lang="ts">
import { Boton } from "../../../shared/ui"
import { cuandoCorto, HISTORIA, litros, type Tanque } from "../api"

// Tarjeta de tanque (local; ronda granel/r01): saldo, lotes con su % Alc.
// declarado vigente (quién y cuándo) y nivel de historia como texto;
// Entrada / Salida / Transferir (admin y productor; con señal).
defineProps<{ tanque: Tanque; slug: string; puedeMover: boolean; enLinea: boolean }>()
</script>

<template>
  <article class="tq" :aria-label="tanque.tanque">
    <h3 class="tq__titulo">
      <span>{{ tanque.tanque }}</span>
      <span class="tq__cap"
        ><template v-if="tanque.capacidad_l">{{ litros(tanque.capacidad_l) }} · </template
        >{{ tanque.capacity_policy }}</span
      >
    </h3>
    <template v-if="tanque.lotes.length">
      <p class="tq__saldo">{{ litros(tanque.litros) }}</p>
      <div v-for="l in tanque.lotes" :key="l.lot_id" class="tq__lote">
        <b>{{ l.folio }}</b>
        <span>{{ litros(l.litros) }}</span>
        <span v-if="l.abv !== null"
          ><b>{{ l.abv }} %</b> Alc. declarado</span
        >
        <span v-else class="tq__h">sin grado declarado</span>
        <span v-if="l.abv_by" class="tq__h">{{ l.abv_by }} · {{ cuandoCorto(l.abv_at) }}</span>
        <span class="tq__h">{{ HISTORIA[l.history] }}</span>
      </div>
    </template>
    <template v-else>
      <p class="tq__saldo tq__saldo--vacio">vacío</p>
      <p class="tq__sub">Sin lote. Entra por carga inicial, compra o transferencia.</p>
    </template>
    <Boton intent="quiet" :to="`/e/${slug}/granel/${tanque.resource_id}`">Ver historial</Boton>
    <div v-if="puedeMover" class="tq__acciones">
      <Boton
        intent="secondary"
        :to="`/e/${slug}/granel/${tanque.resource_id}/movimiento?direccion=entrada`"
        :disabled="!enLinea"
        :motivo-deshabilitado="!enLinea ? 'Necesitas señal.' : undefined"
        >Entrada</Boton
      >
      <Boton
        intent="secondary"
        :to="`/e/${slug}/granel/${tanque.resource_id}/movimiento?direccion=salida`"
        :disabled="!enLinea || tanque.lotes.length === 0"
        :motivo-deshabilitado="
          !enLinea
            ? 'Necesitas señal.'
            : tanque.lotes.length === 0
              ? 'El tanque está vacío.'
              : undefined
        "
        >Salida</Boton
      >
      <Boton
        intent="secondary"
        :to="`/e/${slug}/granel/transferir?${tanque.lotes.length ? `origen=${tanque.resource_id}` : `destino=${tanque.resource_id}`}`"
        :disabled="!enLinea"
        :motivo-deshabilitado="!enLinea ? 'Necesitas señal.' : undefined"
        >Transferir</Boton
      >
    </div>
    <p v-else class="tq__sub">Los movimientos los registra el productor.</p>
  </article>
</template>

<style scoped>
.tq {
  display: grid;
  gap: var(--sp-2);
  padding: var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
  min-width: 0;
  align-content: start;
}
.tq__titulo {
  margin: 0;
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: var(--sp-2);
  font: 700 1.0625rem/1.3 var(--font);
}
.tq__cap {
  font: 400 0.8125rem/1.3 var(--font);
  color: var(--muted);
  white-space: nowrap;
}
.tq__saldo {
  margin: 0;
  font: 700 1.625rem/1.2 var(--font);
  font-variant-numeric: tabular-nums;
}
.tq__saldo--vacio {
  color: var(--muted);
}
.tq__lote {
  display: flex;
  flex-wrap: wrap;
  gap: 2px var(--sp-3);
  padding: var(--sp-2) 0;
  border-top: 1px dashed var(--border);
  font-size: 0.9375rem;
}
.tq__h,
.tq__sub {
  font-size: 0.8125rem;
  color: var(--muted);
  margin: 0;
}
.tq__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
  margin-top: var(--sp-1);
}
@media (max-width: 599px) {
  .tq__acciones :deep(.boton) {
    flex: 1 1 30%;
  }
}
</style>
