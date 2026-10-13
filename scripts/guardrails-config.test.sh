#!/usr/bin/env bash
# Tests for config-driven extensibility in guardrails.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat >"$work/default.yaml" <<'EOF'
deny:
  - git push --force
  - git reset --hard
ask:
  - git push
EOF

cat >"$work/repo.yaml" <<'EOF'
mode: merge
ask:
  - gh pr create
deny:
  - git push --force-with-lease
  - git clean -fd
EOF

payload() {
  local tool="$1" cmd="$2"
  printf '{"tool_name":"%s","tool_input":{"command":"%s"}}' "$tool" "$(printf '%s' "$cmd" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

run_case() {
  local name="$1" expected="$2" cmd="$3"
  local payload_json out got
  payload_json="$(payload run_in_terminal "$cmd")"
  out="$(AGENTIC_DEV_KIT_REPO_ROOT="$work" AGENTIC_DEV_KIT_GUARDRAILS_DEFAULT_PATH="$work/default.yaml" AGENTIC_DEV_KIT_GUARDRAILS_REPO_PATH="$work/repo.yaml" PAYLOAD="$payload_json" bash -c 'printf "%s" "$PAYLOAD" | bash "$0"' "$here/guardrails.sh")"
  got="$(printf '%s' "$out" | sed -nE 's/.*"permissionDecision":"([a-z]+)".*/\1/p' | head -n 1)"
  [ -n "$got" ] || got=none
  if [ "$got" = "$expected" ]; then
    echo "PASS $name -> $got"
  else
    echo "FAIL $name expected=$expected got=$got :: $cmd"
    exit 1
  fi
}

run_case repo_override_ask ask 'gh pr create --base main --title x --body-file body.md'
run_case repo_override_deny deny 'git push --force-with-lease origin feat/x'
run_case repo_override_clean deny 'git clean -fd'

echo 'guardrails-config tests passed'
