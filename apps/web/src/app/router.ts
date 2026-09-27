import { createRouter, createWebHistory } from "vue-router"

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/",
      name: "inicio",
      component: () => import("../modules/inicio/pages/InicioPage.vue"),
    },
  ],
})

export default router
