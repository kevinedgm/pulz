#!/usr/bin/env bash
#
# init-project.sh — first-run bootstrap for the lima skill.
#
# Makes the skill usable in a brand-new repo by generating everything
# project-specific that the skill core delegates to a profile:
#   - profiles/<slug>.md            (from profiles/_TEMPLATE.md)
#   - <hub>/                        (Design Hub root + taxonomy folders)
#   - <hub>/system/registry.json    (empty registry: {})
#   - <hub>/qa/                     (Playwright QA harness) if --qa playwright
#
# It is additive and idempotent: it never overwrites an existing profile,
# Hub, or registry, and prints the next commands + human-only TODOs.
#
# Usage:
#   bash scripts/init-project.sh \
#     --name "Acme / PULZ" \
#     --design-system "PULZ" \
#     --hub "design-hub" \
#     --qa playwright
#
# impeccable is BUNDLED with this skill (vendor/impeccable). --impeccable
# defaults to that bundled copy, so the skill is self-contained and needs no
# external install. Pass --impeccable <path> only to override with a shared one.
#
# --intake <file>: parse a filled intake YAML (reference/intake.md format) and
# generate a COMPLETE profile (no TODOs). Needs python3 (no PyYAML). Explicit
# flags (--name/--hub/--qa) still override the intake's values.
#
# All flags optional; sensible defaults are used and echoed. Run from the
# repo root (the script resolves its own location, so cwd is the target repo).

set -euo pipefail

# ---- defaults -------------------------------------------------------------
NAME=""
DESIGN_SYSTEM=""
HUB=""              # empty => default "design-hub" (or from intake hub_root)
IMPECCABLE=""       # empty => default to the bundled vendor/impeccable (resolved below)
QA=""               # empty => default "none" (or from intake qa_runner)
HUB_PORT="4321"
INTAKE=""           # path to a filled intake YAML (reference/intake.md format)

# ---- parse args -----------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)          NAME="${2:-}"; shift 2;;
    --design-system) DESIGN_SYSTEM="${2:-}"; shift 2;;
    --hub)           HUB="${2:-}"; shift 2;;
    --impeccable)    IMPECCABLE="${2:-}"; shift 2;;
    --qa)            QA="${2:-}"; shift 2;;
    --port)          HUB_PORT="${2:-}"; shift 2;;
    --intake)        INTAKE="${2:-}"; shift 2;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "Unknown flag: $1" >&2; exit 2;;
  esac
done

# ---- locate the skill -----------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$SKILL_DIR/profiles/_TEMPLATE.md"
PROFILES_DIR="$SKILL_DIR/profiles"
VENDOR_IMPECCABLE="$SKILL_DIR/vendor/impeccable"

[[ -f "$TEMPLATE" ]] || { echo "ERROR: template not found at $TEMPLATE" >&2; exit 1; }

# ---- intake file (optional) ----------------------------------------------
# When --intake <file> is given, parse the filled intake YAML (reference/intake.md
# format) and derive the profile fields from it. Uses a dependency-free Python
# parser (no PyYAML needed). The intake is the authoritative source; --name /
# --design-system / --hub / --qa flags still override individual values.
HAVE_INTAKE=0
declare -a INTAKE_TRUTH=()
INTAKE_COLOR_LAW="" INTAKE_TYPE_LAW="" INTAKE_STACK="" INTAKE_COMPONENT_LAYOUT=""
INTAKE_A11Y="" INTAKE_TOUCH="" INTAKE_ANTI="" INTAKE_VIEWPORTS="" INTAKE_SERVE=""
INTAKE_TOKEN_BINDING="" INTAKE_HUB_LANG=""

if [[ -n "$INTAKE" ]]; then
  [[ -f "$INTAKE" ]] || { echo "ERROR: intake file not found: $INTAKE" >&2; exit 1; }
  command -v python3 >/dev/null 2>&1 || { echo "ERROR: --intake needs python3 to parse YAML." >&2; exit 1; }
  # Emit `KEY=value` lines (shell-quoted) that we eval. Block scalars and lists
  # are flattened to single-line, safe strings.
  INTAKE_EVAL="$(python3 "$SCRIPT_DIR/parse_intake.py" "$INTAKE")" \
    || { echo "ERROR: failed to parse intake $INTAKE" >&2; exit 1; }
  eval "$INTAKE_EVAL"
  HAVE_INTAKE=1
