import { describe, expect, it } from "vitest"
import { mount } from "@vue/test-utils"
import InicioPage from "../pages/InicioPage.vue"

describe("InicioPage", () => {
  it("monta sin truenar y muestra el nombre del producto", () => {
    const wrapper = mount(InicioPage)
    expect(wrapper.text()).toContain("PULZ")
  })
})
