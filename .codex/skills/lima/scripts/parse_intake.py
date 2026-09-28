#!/usr/bin/env python3
"""
parse_intake.py — dependency-free parser for the lima
intake file (reference/intake.md format). Emits shell-eval lines consumed by
init-project.sh. No PyYAML required: the intake is a small, known subset
(flat scalar keys, `|` block scalars, simple `-` lists).

Output (each line is `eval`-safe):
  INTAKE_NAME=...            INTAKE_DESIGN_SYSTEM=...
  INTAKE_HUB_ROOT=...        INTAKE_HUB_LANG=...
  INTAKE_QA_RUNNER=...       INTAKE_SERVE=...
  INTAKE_COLOR_LAW=$'...'    INTAKE_TYPE_LAW=$'...'   (multiline, escaped)
  INTAKE_STACK=...           INTAKE_TOKEN_BINDING=...
  INTAKE_COMPONENT_LAYOUT=...INTAKE_A11Y=...  INTAKE_TOUCH=...
  INTAKE_VIEWPORTS=...       INTAKE_ANTI=...
  INTAKE_TRUTH=( "a" "b" )   (bash array)
"""
import sys, re

SCALARS = {
    "project_name", "design_system_name", "hub_root", "hub_language",
    "qa_runner", "serve_command", "framework", "styling", "icon_library",
    "router", "component_dir", "naming_convention", "a11y_target",
    "touch_min_px", "canonical_reference", "breakpoints",
}
BLOCKS = {"color_law", "type_law"}
LISTS = {"tokens_source", "anti_references"}


def strip_inline_comment(v: str) -> str:
    # Remove a trailing "# ..." comment that is not inside quotes.
    out, q = [], None
    for ch in v:
        if q:
            out.append(ch)
            if ch == q:
                q = None
        elif ch in "\"'":
            q = ch
            out.append(ch)
        elif ch == "#":
            break
        else:
            out.append(ch)
    return "".join(out).strip()


def unquote(v: str) -> str:
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        return v[1:-1]
    return v


def parse(lines):
    data, i, n = {}, 0, len(lines)
    while i < n:
        raw = lines[i].rstrip("\n")
        i += 1
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        m = re.match(r"^([a-z][a-z0-9_]*):(.*)$", raw)
        if not m:
            continue
        key, rest = m.group(1), m.group(2)
        rest_stripped = rest.strip()

        if key in BLOCKS and rest_stripped.startswith("|"):
            # collect indented lines until dedent
            block = []
            while i < n:
                ln = lines[i].rstrip("\n")
                if ln.strip() == "":
                    block.append("")
                    i += 1
                    continue
                if re.match(r"^\s+", ln):
                    block.append(re.sub(r"^\s{2}", "", ln, count=1))
                    i += 1
                else:
                    break
            # drop trailing blank lines
            while block and block[-1] == "":
                block.pop()
            data[key] = "\n".join(block)
            continue

        if key in LISTS:
            if rest_stripped and rest_stripped != "":
                # inline list like [a, b] or a single value
                if rest_stripped.startswith("["):
                    items = [unquote(x) for x in rest_stripped.strip("[]").split(",") if x.strip()]
                    data[key] = items
                else:
                    data[key] = [unquote(strip_inline_comment(rest_stripped))]
                continue
            items = []
            while i < n:
                ln = lines[i].rstrip("\n")
                lm = re.match(r"^\s+-\s*(.*)$", ln)
                if lm:
                    val = unquote(strip_inline_comment(lm.group(1)))
                    if val:
                        items.append(val)
                    i += 1
                elif ln.strip() == "" or ln.lstrip().startswith("#"):
                    i += 1
                else:
                    break
            data[key] = items
            continue

        if key in SCALARS:
            data[key] = unquote(strip_inline_comment(rest_stripped))
            continue
    return data


def sh_single(s: str) -> str:
    # single-quote for shell, escaping embedded single quotes
    return "'" + s.replace("'", "'\\''") + "'"


def emit(data):
    out = []

    def scalar(varname, key, default=""):
        v = data.get(key, default)
        if isinstance(v, list):
            v = ", ".join(v)
        out.append(f"{varname}={sh_single(v or default)}")

    scalar("INTAKE_NAME", "project_name")
    scalar("INTAKE_DESIGN_SYSTEM", "design_system_name")
    scalar("INTAKE_HUB_ROOT", "hub_root")
    scalar("INTAKE_HUB_LANG", "hub_language")
    scalar("INTAKE_QA_RUNNER", "qa_runner")
    scalar("INTAKE_SERVE", "serve_command")
    scalar("INTAKE_A11Y", "a11y_target")
    scalar("INTAKE_TOUCH", "touch_min_px")
    scalar("INTAKE_VIEWPORTS", "breakpoints")

    # combine name + design system when both present
    name = data.get("project_name", "")
    ds = data.get("design_system_name", "")
    full = f"{name} / {ds}" if name and ds and ds != "NEW" else (name or ds)
    out.append(f"INTAKE_NAME={sh_single(full)}")

    # stack sentence
    stack_bits = [data.get(k, "") for k in ("framework", "styling", "icon_library", "router")]
    stack = " + ".join(b for b in stack_bits if b and b != "AUTO")
    out.append(f"INTAKE_STACK={sh_single(stack or 'confirm by inspection')}")

    comp = data.get("component_dir", "")
    naming = data.get("naming_convention", "")
    cl = f"{comp}".strip()
    if naming and naming != "AUTO":
        cl = f"{cl} ({naming})" if cl else naming
    out.append(f"INTAKE_COMPONENT_LAYOUT={sh_single(cl or 'match existing naming')}")

    toks = data.get("tokens_source", [])
    if isinstance(toks, str):
        toks = [toks]
    tb = f"Map Hub tokens to {toks[0]}; never hardcode values." if toks and toks[0] not in ("AUTO", "") else "Map Hub tokens to the tokens_source file; never hardcode values."
    out.append(f"INTAKE_TOKEN_BINDING={sh_single(tb)}")

    anti = data.get("anti_references", [])
    if isinstance(anti, str):
        anti = [anti]
    out.append(f"INTAKE_ANTI={sh_single('; '.join(anti))}")

    # block scalars -> $'...' so newlines survive eval
    for var, key in (("INTAKE_COLOR_LAW", "color_law"), ("INTAKE_TYPE_LAW", "type_law")):
        v = data.get(key, "")
        esc = v.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")
        out.append(f"{var}=$'{esc}'")

    # truth_sources array (tokens + canonical reference)
    truth = list(toks) if toks and toks[0] not in ("AUTO", "") else []
    canon = data.get("canonical_reference", "")
    if canon and canon != "AUTO":
        truth.append(canon)
    arr = " ".join(sh_single(t) for t in truth)
    out.append(f"INTAKE_TRUTH=({arr})")

    return "\n".join(out)


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: parse_intake.py <intake.yaml>\n")
        return 2
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        lines = f.readlines()
    print(emit(parse(lines)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
