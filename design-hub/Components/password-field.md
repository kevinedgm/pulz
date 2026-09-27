# Campo de contraseña · `password-field`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/CampoContrasena.vue` |
| Demo real | `Components/demo/index.html#password-field` |
| Pruebas | `ui.test.ts` (1 caso: mostrar/ocultar sin perder el valor) |
| Evidencia | `qa/evidence/acceso-r01/portal-*`, `cambiar-contrasena-*`, `bienvenida-*` |

## Para qué

Contraseña con botón **Mostrar / Ocultar** de texto (el sprite no tiene ojo).
Es una pieza aparte de `text-field` porque cambia anatomía e interacción.

## Uso

- `autocomplete="current-password"` para entrar; `"new-password"` para
  elegir o cambiar.
- El mínimo de 8 caracteres lo valida el formulario (bajo el campo, al salir);
  el campo no lo impone.
- `size="lg"` en el portal (compact, una mano).

## Anatomía

`label` → fila: `input[type=password|text]` + `button` «Mostrar/Ocultar»
(`aria-pressed`, 44 px, `flex: none`) → ayuda **o** error.

## Estados

default · focus (input y botón con anillo) · disabled · error · **revealed**
(`type=text`, botón «Ocultar», `aria-pressed=true`).

## Comportamiento

Alternar visibilidad no cambia el valor ni el foco del input. `blur` para
validar en el formulario. `aria-describedby` solo a ids presentes.

## Responsive

Ancho completo; el input tiene base flex 0 y la columna `minmax(0, 1fr)`, así
que con texto al 200 % el botón sigue a la derecha sin desbordar (corregido
en la compuerta de lima).

## Accesibilidad

Botón con nombre visible y estado `aria-pressed`; borde de campo `--muted`;
targets 44 px; contraste del botón (`--ink-900` sobre `--surface`) 10.0 / 6.5.

## API real

```ts
props: {
  modelValue: string; etiqueta: string
  ayuda?: string; error?: string
  size?: "md" | "lg"                                       // md
  autocomplete?: "current-password" | "new-password"       // current-password
  disabled?: boolean; required?: boolean; name?: string
}
emits: { "update:modelValue": [string]; blur: [FocusEvent] }
```

## Implementación

Tokens como `text-field` más `--ink-900` para el botón. Dependencias del
registry: `text-field` (mismo contrato de etiqueta/ayuda/error), `button`
(mismo contrato de foco y target; no reutiliza el componente `Boton`).

## QA y ciclo de vida

Igual que `text-field`. **Pendiente para Stable:** zoom nativo, harden/audit.
