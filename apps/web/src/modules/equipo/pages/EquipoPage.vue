<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import {
  Aviso,
  BloqueEstado,
  Boton,
  CampoContrasena,
  CampoTexto,
  CapaTarea,
  ChipEstado,
  Icono,
  ListaApilada,
  MenuFila,
  SegmentoOpciones,
  type AccionFila,
} from "../../../shared/ui"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import { useConexion } from "../../../shared/utils/conexion"
import type { Rol } from "../../acceso/api"
import { useAcceso } from "../../acceso/store"
import {
  cambiarEstado,
  cambiarRol,
  darDeAlta,
  desbloquear,
  enlaceVigente,
  equipoMiembros,
  esTitular,
  estaBloqueado,
  reenviarEnlace,
  type MiembroEquipo,
} from "../api"

// Equipo (§7.6, §11.1; ronda acceso/r01, congelada). Solo admin. Una
// primaria: Agregar persona. Alta en capa de tarea con dos entregas del
// acceso (enlace por WhatsApp / contraseña dictada). Nada se borra (§0.3).
const USERNAME_RE = /^[a-z0-9]([a-z0-9._-]{1,28}[a-z0-9])$/
const MIN = 8
const acceso = useAcceso()
const { enLinea } = useConexion()

const miembros = ref<MiembroEquipo[] | null>(null)
const errorCarga = ref<string | null>(null)
const busqueda = ref("")
const aviso = ref<string | null>(null)

// Capa activa: alta · creado · rol · suspender
type Capa =
  | null
  | { tipo: "alta" }
  | {
      tipo: "creado"
      modo: "enlace" | "dictada"
      nombre: string
      usuario: string
      enlace: string | null
    }
  | { tipo: "rol"; m: MiembroEquipo }
  | { tipo: "suspender"; m: MiembroEquipo }
const capa = ref<Capa>(null)
const ocupado = ref(false)
const errorCapa = ref<string | null>(null)
const copiado = ref(false)

const alta = ref({
  nombre: "",
  usuario: "",
  rol: "operador" as Rol,
  modo: "enlace" as "enlace" | "dictada",
  contrasena: "",
})
const tocado = ref({ nombre: false, usuario: false, contrasena: false })
const rolNuevo = ref<Rol>("operador")

const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const soloLectura = computed(() => acceso.modoLectura)
const puedeEscribir = computed(() => enLinea.value && !soloLectura.value)
const visibles = computed(() => {
  const q = busqueda.value.trim().toLowerCase()
  const lista = miembros.value ?? []
  return q
    ? lista.filter((m) => m.full_name.toLowerCase().includes(q) || (m.username ?? "").includes(q))
    : lista
})
const soloYo = computed(() => (miembros.value?.length ?? 0) <= 1)

const OPCIONES_ROL = [
  { valor: "admin" as Rol, etiqueta: "Admin", ayuda: "Admin: todo." },
  { valor: "productor" as Rol, etiqueta: "Productor", ayuda: "Productor: además todo el proceso." },
  {
    valor: "operador" as Rol,
    etiqueta: "Operador",
    ayuda: "Operador: mediciones, corridas y cortes.",
  },
]
const OPCIONES_ENTREGA = [
  {
    valor: "enlace" as const,
    etiqueta: "Enlace por WhatsApp",
    ayuda: "Dura 72 h y sirve una vez; la persona elige su contraseña.",
  },
  {
    valor: "dictada" as const,
    etiqueta: "Contraseña dictada",
    ayuda: "Se la dices en persona y la cambia al entrar.",
  },
]

const errorNombre = computed(() =>
  tocado.value.nombre && !alta.value.nombre.trim() ? "Falta el nombre de la persona." : undefined,
)
const errorUsuario = computed(() =>
  tocado.value.usuario && !USERNAME_RE.test(alta.value.usuario)
    ? "Minúsculas, números, punto o guion (3 a 30)."
    : undefined,
)
const errorContrasena = computed(() =>
  alta.value.modo === "dictada" && tocado.value.contrasena && alta.value.contrasena.length < MIN
    ? `Mínimo ${MIN} caracteres.`
    : undefined,
)
const altaValida = computed(
  () =>
    alta.value.nombre.trim().length > 0 &&
    USERNAME_RE.test(alta.value.usuario) &&
    (alta.value.modo === "enlace" || alta.value.contrasena.length >= MIN),
)

