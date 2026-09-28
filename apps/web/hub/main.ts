// Design Hub · demos F3. Se construye con `pnpm --filter @pulz/web build:hub`
// hacia design-hub/Components/demo/: las piezas REALES de src/shared/ui con
// los tokens REALES. No es una copia paralela del sistema.
import { createApp, defineComponent } from "vue"
import { createMemoryHistory, createRouter } from "vue-router"
import "../src/shared/ui/tokens.css"
import "../src/style.css"
import DemoHub from "./DemoHub.vue"

// Router en memoria: las navegaciones (side-nav, bottom-nav) usan RouterLink
// y la demo no navega a ningún lado.
const router = createRouter({
  history: createMemoryHistory(),
  routes: [{ path: "/:pathMatch(.*)*", component: defineComponent({ render: () => null }) }],
})

createApp(DemoHub).use(router).mount("#hub")
