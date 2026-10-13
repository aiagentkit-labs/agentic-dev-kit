#!/usr/bin/env bash
# The `extends` fetch contract (CONTROLS.md), checked against both implementations: policy_loader.py and controls.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
pass=0
fail=0
ok() { pass=$((pass + 1)); echo "PASS $1"; }
bad() { fail=$((fail + 1)); echo "FAIL $1: $2"; }

shared="$work/shared"
git init --quiet --initial-branch=main "$shared"
git -C "$shared" config user.name test
git -C "$shared" config user.email test@example.com
mkdir -p "$shared/testing-controls"
cat >"$shared/testing-controls/testing.md" <<'EOF'
---
extends: https://example.invalid/other.git#main:testing.md
---

## Controls

| ID | Control | Severity |
|---|---|---|
| ORG-01 | Shared org control | blocker |
EOF
git -C "$shared" add -A
git -C "$shared" commit --quiet -m shared

# Reach the local repo through an https URL, as a real standards repo would be.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$shared.insteadOf" GIT_CONFIG_VALUE_0="https://example.invalid/shared.git"
good="https://example.invalid/shared.git#main:testing-controls/testing.md"

cat >"$work/evil.sh" <<EOF
#!/bin/sh
touch "$work/pwned"
EOF
chmod +x "$work/evil.sh"

mkdir -p "$work/tmp"
out="$(TMPDIR="$work/tmp" python3 "$here/policy_loader.py" --fetch-shared "$good" 2>&1)"
if printf '%s' "$out" | grep -q 'ORG-01'; then ok loader_fetches_https; else bad loader_fetches_https "$out"; fi
if [ -z "$(ls -A "$work/tmp")" ]; then ok loader_cleans_temp; else bad loader_cleans_temp "left: $(ls -A "$work/tmp")"; fi

out="$(python3 "$here/policy_loader.py" --fetch-shared "https://example.invalid/shared.git#main:nope.md" 2>&1)"
code=$?
if [ "$code" -ne 0 ] && printf '%s' "$out" | grep -q 'ERROR:.*not found'; then ok loader_reports_missing_path; else bad loader_reports_missing_path "exit=$code $out"; fi

consumer="$work/consumer"
git init --quiet --initial-branch=main "$consumer"
git -C "$consumer" config user.name test
git -C "$consumer" config user.email test@example.com
mkdir -p "$consumer/.github/testing-controls"

controls_layer2() {
  cat >"$consumer/.github/testing-controls/testing.md" <<EOF
---
extends: $1
---

## Controls

| ID | Control | Severity |
|---|---|---|
| TST-01 | Repo control | blocker |
EOF
  git -C "$consumer" add -A
  git -C "$consumer" commit --quiet --allow-empty -m override
  (cd "$consumer" && bash "$here/controls.sh" testing --ref main 2>&1) | sed -n '/=== layer 2/,/=== layer 3/p'
}

out="$(controls_layer2 "$good")"
if printf '%s' "$out" | grep -q 'ORG-01' && printf '%s' "$out" | grep -q 'one level only'; then ok controls_fetches_https; else bad controls_fetches_https "$out"; fi

# Each spec: name, extends value, whether the contract fetches it.
while IFS='|' read -r name spec want; do
  layer2="$(controls_layer2 "$spec")"
  if printf '%s' "$layer2" | grep -q 'ORG-01'; then by_controls=fetch; else by_controls=refuse; fi
  if python3 "$here/policy_loader.py" --fetch-shared "$spec" >/dev/null 2>&1; then by_loader=fetch; else by_loader=refuse; fi
  if [ "$by_controls" = "$want" ] && [ "$by_loader" = "$want" ]; then
    ok "contract_$name -> $want"
  else
    bad "contract_$name" "want=$want controls=$by_controls loader=$by_loader"
  fi
done <<EOF
https|$good|fetch
local_path|$shared#main:testing-controls/testing.md|refuse
file_url|file://$shared#main:testing-controls/testing.md|refuse
option_injection|--upload-pack=$work/evil.sh#main:testing-controls/testing.md|refuse
missing_ref|https://example.invalid/shared.git#nope:testing-controls/testing.md|refuse
missing_path|https://example.invalid/shared.git#main:nope.md|refuse
no_ref|https://example.invalid/shared.git|refuse
EOF

if [ -e "$work/pwned" ]; then bad no_option_injection "evil.sh ran"; else ok no_option_injection; fi

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