async function cargar() {
  errorCarga.value = null
  try {
    miembros.value = await equipoMiembros(org.value)
  } catch (e) {
    errorCarga.value = (e as Error).message
  }
}
onMounted(() => {
  if (acceso.esAdmin) cargar()
})

function abrirAlta() {
  alta.value = { nombre: "", usuario: "", rol: "operador", modo: "enlace", contrasena: "" }
  tocado.value = { nombre: false, usuario: false, contrasena: false }
  errorCapa.value = null
  capa.value = { tipo: "alta" }
}
function cerrarCapa() {
  if (
    capa.value?.tipo === "alta" &&
    (alta.value.nombre || alta.value.usuario) &&
    !confirm("¿Descartar lo que escribiste?")
  )
    return
  capa.value = null
  errorCapa.value = null
  copiado.value = false
}

async function crearAcceso() {
  tocado.value = { nombre: true, usuario: true, contrasena: true }
  if (!altaValida.value || ocupado.value) return
  ocupado.value = true
  errorCapa.value = null
  try {
    const a = alta.value
    const creado = await darDeAlta(
      org.value,
      a.modo === "enlace"
        ? { modo: "enlace", username: a.usuario, nombre: a.nombre.trim(), rol: a.rol }
        : {
            modo: "dictada",
            username: a.usuario,
            nombre: a.nombre.trim(),
            rol: a.rol,
            contrasena: a.contrasena,
          },
    )
    capa.value = {
      tipo: "creado",
      modo: a.modo,
      nombre: a.nombre.trim(),
      usuario: creado.username,
      enlace: creado.enlace,
    }
    await cargar()
  } catch (e) {
    errorCapa.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}

async function copiarEnlace(enlace: string) {
  try {
    await navigator.clipboard.writeText(enlace)
    copiado.value = true
    setTimeout(() => (copiado.value = false), 4000)
  } catch {
    aviso.value = "No se pudo copiar. Selecciona el enlace y cópialo a mano."
  }
}
const puedeCompartir = typeof navigator !== "undefined" && typeof navigator.share === "function"
async function compartirEnlace(enlace: string) {
  try {
    await navigator.share({
      title: "Tu acceso a PULZ",
      text: `Entra aquí y elige tu contraseña: ${enlace}`,
    })
  } catch {
    /* la persona canceló */
  }
}

function accionesDe(m: MiembroEquipo): AccionFila[] {
  const acciones: AccionFila[] = [{ id: "rol", etiqueta: "Cambiar rol…" }]
  if (m.status === "invitado" || (m.status === "activo" && m.must_change_password))
    acciones.push({ id: "reenviar", etiqueta: "Mandar enlace nuevo" })
  if (estaBloqueado(m)) acciones.push({ id: "desbloquear", etiqueta: "Desbloquear" })
  if (m.status === "suspendido") acciones.push({ id: "reactivar", etiqueta: "Reactivar" })
  else if (!esTitular(m))
    acciones.push({ id: "suspender", etiqueta: "Suspender…", intent: "danger" })
  return acciones
}

async function accion(id: string, m: MiembroEquipo) {
  aviso.value = null
  errorCapa.value = null
  try {
    if (id === "rol") {
      rolNuevo.value = m.role
      capa.value = { tipo: "rol", m }
    } else if (id === "suspender") {
      capa.value = { tipo: "suspender", m }
    } else if (id === "reactivar") {
      await cambiarEstado(org.value, m.user_id, "activo")
      aviso.value = `${m.full_name} ya puede entrar otra vez.`
      await cargar()
    } else if (id === "desbloquear") {
      await desbloquear(org.value, m.user_id)
      aviso.value = `${m.full_name} ya puede intentar entrar.`
      await cargar()
    } else if (id === "reenviar") {
      const r = await reenviarEnlace(org.value, m.user_id)
      capa.value = {
        tipo: "creado",
        modo: "enlace",
        nombre: m.full_name,
        usuario: m.username ?? "",
        enlace: r.enlace,
      }
      await cargar()
    }
  } catch (e) {
    aviso.value = (e as Error).message
  }
}

async function guardarRol() {
  if (capa.value?.tipo !== "rol" || ocupado.value) return
  ocupado.value = true
  try {
    await cambiarRol(org.value, capa.value.m.user_id, rolNuevo.value)
    aviso.value = `${capa.value.m.full_name} ahora es ${rolNuevo.value}.`
    capa.value = null
    await cargar()
  } catch (e) {
    errorCapa.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}

async function suspender() {
  if (capa.value?.tipo !== "suspender" || ocupado.value) return
  ocupado.value = true
  try {
    await cambiarEstado(org.value, capa.value.m.user_id, "suspendido")
    aviso.value = `${capa.value.m.full_name} ya no puede entrar. Puedes reactivar cuando quieras.`
    capa.value = null
    await cargar()
  } catch (e) {
    errorCapa.value = (e as ErrorAcceso).message
  } finally {
    ocupado.value = false
  }
}

const variante = (m: MiembroEquipo) =>
  m.status === "activo" ? "on" : m.status === "invitado" ? "draft" : "off"
const diasParaVencer = (m: MiembroEquipo) =>
  Math.max(0, Math.ceil((new Date(m.invitation_expires_at!).getTime() - Date.now()) / 86400000))
</script>

<template>
  <div class="equipo">
    <Aviso v-if="!enLinea" variante="offline" titulo="Sin conexión."
      >Ves la última lista cargada; para hacer cambios necesitas señal.</Aviso
    >
    <Aviso v-else-if="soloLectura" variante="readonly" titulo="Solo lectura."
      >La suscripción venció: puedes ver el equipo, no cambiarlo.</Aviso
    >

    <main class="equipo__cuerpo">
      <nav class="equipo__ruta" aria-label="Ruta">
        <router-link :to="`/e/${acceso.slug}/inicio`">Inicio</router-link> / <strong>Equipo</strong>
      </nav>

      <BloqueEstado
        v-if="!acceso.esAdmin"
        variante="denied"
        titulo="Solo el administrador puede ver el equipo"
        :texto="`Pídele a quien administra ${acceso.membresiaActual?.name ?? 'la empresa'} que te dé de alta o cambie tu rol.`"
      />

      <template v-else>
        <h1 class="equipo__titulo">Equipo</h1>
        <p class="equipo__texto">
          Quién puede entrar a {{ acceso.membresiaActual?.name }} y qué puede hacer.
        </p>

        <div class="equipo__acciones">
          <Boton
            v-if="miembros && !soloYo"
            intent="primary"
            adapt="page-primary"
            :disabled="!puedeEscribir"
            :motivo-deshabilitado="
              !enLinea
                ? 'Para agregar necesitas señal.'
                : soloLectura
                  ? 'Con la suscripción vencida no se agregan personas.'
                  : undefined
            "
            @click="abrirAlta"
          >
            <Icono nombre="i-mas" :size="20" /> Agregar persona
          </Boton>
          <CampoTexto
            v-if="(miembros?.length ?? 0) > 4"
            v-model="busqueda"
            etiqueta="Buscar por nombre o usuario"
            type="search"
            inputmode="search"
          />
        </div>

        <p v-if="aviso" class="equipo__aviso" role="status">{{ aviso }}</p>

        <div v-if="miembros === null && !errorCarga" class="equipo__esqueleto" aria-busy="true">
          <span v-for="i in 4" :key="i" class="equipo__linea"></span>
        </div>

        <BloqueEstado
          v-else-if="errorCarga"
          variante="error"
          titulo="No pudimos cargar al equipo"
          :texto="errorCarga"
        >
          <Boton intent="secondary" @click="cargar">Reintentar</Boton>
        </BloqueEstado>

        <BloqueEstado
          v-else-if="soloYo"
          variante="empty"
          titulo="Solo estás tú"
          texto="Agrega a quien produce y a quien mide. Puedes dictarle una contraseña o mandarle un enlace por WhatsApp."
        >
          <Boton intent="primary" :disabled="!puedeEscribir" @click="abrirAlta"
            ><Icono nombre="i-mas" :size="20" /> Agregar persona</Boton
          >
        </BloqueEstado>

        <ListaApilada
          v-else
          :resumen="`Personas de ${acceso.membresiaActual?.name}: nombre, usuario, rol, estado y acciones`"
        >
          <template #cabecera>
            <tr>
              <th scope="col">Nombre</th>
              <th scope="col">Usuario</th>
              <th scope="col">Rol</th>
              <th scope="col">Estado</th>
              <th scope="col"><span class="sr">Acciones</span></th>
            </tr>
          </template>
          <tr v-for="m in visibles" :key="m.user_id">
            <td data-label="Nombre">
              <strong>{{ m.full_name }}</strong>
              <span v-if="esTitular(m)" class="equipo__nota">titular · entra con su correo</span>
              <span v-else-if="m.must_change_password" class="equipo__nota"
                >debe cambiar la contraseña dictada</span
              >
            </td>
            <td data-label="Usuario">
              <code v-if="m.username">{{ m.username }}</code
              ><span v-else class="equipo__nota">—</span>
            </td>
            <td data-label="Rol">{{ m.role }}</td>
            <td data-label="Estado">
              <ChipEstado :variante="variante(m)">{{ m.status }}</ChipEstado>
              <span v-if="m.status === 'invitado' && enlaceVigente(m)" class="equipo__nota"
                >enlace vigente · vence en {{ diasParaVencer(m) }} días</span
              >
              <span v-else-if="m.status === 'invitado'" class="equipo__nota"
                >enlace vencido o usado</span
              >
              <span v-if="estaBloqueado(m)" class="equipo__nota">bloqueado por intentos</span>
            </td>
            <!-- sin data-label: el botón ya se llama "Acciones"; no se repite -->
            <td>
              <MenuFila
                v-if="puedeEscribir"
                :nombre="m.full_name"
                :acciones="accionesDe(m)"
                @seleccionar="accion($event, m)"
              />
            </td>
          </tr>
        </ListaApilada>
      </template>
    </main>

    <!-- Alta -->
    <CapaTarea
      :abierta="capa?.tipo === 'alta'"
      titulo="Agregar persona"
      etiqueta-cerrar="Cancelar"
      @cerrar="cerrarCapa"
    >
      <form id="form-alta" class="form" novalidate @submit.prevent="crearAcceso">
        <CampoTexto
          v-model="alta.nombre"
          etiqueta="Nombre"
          autocomplete="off"
          autocapitalize="words"
          :error="errorNombre"
          @blur="tocado.nombre = true"
        />
        <CampoTexto
          v-model="alta.usuario"
          etiqueta="Usuario para entrar"
          autocapitalize="none"
          autocomplete="off"
          ayuda="Minúsculas, números, punto o guion (3 a 30). Solo se usa para entrar; no es un correo."
          :error="errorUsuario"
          @blur="tocado.usuario = true"
        />
        <SegmentoOpciones v-model="alta.rol" etiqueta="Rol" :opciones="OPCIONES_ROL" />
        <SegmentoOpciones
          v-model="alta.modo"
          etiqueta="¿Cómo le entregas el acceso?"
          :opciones="OPCIONES_ENTREGA"
        />
        <CampoContrasena
          v-if="alta.modo === 'dictada'"
          v-model="alta.contrasena"
          etiqueta="Contraseña temporal"
          autocomplete="new-password"
          :ayuda="`Mínimo ${MIN} caracteres. La persona la cambia al entrar.`"
          :error="errorContrasena"
          @blur="tocado.contrasena = true"
        />
        <p v-if="errorCapa" class="rechazo" role="alert">{{ errorCapa }}</p>
      </form>
      <template #acciones>
        <Boton
          intent="primary"
          type="submit"
          form="form-alta"
          :loading="ocupado"
          :disabled="!enLinea"
          >Crear acceso</Boton
        >
        <Boton intent="secondary" @click="cerrarCapa">Cancelar</Boton>
      </template>
    </CapaTarea>

    <!-- Acceso creado -->
    <CapaTarea
      :abierta="capa?.tipo === 'creado'"
      :titulo="capa?.tipo === 'creado' ? `Listo: acceso para ${capa.nombre}` : ''"
      @cerrar="cerrarCapa"
    >
      <template v-if="capa?.tipo === 'creado' && capa.modo === 'enlace' && capa.enlace">
        <p class="texto">Mándale este enlace por WhatsApp. Sirve una vez y vence en 72 horas.</p>
        <p class="enlace" tabindex="0">{{ capa.enlace }}</p>
        <div class="fila">
          <Boton intent="primary" @click="copiarEnlace(capa.enlace)">Copiar enlace</Boton>
          <Boton v-if="puedeCompartir" intent="secondary" @click="compartirEnlace(capa.enlace)"
            >Compartir…</Boton
          >
        </div>
        <p v-if="copiado" class="texto" role="status">Copiado ✓</p>
        <p class="texto">
          Si se pierde, en la fila de {{ capa.nombre }} puedes mandar un enlace nuevo.
        </p>
      </template>
      <template v-else-if="capa?.tipo === 'creado'">
        <p class="texto">
          Dile su usuario <code>{{ capa.usuario }}</code> y la contraseña que escribiste. La primera
          vez que entre tendrá que cambiarla.
        </p>
      </template>
      <template #acciones>
        <Boton intent="secondary" @click="cerrarCapa">Cerrar</Boton>
      </template>
    </CapaTarea>

    <!-- Cambiar rol -->
    <CapaTarea
      :abierta="capa?.tipo === 'rol'"
      :titulo="capa?.tipo === 'rol' ? `Rol de ${capa.m.full_name}` : ''"
      etiqueta-cerrar="Cancelar"
      @cerrar="cerrarCapa"
    >
      <SegmentoOpciones v-model="rolNuevo" etiqueta="Rol" :opciones="OPCIONES_ROL" />
      <p v-if="errorCapa" class="rechazo" role="alert">{{ errorCapa }}</p>
      <template #acciones>
        <Boton intent="primary" :loading="ocupado" :disabled="!enLinea" @click="guardarRol"
          >Guardar rol</Boton
        >
        <Boton intent="secondary" @click="cerrarCapa">Cancelar</Boton>
      </template>
    </CapaTarea>

    <!-- Suspender (confirmación corta con consecuencia) -->
    <CapaTarea
      :abierta="capa?.tipo === 'suspender'"
      :titulo="capa?.tipo === 'suspender' ? `¿Suspender a ${capa.m.full_name}?` : ''"
      etiqueta-cerrar="Cancelar"
      @cerrar="cerrarCapa"
    >
      <p class="texto">Ya no podrá entrar. Puedes reactivar cuando quieras; nada se borra.</p>
      <p v-if="errorCapa" class="rechazo" role="alert">{{ errorCapa }}</p>
      <template #acciones>
        <Boton intent="danger" :loading="ocupado" :disabled="!enLinea" @click="suspender"
          >Suspender</Boton
        >
        <Boton intent="secondary" @click="cerrarCapa">Cancelar</Boton>
      </template>
    </CapaTarea>
  </div>
</template>

<style scoped>
.equipo {
  min-height: 100vh;
  background: var(--canvas);
  color: var(--text);
}
.equipo__cuerpo {
  max-width: 960px;
  margin: 0 auto;
  padding: var(--sp-5) var(--sp-4) calc(var(--sp-10) + var(--tap));
  display: grid;
  gap: var(--sp-4);
}
.equipo__ruta {
  font-size: 0.875rem;
  color: var(--muted);
}
.equipo__ruta a {
  color: var(--ink-900);
}
.equipo__titulo {
  margin: 0;
  font: 700 1.75rem/1.2 var(--font);
}
.equipo__texto {
  margin: 0;
  color: var(--muted);
}
.equipo__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-3);
  align-items: flex-start;
}
.equipo__acciones > :last-child:not(:first-child) {
  flex: 1 1 260px;
  max-width: 360px;
}
.equipo__aviso {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border-left: 4px solid var(--ok);
  background: var(--ok-bg);
  border-radius: var(--r-sm);
}
.equipo__nota {
  display: block;
  font-size: 0.8125rem;
  color: var(--muted);
}
.equipo__esqueleto {
  display: grid;
  gap: var(--sp-3);
}
.equipo__linea {
  display: block;
  height: 48px;
  border-radius: var(--r-md);
  background: var(--ink-100);
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
.texto {
  margin: 0 0 var(--sp-3);
  color: var(--muted);
  line-height: 1.45;
}
.enlace {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-3);
  border: 1px dashed var(--border);
  border-radius: var(--r-md);
  background: var(--canvas);
  font:
    0.8125rem/1.4 ui-monospace,
    Menlo,
    Consolas,
    monospace;
  word-break: break-all;
  user-select: all;
}
.fila {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
  margin-bottom: var(--sp-3);
}
.sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
}
code {
  font-size: 0.9375rem;
  background: var(--ink-100);
  border-radius: var(--r-sm);
  padding: 0 var(--sp-1);
}
@media (max-width: 599px) {
  .equipo__acciones > .boton {
    position: fixed;
    left: var(--sp-4);
    right: var(--sp-4);
    bottom: calc(var(--sp-3) + env(safe-area-inset-bottom));
    z-index: 5;
    box-shadow: var(--shadow);
  }
}
</style>
