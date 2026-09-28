import { createApp } from "vue"
import { createPinia } from "pinia"
import "./shared/ui/tokens.css"
import "./style.css"
import App from "./App.vue"
import router from "./app/router"
import { aplicarTemaGuardado } from "./app/tema"

// Tema guardado antes de montar: sin parpadeo (shell/r01)
aplicarTemaGuardado()

createApp(App).use(createPinia()).use(router).mount("#app")
