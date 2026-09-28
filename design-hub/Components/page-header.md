# Cabecera de página · `page-header`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/shell/r01` |
| Código | `apps/web/src/shared/ui/CabeceraPagina.vue` |
| Demo real | `Components/demo/index.html#page-header` |
| Pruebas | `shell.test.ts` (1 caso) |
| Evidencia | `qa/evidence/shell-r01/inicio-*`, `configuracion-*` |

## Para qué

Decir dónde estás (título del destino) y en qué empresa y con qué rol
(botón de empresa que abre la Cuenta). La línea superior de 4 px lleva el
color de la empresa **solo como acento**, nunca detrás de texto.

## Anatomía

`header` → línea de acento (`--acento`, por defecto `--clay-300`) ·
`button[aria-haspopup=dialog][title=nombre completo]` con iniciales, nombre
en una línea con elipsis y `persona · rol` · `h1` del destino.

## Estados

default · nombre largo (elipsis; completo en `title`) · sin empresa
(expanded: solo `h1`, más grande).

## Accesibilidad

Botón ≥44 px con nombre completo en `title`; `h1` único por pantalla (las
páginas usan `h2` en adelante).

## API real

```ts
props: {
  titulo: string
  empresa?: { nombre: string; subtitulo: string; iniciales: string; acento?: string | null }
}
emits: { cuenta: [] }
```

## Implementación

Tokens: `--clay-300/100`, `--border`, `--surface`, `--text`, `--muted`,
`--ink-900/100`, `--tap`, `--sp-*`, `--r-md`, `--r-pill`, `--font`.
Dependencias: ninguna.

## QA y ciclo de vida

Capturas en 4 anchos × 2 temas; prueba de componente. **Pendiente para
Stable:** nombre largo real, harden/audit.
