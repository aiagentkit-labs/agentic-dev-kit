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

shared_repo="$(mktemp -d)"
git init --initial-branch=main "$shared_repo" >/dev/null 2>&1
cat >"$shared_repo/guardrails.yml" <<'EOF'
mode: merge
deny:
  - git push --force-with-lease
ask:
  - gh pr review
EOF
git -C "$shared_repo" config user.name 'Test User'
git -C "$shared_repo" config user.email 'test@example.com'
git -C "$shared_repo" add guardrails.yml
git -C "$shared_repo" commit -m 'shared guardrails' >/dev/null

cat >"$work/repo-extends.yaml" <<EOF
extends: $shared_repo#main:guardrails.yml
mode: merge
ask:
  - gh pr create
EOF

cat >"$work/repo-invalid-mode.yaml" <<'EOF'
mode: not-valid
deny:
  - git push origin feat/x
EOF

payload() {
  local tool="$1" cmd="$2"
  printf '{"tool_name":"%s","tool_input":{"command":"%s"}}' "$tool" "$(printf '%s' "$cmd" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

run_case() {
  local name="$1" expected="$2" cmd="$3" repo_path="${4:-$work/repo.yaml}"
  local payload_json out got
  payload_json="$(payload run_in_terminal "$cmd")"
  out="$(AGENTIC_DEV_KIT_REPO_ROOT="$work" AGENTIC_DEV_KIT_GUARDRAILS_DEFAULT_PATH="$work/default.yaml" AGENTIC_DEV_KIT_GUARDRAILS_REPO_PATH="$repo_path" PAYLOAD="$payload_json" bash -c 'printf "%s" "$PAYLOAD" | bash "$0"' "$here/guardrails.sh")"
  got="$(printf '%s' "$out" | sed -nE 's/.*"permissionDecision":"([a-z]+)".*/\1/p' | head -n 1)"
  [ -n "$got" ] || got=none
  if [ "$got" = "$expected" ]; then
    echo "PASS $name -> $got"
  else
    echo "FAIL $name expected=$expected got=$got :: $cmd"
    exit 1
  fi
}

run_case repo_override_ask ask 'gh pr create --base main --title x --body-file body.md' "$work/repo.yaml"
run_case repo_override_deny deny 'git push --force-with-lease origin feat/x' "$work/repo.yaml"
run_case repo_override_clean deny 'git clean -fd' "$work/repo.yaml"
run_case repo_extends_shared_deny deny 'git push --force-with-lease origin feat/x' "$work/repo-extends.yaml"
run_case repo_extends_shared_ask ask 'gh pr review --repo org/project 5' "$work/repo-extends.yaml"
run_case repo_invalid_mode_ignored ask 'git push origin feat/x' "$work/repo-invalid-mode.yaml"

loader_out="$(python3 "$here/policy_loader.py" --default "$work/default.yaml" --repo "$work/repo-extends.yaml" --command 'gh pr review --repo org/project 5' 2>/dev/null || true)"
if printf '%s' "$loader_out" | grep -Eq 'ask\tgh pr review'; then
  echo 'PASS policy_loader_shared_extends -> ask'
else
  echo "FAIL policy_loader_shared_extends expected ask got: $loader_out"
  exit 1
fi

registry_out="$(python3 "$here/policy_registry.py" --list 2>/dev/null || true)"
if printf '%s' "$registry_out" | grep -Eq 'security.*privacy.*testing.*practices.*lint'; then
  echo 'PASS policy_registry_list -> topics'
else
  echo "FAIL policy_registry_list expected topic list got: $registry_out"
  exit 1
fi

shared_fetch_out="$(python3 "$here/policy_loader.py" --fetch-shared "$shared_repo#main:guardrails.yml" 2>/dev/null || true)"
if printf '%s' "$shared_fetch_out" | grep -Eq 'gh pr review'; then
  echo 'PASS policy_loader_fetch_shared -> content'
else
  echo "FAIL policy_loader_fetch_shared expected shared content got: $shared_fetch_out"
  exit 1
fi

cat >"$work/valid-override.md" <<'EOF'
---
extends: https://github.com/contoso/eng-standards.git#main:testing-controls/testing.md
mode: merge
---

## Controls

| ID | Control | Severity |
|---|---|---|
| A11Y-02 | Scans check WCAG 2.2 level AAA | blocker |
| UI-05 | off: repo tests UI with Cypress (ADR-012) | off |

## Instructions

Use the page objects in `tests/pages/` for every UI test.
EOF

validate_out="$(python3 "$here/policy_loader.py" --validate "$work/valid-override.md" 2>/dev/null || true)"
if printf '%s' "$validate_out" | grep -Eq 'OK: valid override file'; then
  echo 'PASS policy_loader_validate_override -> ok'
else
  echo "FAIL policy_loader_validate_override expected valid override got: $validate_out"
  exit 1
fi

echo 'guardrails-config tests passed'
