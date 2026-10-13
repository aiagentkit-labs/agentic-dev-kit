#!/usr/bin/env bash
# Validate override files before they are applied.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
pass=0
fail=0
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

run_case() {
  name="$1"
  want="$2"
  file="$3"
  out="$(bash "$here/validate-overrides.sh" "$file" 2>&1 || true)"
  if [ "$want" = pass ]; then
    if printf '%s\n' "$out" | grep -Eq 'OK|valid'; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $name: expected success"; fi
  else
    if printf '%s\n' "$out" | grep -Eq 'ERROR|invalid|unsupported'; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $name: expected rejection"; fi
  fi
}

cat >"$work/valid.md" <<'EOF'
---
extends: https://github.com/contoso/eng-standards.git#main:testing-controls/testing.md
mode: merge
---

## Controls

| ID | Control | Severity |
|---|---|---|
| A11Y-02 | Scans check WCAG 2.2 level AAA | blocker |
| UI-05 | off: this repo tests its UI with Cypress (ADR-012) | off |

## Instructions

Use the page objects in `tests/pages/` for every UI test.
EOF

cat >"$work/invalid-mode.md" <<'EOF'
---
mode: merge-me
---

## Controls

| ID | Control | Severity |
|---|---|---|
| TST-01 | Example | blocker |
EOF

cat >"$work/invalid-extends.md" <<'EOF'
---
extends: contoso/eng-standards
---

## Controls

| ID | Control | Severity |
|---|---|---|
| TST-01 | Example | blocker |
EOF

cat >"$work/invalid-off.md" <<'EOF'
---
mode: merge
---

## Controls

| ID | Control | Severity |
|---|---|---|
| TST-01 | Example | off |
EOF

run_case valid pass "$work/valid.md"
run_case invalid-mode fail "$work/invalid-mode.md"
run_case invalid-extends fail "$work/invalid-extends.md"
run_case invalid-off fail "$work/invalid-off.md"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
