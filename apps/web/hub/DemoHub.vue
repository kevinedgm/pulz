<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import sprite from "../src/shared/ui/iconos.svg?raw"
import {
  Aviso,
  BloqueEstado,
  BloqueMarca,
  Boton,
  BotonFlotante,
  CabeceraPagina,
  NavInferior,
  NavLateral,
  CampoColor,
  CampoContrasena,
  CampoNumero,
  CampoTexto,
  CapaTarea,
  ChipEstado,
  Icono,
  ListaApilada,
  MenuFila,
  SegmentoOpciones,
} from "../src/shared/ui"

// Demos F3 de las piezas registradas (design-hub/system/registry.json).
// ?pieza=<id> muestra una sola pieza; ?solo=1 sin cromo (para los marcos).
const PIEZAS = [
  { id: "button", nombre: "Botón" },
  { id: "text-field", nombre: "Campo de texto" },
  { id: "password-field", nombre: "Campo de contraseña" },
  { id: "segmented-choice", nombre: "Segmento de opciones" },
  { id: "status-chip", nombre: "Chip de estado" },
  { id: "banner", nombre: "Aviso" },
  { id: "state-block", nombre: "Bloque de estado" },
  { id: "task-layer", nombre: "Capa de tarea" },
  { id: "list-stack", nombre: "Lista apilada" },
  { id: "row-menu", nombre: "Menú de fila" },
  { id: "page-header", nombre: "Cabecera de página" },
  { id: "side-nav", nombre: "Menú lateral" },
  { id: "bottom-nav", nombre: "Navegación inferior" },
  { id: "fab", nombre: "Botón flotante" },
  { id: "select", nombre: "Select" },
  { id: "number-field", nombre: "Campo numérico" },
  { id: "switch", nombre: "Interruptor" },
  { id: "color-field", nombre: "Campo de color" },
  { id: "file-picker", nombre: "Selector de archivo" },
  { id: "brand-block", nombre: "Bloque de marca" },
] as const
type PiezaId = (typeof PIEZAS)[number]["id"]

const q = new URLSearchParams(location.search)
const solo = q.get("solo") === "1"
const pieza = ref<PiezaId | "todas">((q.get("pieza") as PiezaId) || "todas")
const modo = ref<"pagina" | "espacios">("pagina")
const oscuro = ref(false)
const ANCHOS = [1440, 768, 390] as const

const visibles = computed(() =>
  pieza.value === "todas" ? PIEZAS : PIEZAS.filter((p) => p.id === pieza.value),
)
const urlMarco = (id: string) =>
  `${location.pathname}?pieza=${id}&solo=1${oscuro.value ? "&oscuro=1" : ""}`
function aplicarTema() {
  document.documentElement.dataset.theme = oscuro.value ? "dark" : "light"
}
onMounted(() => {
  oscuro.value = q.get("oscuro") === "1"
  aplicarTema()
})

