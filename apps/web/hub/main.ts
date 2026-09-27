// Design Hub · demos F3. Se construye con `pnpm --filter @pulz/web build:hub`
// hacia design-hub/Components/demo/: las piezas REALES de src/shared/ui con
// los tokens REALES. No es una copia paralela del sistema.
import { createApp } from "vue"
import "../src/shared/ui/tokens.css"
import "../src/style.css"
import DemoHub from "./DemoHub.vue"

createApp(DemoHub).mount("#hub")
