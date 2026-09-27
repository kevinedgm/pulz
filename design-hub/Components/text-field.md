# Campo de texto · `text-field`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/CampoTexto.vue` |
| Demo real | `Components/demo/index.html#text-field` |
| Pruebas | `ui.test.ts` (2 casos: etiqueta/describedby/aria-invalid, v-model) |
| Evidencia | `qa/evidence/acceso-r01/portal-*`, `equipo-alta-*` |

## Para qué

Entrada de una línea con etiqueta **siempre visible**, ayuda opcional y error
bajo el campo. El placeholder solo ejemplifica («ana.lopez»), nunca sustituye
a la etiqueta.

## Uso

- `size="lg"` (52 px) en los campos de acceso en compact: una mano, sol.
  `md` (44 px) en el resto.
- `inputmode`, `autocapitalize` y `autocomplete` según la intención del dato
  (`email` + `none` + `username` para «Usuario o correo»).
- La validación la hace el formulario al salir del campo (`blur`) y la pasa
  por `error`; el campo no valida solo.

## Anatomía

`label[for]` → `input` → `p` de ayuda (`id`-ayuda) **o** `p` de error
(`id`-error). La ayuda se oculta mientras hay error.

## Estados

default · focus-visible (borde y anillo `--ink-900`) · disabled (opacidad,
`cursor: not-allowed`) · error (borde `--late`, `aria-invalid`, texto en
negrita `--late`).

## Comportamiento

- `update:modelValue` en cada `input`; `blur` para que el consumidor valide.
- `aria-describedby` apunta solo a ids que existen en el DOM (ayuda **o**
  error; corregido en la ronda).
- Texto largo: el input desplaza horizontalmente, no recorta.

## Responsive

Ancho completo del contenedor en todos los rangos. La columna del grid es
`minmax(0, 1fr)` y el control `min-width: 0`: con texto al 200 % el input no
impone su ancho intrínseco al viewport (corregido en la compuerta de lima).

## Accesibilidad

Etiqueta ligada (`for`/`id` con `useId`); borde en `--muted` (4.9:1, límite
del control visible bajo el sol); anillo de foco 3 px; error con causa y
solución, en texto.

## API real

```ts
props: {
  modelValue: string; etiqueta: string
  ayuda?: string; error?: string
  size?: "md" | "lg"                                              // md
  type?: "text" | "email" | "search" | "password"                 // text
  inputmode?: "text" | "email" | "search" | "none"
  autocomplete?: string
  autocapitalize?: "none" | "sentences" | "words"                 // none
  placeholder?: string; disabled?: boolean; required?: boolean; name?: string
}
emits: { "update:modelValue": [string]; blur: [FocusEvent] }
```

## Implementación

Tokens: `--muted`, `--ink-900`, `--late`, `--surface`, `--text`, `--tap`,
`--sp-*`, `--r-md`, `--font`. Dependencias: ninguna.

## QA y ciclo de vida

viewports runtime-verified · teclado en jsdom (aprox.) · touch emulado ·
zoom 200 % aproximado · contraste medido. **Pendiente para Stable:** texto
largo con datos reales, zoom nativo a mano, harden/audit.
