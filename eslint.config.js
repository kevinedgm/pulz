import js from "@eslint/js"
import tseslint from "typescript-eslint"
import pluginVue from "eslint-plugin-vue"
import eslintConfigPrettier from "eslint-config-prettier"
import globals from "globals"

export default tseslint.config(
  {
    // .claude/, .agents/ y design-hub/ son tooling de terceros (Fruti Squad,
    // agent-skills): no son código nuestro y traen scripts minificados.
    ignores: [
      "**/dist/**",
      "**/node_modules/**",
      "**/.wrangler/**",
      "docs/**",
      ".claude/**",
      ".agents/**",
      "design-hub/**",
      "supabase/.temp/**",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...pluginVue.configs["flat/recommended"],
  {
    files: ["**/*.vue"],
    languageOptions: {
      parserOptions: {
        parser: tseslint.parser,
      },
    },
  },
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    rules: {
      "vue/multi-word-component-names": "off",
      // Con defineProps<>() tipado, un prop opcional (`x?: string`) ya es
      // undefined por defecto; exigir `default: undefined` solo mete ruido.
      "vue/require-default-prop": "off",
    },
  },
  eslintConfigPrettier,
)
