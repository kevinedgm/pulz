#!/usr/bin/env python3
"""kiwi · check_artifact.py — verificador estático de wireframes F1/F2.

Uso:
    python3 check_artifact.py <archivo.html> [--fidelidad F1|F2]

Comprueba:
  - estructura mínima (lang, viewport, title) y etiquetas balanceadas;
  - solo grises (hex, rgb/rgba, hsl) en <style>, style="" y CSS locales enlazados;
  - una sola familia tipográfica (la monoespaciada para código no cuenta);
  - panel de estados (F2) y notas de decisión;
  - sin fuentes ni hojas externas salvo el kit.
Sale con código 1 si hay errores. No sustituye la revisión en navegador.
"""
import argparse
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
        "param", "source", "track", "wbr"}
GRAY_TOL = 6  # diferencia máxima entre canales para considerar gris


class Collector(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.unbalanced = [], []
        self.styles, self.inline, self.links, self.metas = [], [], [], {}
        self.lang = None
        self.title = False
        self._in_style = False
        self._in_title = False
        self.text = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "html":
            self.lang = a.get("lang")
        if tag == "meta" and a.get("name"):
            self.metas[a["name"]] = a.get("content", "")
        if tag == "link" and "stylesheet" in (a.get("rel") or ""):
            self.links.append(a.get("href", ""))
        if "style" in a and a["style"]:
            self.inline.append(a["style"])
        if tag == "style":
            self._in_style = True
        if tag == "title":
            self._in_title = True
        if tag not in VOID:
            self.stack.append((tag, self.getpos()[0]))

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag not in VOID and self.stack and self.stack[-1][0] == tag:
            self.stack.pop()

    def handle_endtag(self, tag):
        if tag == "style":
            self._in_style = False
        if tag == "title":
            self._in_title = False
        if tag in VOID:
            return
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i][0] == tag:
                for t, line in self.stack[i + 1:]:
                    self.unbalanced.append(f"<{t}> abierta en línea {line} sin cerrar")
                del self.stack[i:]
                return
        self.unbalanced.append(f"</{tag}> sin apertura (línea {self.getpos()[0]})")

    def handle_data(self, data):
        if self._in_style:
            self.styles.append(data)
        elif self._in_title and data.strip():
            self.title = True
        else:
            self.text.append(data)


def is_gray(r, g, b):
    return max(r, g, b) - min(r, g, b) <= GRAY_TOL


def colors_in(css):
    bad = []
    for m in re.finditer(r"#([0-9a-fA-F]{3,8})\b", css):
        h = m.group(1)
        if len(h) in (3, 4):
            r, g, b = (int(c * 2, 16) for c in h[:3])
        elif len(h) in (6, 8):
            r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
        else:
            continue
        if not is_gray(r, g, b):
            bad.append(m.group(0))
    for m in re.finditer(r"rgba?\(\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)", css):
        r, g, b = map(int, m.groups())
        if not is_gray(r, g, b):
            bad.append(m.group(0) + ")")
    for m in re.finditer(r"hsla?\(\s*[\d.]+(?:deg)?[\s,]+([\d.]+)%", css):
        if float(m.group(1)) > 3:
            bad.append(m.group(0) + ")")
    named = re.findall(r"(?<![\w-])(red|blue|green|orange|purple|yellow|pink|teal|cyan|magenta|lime|navy|olive|maroon|aqua|fuchsia)(?![\w-])", css)
    bad += named
    return bad


def families_in(css):
    fams = set()
    for m in re.finditer(r"font-family\s*:\s*([^;}{]+)", css):
        val = m.group(1).strip()
        if "var(" in val:
            continue
        first = val.split(",")[0].strip().strip("'\"").lower()
        if first and "mono" not in first and first not in ("inherit", "monospace", "menlo", "consolas"):
            fams.add(first)
    for m in re.finditer(r"--[\w-]*font[\w-]*\s*:\s*([^;}{]+)", css):
        first = m.group(1).split(",")[0].strip().strip("'\"").lower()
        if first and "mono" not in first and first not in ("monospace", "menlo", "consolas"):
            fams.add(first)
    fams.discard("system-ui")  # la pila del kit empieza en system-ui
    return fams


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("archivo")
    ap.add_argument("--fidelidad", default="F2", choices=["F1", "F2", "F3"])
    args = ap.parse_args()

    if args.fidelidad == "F3":
        print("F3 no es de kiwi: la alta fidelidad con el sistema real la verifica coco.")
        return 2

    path = Path(args.archivo)
    html = path.read_text(encoding="utf-8")
    c = Collector()
    c.feed(html)
    c.close()

    errors, warns, oks = [], [], []

    # Estructura
    (oks if c.lang else errors).append("atributo lang en <html>" if c.lang else "falta lang en <html>")
    if "viewport" in c.metas:
        oks.append("meta viewport")
    else:
        errors.append("falta <meta name=viewport>")
    (oks if c.title else warns).append("<title> presente" if c.title else "falta <title>")
    for t, line in c.stack:
        c.unbalanced.append(f"<{t}> abierta en línea {line} sin cerrar")
    if c.unbalanced:
        errors += c.unbalanced[:10]
    else:
        oks.append("etiquetas balanceadas")

    # CSS: inline + <style> + hojas locales
    css = "\n".join(c.styles + c.inline)
    for href in c.links:
        if re.match(r"https?://", href):
            errors.append(f"hoja externa en un wireframe: {href}")
            continue
        p = (path.parent / href).resolve()
        if p.exists():
            css += "\n" + p.read_text(encoding="utf-8")
        else:
            warns.append(f"hoja enlazada no encontrada: {href}")
    # también estilos generados en JS (cadenas style="...")
    css += "\n".join(re.findall(r"style=\\?[\"']([^\"']+)", html))

    bad = sorted(set(colors_in(css)))
    if bad:
        errors.append("colores no grises: " + ", ".join(bad[:12]))
    else:
        oks.append("solo grises")

    fams = families_in(css)
    if len(fams) > 1:
        errors.append("más de una familia tipográfica: " + ", ".join(sorted(fams)))
    else:
        oks.append("una familia tipográfica")
    if re.search(r"fonts\.googleapis|@font-face", html + css):
        warns.append("fuentes web cargadas: el kit usa la pila del sistema")

    # Estados y notas
    low = html.lower()
    has_panel = "data-wf-states" in low or re.search(r"<select[^>]*id=\"?[\w-]*state", low)
    states = [s for s in ("carga", "vacío", "error", "sin permiso", "sin conexión") if s in low]
    if args.fidelidad == "F2":
        if has_panel:
            oks.append("panel de estados")
        else:
            warns.append("sin panel de estados (F2 los exige en un panel, no en pantallas duplicadas)")
        missing = {"carga", "vacío", "error"} - set(states)
        if missing:
            warns.append("estados no mencionados: " + ", ".join(sorted(missing)))
    if "wf-note" in low:
        oks.append("notas de decisión")
    else:
        warns.append("sin notas wf-note: anota decisiones y supuestos")

    prim = len(re.findall(r"wf-btn--primary|class=\"[^\"]*\bprimary\b", html))
    if prim:
        oks.append(f"{prim} marcas de acción primaria (revisa: una por vista)")

    print(f"kiwi · check_artifact · {path.name} · {args.fidelidad}")
    for o in oks:
        print("  ✔", o)
    for w in warns:
        print("  !", w)
    for e in errors:
        print("  ✘", e)
    print(f"\n{len(errors)} errores · {len(warns)} avisos")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
