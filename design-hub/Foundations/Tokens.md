# Tokens

| Campo | Valor |
|---|---|
| Fuente propietaria | `apps/web/src/shared/ui/tokens.css` (copia sembrada de `docs/referencia/pulz-tokens.css`; cambia solo con aprobación del dueño) |
| Ley | `PULZ_MAESTRO.md` §13.4 · perfil `.claude/skills/lima/profiles/pulz.md` (`color_law`, `type_law`) |
| Regla dura | nunca un valor a mano si existe un token; un color de acción, uno de peligro, semánticos solo en estados |

## Color

| Token | Claro | Oscuro | Rol |
|---|---|---|---|
| `--ink-900` | `#173F87` | `#7FA3E0` | acción (primaria, enlaces, foco, selección) |
| `--ink-700` | `#275AA5` | `#A4BEEB` | hover de la primaria |
| `--ink-100` | `#DDE7F5` | `#1E2B44` | fondo suave de acción (hover secundario, menú abierto) |
| `--clay-300` / `--clay-100` | `#F2CFC2` / `#FAEAE4` | `#E0A98F` / `#3A2A25` | acento de marca, monograma |
| `--canvas` / `--surface` | `#F8F6F2` / `#FFFFFF` | `#0F1521` / `#171F2E` | lienzo / superficie |
| `--text` / `--muted` | `#18243A` / `#687184` | `#EEF1F7` / `#9AA5BB` | texto / secundario y **límite de campo** |
| `--border` | `#DDE1E7` | `#2A3549` | separadores (no límite de control: 1.3:1) |
| `--ok` · `--ok-bg` | `#287A55` · `#E4F2EA` | `#6FC79A` · `#163526` | estado al día / activo |
| `--pend` · `--pend-bg` | `#C17A18` · `#FBEEDB` | `#E9B356` · `#3A2A10` | pendiente / invitado / sin conexión |
| `--late` · `--late-bg` | `#B93A2E` · `#FBE4E1` | `#F0837A` · `#3B1B18` | atrasado / error / destructivo |
| `--info` · `--info-bg` | `#2B6CB0` · `#E1ECF8` | `#7FB2F0` · `#18304B` | informativo / solo lectura |

Modo oscuro: mismos nombres, valores invertidos, por `prefers-color-scheme`
y `[data-theme="dark"]`.

### Contraste medido (lima, compuerta Candidate 2026-09-27)

| Par | Uso | Claro | Oscuro |
|---|---|---|---|
| `--text` / `--surface` | texto | 15.5 | 14.6 |
| `--muted` / `--surface` | ayudas 13 px, límite de campo | 4.9 | 6.7 |
| `--surface` / `--ink-900` | texto de la primaria | 10.0 | 6.5 |
| `--ok` / `--ok-bg` | chip activo | 4.5 | 6.6 |
| `--pend` / `--pend-bg` | **solo borde y punto** (texto: 3.0 en claro, `docs/DUDAS.md` #12) | 3.0 | 7.3 |
| `--late` / `--late-bg` | chip suspendido, rechazo | 4.7 | 6.1 |
| `--info` / `--info-bg` | aviso solo lectura | 4.5 | 6.1 |
| `--ink-900` / `--canvas` | anillo de foco | 9.3 | 7.2 |

## Tipografía

`--font: "Atkinson Hyperlegible Next", "Atkinson Hyperlegible", system-ui, …`.
Base 16 px; tamaños en `rem` en todas las piezas (escalan al 200 %).

## Geometría y espacio

| Token | Valor |
|---|---|
| `--r-sm` · `--r-md` · `--r-lg` · `--r-xl` · `--r-2xl` · `--r-pill` | 8 · 10 · 12 · 14 · 16 · 999 px |
| `--tap` | 44 px (objetivo táctil mínimo; campos de acceso 52 px) |
| `--sp-1…10` | 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 px |
| `--shadow` | elevación de capas y menús (nunca decorativa) |

## Marca

`--brand-ink`, `--brand-clay` y sus hover son la identidad PULZ. El color de
cada empresa (`portal_branding.brand_color`) se usa **solo como acento** sobre
fondo neutro (línea superior y monograma del portal), nunca detrás de texto.
