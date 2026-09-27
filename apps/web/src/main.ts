import { createApp } from "vue"
import { createPinia } from "pinia"
import "./shared/ui/tokens.css"
import "./style.css"
import App from "./App.vue"
import router from "./app/router"

createApp(App).use(createPinia()).use(router).mount("#app")