// Datos de ejemplo (Cuatro Vientos, la empresa de la semilla)
const usuario = ref("tomas.h")
const contrasena = ref("")
const rol = ref<"admin" | "productor" | "operador">("operador")
const entrega = ref<"enlace" | "dictada">("enlace")
const capa = ref(false)
const ultimaAccion = ref("")
// Shell (ronda shell/r01): los destinos de §13.1 como ItemNav de ejemplo
const destinos = [
  { id: "inicio", etiqueta: "Inicio", icono: "i-home" as const, to: "#inicio" },
  { id: "maguey", etiqueta: "Maguey", icono: "i-maguey" as const, to: "#maguey" },
  { id: "horneado", etiqueta: "Horneado", icono: "i-horno" as const, to: "#horneado" },
  { id: "fermentacion", etiqueta: "Fermentación", icono: "i-tina" as const, to: "#fermentacion" },
  { id: "destilacion", etiqueta: "Destilación", icono: "i-destila" as const, to: "#destilacion" },
  { id: "granel", etiqueta: "Granel", icono: "i-tanque" as const, to: "#granel" },
  { id: "trazabilidad", etiqueta: "Trazabilidad", icono: "i-traza" as const, to: "#trazabilidad" },
  {
    id: "configuracion",
    etiqueta: "Configuración",
    icono: "i-ajustes" as const,
    to: "#configuracion",
  },
]
const fijos = destinos.filter((d) =>
  ["inicio", "fermentacion", "destilacion", "granel"].includes(d.id),
)
const navActual = ref("fermentacion")
const cuentaAbierta = ref(false)
// Configuración (ronda configuracion/r01)
const catalogo = ref("tipo_tina")
const capacidad = ref<number | null>(1500)
const puntas = ref(false)
const color = ref("#7A3E1D")
const logoPrevia = ref<string | null>(null)
const previaDe = (f: File) => (logoPrevia.value = URL.createObjectURL(f))
const miembros = [
  { n: "Benito Cruz", u: null, rol: "admin", est: "on" as const, txt: "activo" },
  { n: "Aurelia Santiago", u: "aurelia", rol: "productor", est: "on" as const, txt: "activo" },
  { n: "Tomás Hernández", u: "tomas.h", rol: "operador", est: "on" as const, txt: "activo" },
  {
    n: "Prueba Enlace",
    u: "prueba.enlace",
    rol: "operador",
    est: "draft" as const,
    txt: "invitado",
  },
]
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -- sprite estático del repo, no dato de usuario -->
  <div class="sprite" aria-hidden="true" v-html="sprite"></div>

  <header v-if="!solo" class="hub-barra">
    <strong><Icono nombre="pulz-mark" :size="22" /> Design Hub · PULZ · demos F3</strong>
    <label
      >Pieza
      <select v-model="pieza">
        <option value="todas">Todas</option>
        <option v-for="p in PIEZAS" :key="p.id" :value="p.id">{{ p.nombre }}</option>
      </select>
    </label>
    <label
      >Vista
      <select v-model="modo">
        <option value="pagina">Página</option>
        <option value="espacios">3 espacios (1440 / 768 / 390)</option>
      </select>
    </label>
    <label><input v-model="oscuro" type="checkbox" @change="aplicarTema()" /> Oscuro</label>
  </header>

  <main v-if="modo === 'espacios' && !solo" class="marcos">
    <p class="nota">
      Cada marco es esta misma página a su ancho real: las reglas de compact (&lt;600) y de lista
      apilada (≤1023) son las de producción, no una simulación.
    </p>
    <div v-for="w in ANCHOS" :key="w" class="marco" :style="{ '--w': w + 'px' }">
      <p class="marco__rotulo">
        {{ w }}px · {{ w < 600 ? "compact" : w < 1024 ? "medium" : "expanded" }}
      </p>
      <iframe
        :src="urlMarco(pieza === 'todas' ? 'button' : pieza)"
        :title="`Demo a ${w}px`"
        :width="w"
        height="900"
      ></iframe>
    </div>
  </main>

  <main v-else class="hub" :class="{ 'hub--solo': solo }">
    <section v-if="visibles.some((p) => p.id === 'button')" id="button" class="pieza">
      <h2>Botón <code>button</code></h2>
      <div class="fila">
        <Boton intent="primary">Entrar</Boton>
        <Boton intent="secondary">Cancelar</Boton>
        <Boton intent="quiet">¿No puedes entrar?</Boton>
        <Boton intent="danger">Suspender…</Boton>
      </div>
      <div class="fila">
        <Boton intent="primary" loading>Entrar</Boton>
        <Boton intent="primary" disabled motivo-deshabilitado="Para entrar necesitas señal."
          >Entrar</Boton
        >
        <Boton intent="secondary" href="https://pulz.mx">Conoce PULZ (enlace)</Boton>
        <Boton intent="secondary"><Icono nombre="i-mas" :size="20" /> Agregar persona</Boton>
      </div>
      <p class="nota">
        Una primaria por vista. <code>adapt="page-primary"</code> ocupa toda la barra inferior en
        compact (ver marco 390).
      </p>
      <div class="barra-inferior"><Boton intent="primary" adapt="page-primary">Entrar</Boton></div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'text-field')" id="text-field" class="pieza">
      <h2>Campo de texto <code>text-field</code></h2>
      <div class="col">
        <CampoTexto
          v-model="usuario"
          etiqueta="Usuario o correo"
          size="lg"
          inputmode="email"
          autocomplete="username"
          ayuda="Si tu encargado te dio un usuario, escríbelo tal cual. Si eres el titular, tu correo."
          placeholder="ana.lopez"
        />
        <CampoTexto
          v-model="usuario"
          etiqueta="Usuario para entrar"
          error="Ese usuario ya existe en la empresa"
        />
        <CampoTexto model-value="Búsqueda" etiqueta="Buscar por nombre o usuario" type="search" />
        <CampoTexto model-value="" etiqueta="Deshabilitado" disabled />
      </div>
    </section>

    <section
      v-if="visibles.some((p) => p.id === 'password-field')"
      id="password-field"
      class="pieza"
    >
      <h2>Campo de contraseña <code>password-field</code></h2>
      <div class="col">
        <CampoContrasena v-model="contrasena" etiqueta="Contraseña" size="lg" />
        <CampoContrasena
          v-model="contrasena"
          etiqueta="Nueva contraseña"
          autocomplete="new-password"
          ayuda="Mínimo 8 caracteres."
        />
        <CampoContrasena
          v-model="contrasena"
          etiqueta="Repítela"
          autocomplete="new-password"
          error="No coinciden. Escríbela igual dos veces."
        />
      </div>
    </section>

    <section
      v-if="visibles.some((p) => p.id === 'segmented-choice')"
      id="segmented-choice"
      class="pieza"
    >
      <h2>Segmento de opciones <code>segmented-choice</code></h2>
      <div class="col">
        <SegmentoOpciones
          v-model="rol"
          etiqueta="Rol"
          :opciones="[
            { valor: 'admin', etiqueta: 'Admin', ayuda: 'Admin: todo.' },
            {
              valor: 'productor',
              etiqueta: 'Productor',
              ayuda: 'Productor: además todo el proceso.',
            },
            {
              valor: 'operador',
              etiqueta: 'Operador',
              ayuda: 'Operador: mediciones, corridas y cortes.',
            },
          ]"
        />
        <SegmentoOpciones
          v-model="entrega"
          etiqueta="¿Cómo le entregas el acceso?"
          :opciones="[
            {
              valor: 'enlace',
              etiqueta: 'Enlace por WhatsApp',
              ayuda: 'Dura 72 h y sirve una vez; la persona elige su contraseña.',
            },
            {
              valor: 'dictada',
              etiqueta: 'Contraseña dictada',
              ayuda: 'Se la dices en persona y la cambia al entrar.',
            },
          ]"
        />
      </div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'status-chip')" id="status-chip" class="pieza">
      <h2>Chip de estado <code>status-chip</code></h2>
      <div class="fila">
        <ChipEstado variante="on">activo</ChipEstado>
        <ChipEstado variante="draft">invitado</ChipEstado>
        <ChipEstado variante="off">suspendido</ChipEstado>
        <ChipEstado variante="partial">parcial</ChipEstado>
      </div>
      <p class="nota">Forma + texto; el color solo refuerza.</p>
    </section>

    <section v-if="visibles.some((p) => p.id === 'banner')" id="banner" class="pieza">
      <h2>Aviso <code>banner</code></h2>
      <div class="col">
        <Aviso variante="offline" titulo="Sin conexión."
          >Para entrar o hacer cambios necesitas señal.</Aviso
        >
        <Aviso variante="readonly" titulo="Solo lectura."
          >La suscripción venció: puedes consultar y exportar, no registrar.</Aviso
        >
      </div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'state-block')" id="state-block" class="pieza">
      <h2>Bloque de estado <code>state-block</code></h2>
      <BloqueEstado
        variante="empty"
        titulo="Solo estás tú"
        texto="Agrega a quien produce y a quien mide. Puedes dictarle una contraseña o mandarle un enlace por WhatsApp."
      >
        <Boton intent="primary"><Icono nombre="i-mas" :size="20" /> Agregar persona</Boton>
      </BloqueEstado>
      <BloqueEstado
        variante="error"
        titulo="No pudimos conectar"
        texto="Revisa tu señal. Lo que escribiste se conserva."
      >
        <Boton intent="secondary">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        variante="denied"
        titulo="Solo el administrador puede ver el equipo"
        texto="Pídele a Benito Cruz que te dé de alta o cambie tu rol."
      />
    </section>

    <section v-if="visibles.some((p) => p.id === 'task-layer')" id="task-layer" class="pieza">
      <h2>Capa de tarea <code>task-layer</code></h2>
      <Boton intent="primary" @click="capa = true"
        ><Icono nombre="i-mas" :size="20" /> Agregar persona</Boton
      >
      <p class="nota">
        Drawer derecho en ≥600, hoja inferior en compact; misma instancia. Esc, atrás y el fondo
        cierran; el foco vuelve al botón.
      </p>
      <CapaTarea :abierta="capa" titulo="Agregar persona" @cerrar="capa = false">
        <div class="col">
          <CampoTexto model-value="Rosalinda García" etiqueta="Nombre" />
          <CampoTexto
            model-value="rosalinda"
            etiqueta="Usuario para entrar"
            ayuda="Minúsculas, números, punto o guion (3 a 30). Solo se usa para entrar; no es un correo."
          />
          <SegmentoOpciones
            v-model="rol"
            etiqueta="Rol"
            :opciones="[
              { valor: 'admin', etiqueta: 'Admin' },
              { valor: 'productor', etiqueta: 'Productor' },
              { valor: 'operador', etiqueta: 'Operador' },
            ]"
          />
        </div>
        <template #acciones>
          <Boton intent="primary" @click="capa = false">Crear acceso</Boton>
          <Boton intent="secondary" @click="capa = false">Cancelar</Boton>
        </template>
      </CapaTarea>
    </section>

    <section
      v-if="visibles.some((p) => p.id === 'list-stack' || p.id === 'row-menu')"
      id="list-stack"
      class="pieza"
    >
      <h2>Lista apilada <code>list-stack</code> + Menú de fila <code>row-menu</code></h2>
      <ListaApilada
        resumen="Personas de Mezcal Cuatro Vientos: nombre, usuario, rol, estado y acciones"
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
        <tr v-for="m in miembros" :key="m.n">
          <td data-label="Nombre">
            <strong>{{ m.n }}</strong>
          </td>
          <td data-label="Usuario">
            <code v-if="m.u">{{ m.u }}</code
            ><span v-else class="muted">titular</span>
          </td>
          <td data-label="Rol">{{ m.rol }}</td>
          <td data-label="Estado">
            <ChipEstado :variante="m.est">{{ m.txt }}</ChipEstado>
          </td>
          <td data-label="Acciones">
            <MenuFila
              :nombre="m.n"
              :acciones="[
                { id: 'rol', etiqueta: 'Cambiar rol…' },
                ...(m.est === 'draft' ? [{ id: 'reenviar', etiqueta: 'Reenviar enlace' }] : []),
                { id: 'suspender', etiqueta: 'Suspender…', intent: 'danger' },
              ]"
              @seleccionar="ultimaAccion = `${$event} → ${m.n}`"
            />
          </td>
        </tr>
      </ListaApilada>
      <p v-if="ultimaAccion" class="nota" role="status">Acción elegida: {{ ultimaAccion }}</p>
    </section>

    <section v-if="visibles.some((p) => p.id === 'page-header')" id="page-header" class="pieza">
      <h2>Cabecera de página <code>page-header</code></h2>
      <CabeceraPagina
        titulo="Inicio"
        :empresa="{
          nombre: 'Mezcal Cuatro Vientos',
          subtitulo: 'titular · admin',
          iniciales: 'MC',
          acento: '#7A3E1D',
        }"
        @cuenta="cuentaAbierta = !cuentaAbierta"
      />
      <p class="nota">
        Línea de acento con el color de la empresa (solo acento). En expanded no lleva empresa:
      </p>
      <CabeceraPagina titulo="Equipo" />
      <p v-if="cuentaAbierta" class="nota" role="status">Abriría la Cuenta (task-layer).</p>
    </section>

    <section v-if="visibles.some((p) => p.id === 'side-nav')" id="side-nav" class="pieza">
      <h2>Menú lateral <code>side-nav</code></h2>
      <div class="demo-lateral">
        <NavLateral
          :items="destinos"
          :actual="navActual"
          :empresa="{
            nombre: 'Destilería Artesanal de los Cuatro Vientos del Valle',
            iniciales: 'DA',
          }"
          :cuenta="{ nombre: 'titular', subtitulo: 'admin · cuenta', iniciales: 'T' }"
          ancho="expanded"
          @cuenta="cuentaAbierta = !cuentaAbierta"
        />
        <NavLateral
          :items="destinos.slice(0, 7)"
          :actual="navActual"
          :empresa="{ nombre: 'Mezcal Cuatro Vientos', iniciales: 'MC' }"
          ancho="medium"
        />
      </div>
      <p class="nota">
        240 px (expanded, con cuenta al pie) y 200 px (medium, sin Configuración = productora).
      </p>
    </section>

    <section v-if="visibles.some((p) => p.id === 'bottom-nav')" id="bottom-nav" class="pieza">
      <h2>Navegación inferior <code>bottom-nav</code></h2>
      <div class="demo-inferior">
        <NavInferior :items="fijos" :actual="navActual" @mas="navActual = 'maguey'" />
      </div>
      <p class="nota">
        Solo en compact (&lt;600): 4 fijos + Más. Aquí se muestra fija dentro del marco; en la app
        es
        <code>position: fixed</code>. Ver el marco 390 en «3 espacios».
      </p>
    </section>

    <section v-if="visibles.some((p) => p.id === 'fab')" id="fab" class="pieza">
      <h2>Botón flotante <code>fab</code></h2>
      <div class="demo-inferior demo-inferior--fab">
        <BotonFlotante etiqueta="Medir" icono="i-medir" />
      </div>
      <p class="nota">
        Solo compact: la primaria del destino, 56 px, sobre la navegación inferior. En ≥600 no se
        muestra.
      </p>
    </section>

    <section v-if="visibles.some((p) => p.id === 'select')" id="select" class="pieza">
      <h2>Select <code>select</code></h2>
      <div class="col">
        <Selector
          v-model="catalogo"
          etiqueta="Catálogo"
          :opciones="[
            { valor: 'tipo_tina', etiqueta: 'Tipos de tina' },
            { valor: 'tipo_tanque', etiqueta: 'Tipos de tanque' },
            { valor: 'concepto', etiqueta: 'Conceptos de movimiento' },
            { valor: 'especie', etiqueta: 'Especies' },
          ]"
          ayuda="Para 4 o más opciones; con 3 o menos, segmento."
        />
        <Selector
          model-value=""
          etiqueta="Tipo (catálogo)"
          placeholder="Sin tipo"
          :opciones="[{ valor: 'a', etiqueta: 'Tanque de acero inoxidable' }]"
          error="Elige el tipo."
        />
      </div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'number-field')" id="number-field" class="pieza">
      <h2>Campo numérico <code>number-field</code></h2>
      <div class="col">
        <CampoNumero v-model="capacidad" etiqueta="Capacidad" unidad="L" ayuda="Opcional." />
        <CampoNumero
          :model-value="9"
          etiqueta="Hora del recordatorio"
          :decimales="false"
          error="Entre 0 y 23."
        />
      </div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'switch')" id="switch" class="pieza">
      <h2>Interruptor <code>switch</code></h2>
      <div class="col">
        <Interruptor
          v-model="puntas"
          etiqueta="¿Capturan puntas?"
          ayuda="Casi nadie (menos de 300 mL)."
        />
        <Interruptor
          :model-value="true"
          etiqueta="Avisar si una segunda pasada mezcla tinas"
          disabled
        />
      </div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'color-field')" id="color-field" class="pieza">
      <h2>Campo de color <code>color-field</code></h2>
      <div class="col">
        <CampoColor
          v-model="color"
          etiqueta="Color de la empresa"
          ayuda="Solo como acento; nunca detrás de texto."
        />
      </div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'file-picker')" id="file-picker" class="pieza">
      <h2>Selector de archivo <code>file-picker</code></h2>
      <div class="col">
        <SelectorArchivo
          etiqueta="Logo"
          :preview-url="logoPrevia"
          ayuda="PNG, JPG o WebP hasta 2 MB."
          texto-subir="Subir logo…"
          @elegir="previaDe($event)"
          @quitar="logoPrevia = null"
        />
      </div>
    </section>

    <section v-if="visibles.some((p) => p.id === 'brand-block')" id="brand-block" class="pieza">
      <h2>Bloque de marca <code>brand-block</code></h2>
      <div class="col">
        <BloqueMarca
          :marca="{
            nombre: 'Mezcal Cuatro Vientos',
            mensaje: 'Registro de producción del palenque',
            acento: color,
          }"
          nivel="p"
        />
        <BloqueMarca
          :marca="{
            nombre:
              'Destilería Artesanal de los Cuatro Vientos del Valle de Tlacolula y Anexas, S. de R.L. de C.V.',
            acento: '#173F87',
          }"
          nivel="p"
        />
        <BloqueMarca />
      </div>
      <p class="nota">
        La misma pieza en el portal (antes de entrar) y en la vista previa de Configuración.
      </p>
    </section>
  </main>