fi

# ---- resolve defaults (after intake so intake can set them) ---------------
[[ -n "$HUB" ]] || HUB="${INTAKE_HUB_ROOT:-design-hub}"
[[ -n "$QA"  ]] || QA="${INTAKE_QA_RUNNER:-none}"
[[ -n "$NAME" ]] || NAME="${INTAKE_NAME:-}"
[[ -n "$DESIGN_SYSTEM" ]] || DESIGN_SYSTEM="${INTAKE_DESIGN_SYSTEM:-}"

# Prefer a repo-relative path when the skill lives INSIDE the repo (the normal,
# self-contained case). If the skill is outside the repo (a long "../../" chain),
# keep the absolute path — more portable than a fragile upward-escaping relative.
rel_to_pwd() {
  local target="$1" rel
  if command -v python3 >/dev/null 2>&1; then
    rel="$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$target" "$PWD")"
    case "$rel" in
      ../../*) echo "$target";;   # escapes the repo -> use absolute
      *)       echo "$rel";;      # inside the repo -> clean relative
    esac
  else
    echo "$target"                # no python3 -> absolute
  fi
}

# Default impeccable to the bundled copy shipped inside this skill (self-contained).
if [[ -z "$IMPECCABLE" ]]; then
  if [[ -d "$VENDOR_IMPECCABLE" ]]; then
    IMPECCABLE="$(rel_to_pwd "$VENDOR_IMPECCABLE")"
  else
    echo "WARN: bundled vendor/impeccable not found; set --impeccable explicitly." >&2
    IMPECCABLE="vendor/impeccable"
  fi
fi

# ---- derive values --------------------------------------------------------
[[ -n "$NAME" ]] || NAME="$(basename "$PWD")"
[[ -n "$DESIGN_SYSTEM" ]] || DESIGN_SYSTEM="$NAME"
[[ -n "$QA" ]] || QA="none"

# slug: lowercase, spaces/slashes -> dashes, strip other punctuation
SLUG="$(printf '%s' "$NAME" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's#[/[:space:]]+#-#g; s/[^a-z0-9-]//g; s/-+/-/g; s/^-|-$//g')"
[[ -n "$SLUG" ]] || SLUG="project"

PROFILE="$PROFILES_DIR/$SLUG.md"
REGISTRY="$HUB/system/registry.json"

echo "==> lima · first-run init"
echo "    profile name : $NAME"
echo "    design system: $DESIGN_SYSTEM"
echo "    profile file : profiles/$SLUG.md"
echo "    hub root     : $HUB"
echo "    registry     : $REGISTRY"
echo "    impeccable   : $IMPECCABLE"
echo "    qa           : $QA"
[[ "$HAVE_INTAKE" -eq 1 ]] && echo "    intake       : $INTAKE (complete profile)"
echo

# ---- 1. profile -----------------------------------------------------------
# helpers to render fields: from intake if present, else a TODO placeholder.
VIEWPORTS="${INTAKE_VIEWPORTS:-[1440, 1024, 768, 390]}"
SERVE="${INTAKE_SERVE:-python3 -m http.server $HUB_PORT --directory .}"

if [[ -f "$PROFILE" ]]; then
  echo "skip  profile already exists: profiles/$SLUG.md"
elif [[ "$HAVE_INTAKE" -eq 1 ]]; then
  # ---- complete profile from intake (no TODOs) ----------------------------
  {
    echo "# Profile — $NAME"
    echo
    echo "Active profile for this repository. Generated by scripts/init-project.sh from an intake file ($INTAKE)."
    echo
    echo '```yaml'
    echo "name: $NAME"
    echo "design_system: $DESIGN_SYSTEM"
    echo
    echo "truth_sources:"
    if [[ ${#INTAKE_TRUTH[@]} -gt 0 ]]; then
      for t in "${INTAKE_TRUTH[@]}"; do echo "  - $t"; done
    else
      echo "  []   # none provided"
    fi
    echo
    echo "color_law: |"
    printf '%s\n' "${INTAKE_COLOR_LAW:-  # not provided}" | sed 's/^/  /'
    echo
    echo "type_law: |"
    printf '%s\n' "${INTAKE_TYPE_LAW:-  # not provided}" | sed 's/^/  /'
    echo
    echo "hub_root: $HUB"
    echo "hub_layout:"
    echo "  - Foundations/{Color,Type,Icons,Tokens}"
    echo "  - Components"
    echo "  - Patterns"
    echo "  - Responsive/{Mobile,Tablet,Desktop}"
    echo
    echo "registry_path: $REGISTRY"
    echo
    echo "production:"
    echo "  detect: true"
    echo "  known_stack: >"
    echo "    ${INTAKE_STACK:-confirm by inspection}"
    echo "  token_binding: ${INTAKE_TOKEN_BINDING:-Map Hub tokens to the tokens_source file; never hardcode values.}"
    echo "  component_layout: ${INTAKE_COMPONENT_LAYOUT:-match existing naming}"
    echo
    echo "impeccable_path: $IMPECCABLE"
    if [[ "$QA" == "playwright" ]]; then
      echo
      echo "runtime_qa:"
      echo "  enabled: true"
      echo "  runner: playwright"
      echo "  harness_root: $HUB/qa"
      echo "  hub:"
      echo "    start_command: \"$SERVE\""
      echo "    base_url: \"http://localhost:$HUB_PORT\""
      echo "  tests_root: $HUB/qa/tests"
      echo "  evidence_root: $HUB/qa/evidence"
      echo "  viewports: $VIEWPORTS"
    fi
    echo '```'
    echo
    echo "## Notes"
    echo
    echo "- Accessibility target: ${INTAKE_A11Y:-none-stated}. Touch targets >= ${INTAKE_TOUCH:-44}px on mobile; meaning never carried by color alone."
    if [[ -n "$INTAKE_ANTI" ]]; then
      echo "- Anti-references (never reintroduce): $INTAKE_ANTI"
    fi
  } > "$PROFILE"
  echo "make  profiles/$SLUG.md  (from intake — complete, no TODOs)"
else
  # ---- pre-filled profile with TODO markers (no intake) -------------------
  cat > "$PROFILE" <<EOF
# Profile — $NAME

Active profile for this repository. Generated by scripts/init-project.sh.
Fill the TODO fields by inspecting the repo (tokens, mockups) — do not guess.
Tip: pass --intake <file> (reference/intake.md format) to generate a complete profile.

\`\`\`yaml
name: $NAME
design_system: $DESIGN_SYSTEM

truth_sources:            # TODO: point at the files that DEFINE tokens/visual law
  # - path/to/tokens.css
  # - path/to/canonical-mockup.html

color_law: >              # TODO: the system's color rules, briefly
  # e.g. surface/ink, one action color, one focus/accent, one danger; shadow = elevation

type_law: >               # TODO: typography rules
  # e.g. Font A across the system; Font B only for display/brand

hub_root: $HUB
hub_layout:
  - Foundations/{Color,Type,Icons,Tokens}
  - Components
  - Patterns
  - Responsive/{Mobile,Tablet,Desktop}

registry_path: $REGISTRY

production:
  detect: true
  known_stack: >          # TODO: confirm by inspection (framework/language/styling/icons/router)
  token_binding:          # TODO: how Hub tokens map to production tokens (never hardcode values)
  component_layout:       # TODO: where production components live + naming convention

impeccable_path: $IMPECCABLE
EOF

  if [[ "$QA" == "playwright" ]]; then
    cat >> "$PROFILE" <<EOF

runtime_qa:
  enabled: true
  runner: playwright
  harness_root: $HUB/qa
  hub:
    start_command: "python3 -m http.server $HUB_PORT --directory ."
    base_url: "http://localhost:$HUB_PORT"
  tests_root: $HUB/qa/tests
  evidence_root: $HUB/qa/evidence
  viewports: [1440, 1024, 768, 390]
EOF
  fi

  cat >> "$PROFILE" <<'EOF'
```

## Notes

- TODO: record accessibility target (e.g. WCAG AA: contrast, visible focus,
  keyboard, touch targets >=44px, meaning never carried by color alone).
- TODO: list anti-references (deprecated looks/fonts never to reintroduce).
EOF
  echo "make  profiles/$SLUG.md"
fi

# ---- 2. Hub root + taxonomy ----------------------------------------------
mk() { [[ -d "$1" ]] && echo "skip  $1/" || { mkdir -p "$1"; echo "make  $1/"; }; }

mk "$HUB"
mk "$HUB/Foundations"
mk "$HUB/Components"
mk "$HUB/Patterns"
mk "$HUB/Responsive"
mk "$HUB/system"

# ---- 3. empty registry ----------------------------------------------------
if [[ -f "$REGISTRY" ]]; then
  echo "skip  $REGISTRY (exists)"
else
  printf '{}\n' > "$REGISTRY"
  echo "make  $REGISTRY  (empty registry)"
fi

# ---- 4. optional Playwright QA harness ------------------------------------
if [[ "$QA" == "playwright" ]]; then
  QA_DIR="$HUB/qa"
  mk "$QA_DIR"
  mk "$QA_DIR/tests"
  mk "$QA_DIR/evidence"

  if [[ ! -f "$QA_DIR/package.json" ]]; then
    cat > "$QA_DIR/package.json" <<'EOF'
{
  "name": "design-hub-qa",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "playwright test",
    "report": "playwright show-report"
  },
  "devDependencies": {
    "@playwright/test": "^1.47.0"
  }
}
EOF
    echo "make  $QA_DIR/package.json"
  else
    echo "skip  $QA_DIR/package.json (exists)"
  fi

  if [[ ! -f "$QA_DIR/playwright.config.js" ]]; then
    cat > "$QA_DIR/playwright.config.js" <<EOF
// Runtime QA harness for the Design Hub. Serves the Hub statically and runs
// the four mandatory viewports. Generated by init-project.sh; edit freely.
import { defineConfig, devices } from '@playwright/test';

const PORT = process.env.HUB_QA_PORT || '$HUB_PORT';
const BASE_URL = \`http://localhost:\${PORT}\`;

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  fullyParallel: false,
  reporter: [['list'], ['html', { open: 'never' }]],
  webServer: {
    command: \`python3 -m http.server \${PORT} --directory ..\`,
    url: BASE_URL,
    reuseExistingServer: true,
    timeout: 20000,
  },
  use: { baseURL: BASE_URL, screenshot: 'only-on-failure', trace: 'retain-on-failure' },
  projects: [
    { name: 'desktop-1440', use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 900 } } },
    { name: 'desktop-1024', use: { ...devices['Desktop Chrome'], viewport: { width: 1024, height: 800 } } },
    { name: 'tablet-768',   use: { ...devices['Desktop Chrome'], viewport: { width: 768,  height: 900 } } },
    { name: 'mobile-390',   use: { ...devices['Desktop Chrome'], viewport: { width: 390,  height: 780 }, hasTouch: true, isMobile: true } },
  ],
});
EOF
    echo "make  $QA_DIR/playwright.config.js"
  else
    echo "skip  $QA_DIR/playwright.config.js (exists)"
  fi
fi

# ---- next steps -----------------------------------------------------------
echo
echo "==> Done. Next steps:"
echo "  1. Fill the TODO fields in profiles/$SLUG.md (color_law, type_law, truth_sources, production.*)."
if [[ "$QA" == "playwright" ]]; then
  echo "  2. Install QA deps once:"
  echo "       (cd $HUB/qa && npm install && npx playwright install --with-deps chromium)"
fi
echo "  3. Sanity-check the registry:"
echo "       node -e \"JSON.parse(require('fs').readFileSync('$REGISTRY','utf8')); console.log('registry OK')\""
echo "  4. Confirm the profile with the user, then start designing."