</template>

<style scoped>
.demo-lateral {
  display: flex;
  gap: var(--sp-4);
  align-items: flex-start;
  height: 520px;
}
.demo-inferior {
  position: relative;
  height: 120px;
  border: 1px dashed var(--border);
  border-radius: var(--r-lg);
  overflow: hidden;
}
.demo-inferior :deep(nav),
.demo-inferior :deep(.fab) {
  position: absolute;
}
.demo-inferior--fab :deep(.fab) {
  display: inline-flex;
  bottom: var(--sp-4);
}
.sprite {
  position: absolute;
  width: 0;
  height: 0;
  overflow: hidden;
}
.hub-barra {
  position: sticky;
  top: 0;
  z-index: 10;
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-4);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  font: 500 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.hub-barra label {
  display: flex;
  flex: 1 1 200px;
  min-width: 0;
  gap: var(--sp-2);
  align-items: center;
}
.hub-barra select {
  flex: 1 1 0;
  min-width: 0; /* con texto al 200 % no ensancha la barra */
  min-height: var(--tap);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: inherit;
  padding: 0 var(--sp-2);
}
.hub {
  max-width: 960px;
  margin: 0 auto;
  padding: var(--sp-6) var(--sp-4) var(--sp-10);
  color: var(--text);
}
.hub--solo {
  max-width: none;
}
.pieza {
  margin-bottom: var(--sp-10);
}
.pieza h2 {
  font: 600 1.25rem/1.3 var(--font);
  margin: 0 0 var(--sp-4);
}
.pieza code {
  font-size: 0.8125rem;
  color: var(--muted);
  background: var(--ink-100);
  border-radius: var(--r-sm);
  padding: 0 var(--sp-1);
}
.fila {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-3);
  align-items: flex-start;
  margin-bottom: var(--sp-4);
}
.col {
  display: grid;
  gap: var(--sp-4);
  max-width: 440px;
}
.nota {
  font-size: 0.875rem;
  color: var(--muted);
  margin: var(--sp-2) 0;
}
.muted {
  color: var(--muted);
}
.sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
}
.barra-inferior {
  margin-top: var(--sp-4);
  padding: var(--sp-3) var(--sp-4);
  border: 1px dashed var(--border);
  border-radius: var(--r-lg);
}
.marcos {
  padding: var(--sp-4);
  overflow-x: auto;
  display: grid;
  gap: var(--sp-6);
}
.marco {
  width: var(--w);
  max-width: 100%;
}
.marco__rotulo {
  font: 500 0.8125rem/1.2 var(--font);
  color: var(--muted);
  margin: 0 0 var(--sp-2);
}
.marco iframe {
  display: block;
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--canvas);
  max-width: 100%;
}
</style>
