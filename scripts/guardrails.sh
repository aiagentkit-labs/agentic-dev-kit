#!/usr/bin/env bash
# PreToolUse guardrail: deny destructive or policy-bypassing actions, ask before writes to shared systems.
# Reads the hook payload on stdin; prints a permission decision, or nothing to leave the call alone.
set -u

input="$(cat)"

field() {
  if jq --version >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
  else
    printf '%s' "$input" | tr -d '\n' | sed -nE 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p'
  fi
}

tool="$(field .tool_name tool_name)"
cmd="$(field .tool_input.command command)"

# Top level for the Copilot harness, hookSpecificOutput for VS Code's Local harness and Claude Code.
decide() {
  printf '{"permissionDecision":"%s","permissionDecisionReason":"agentic-dev-kit: %s","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"agentic-dev-kit: %s"}}\n' "$1" "$2" "$1" "$2"
  exit 0
}
has() { printf '%s' "$cmd" | grep -Eq -- "$1"; }
hasi() { printf '%s' "$cmd" | grep -Eiq -- "$1"; }

config_decision() {
  plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
  repo_root="${AGENTIC_DEV_KIT_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  default_config="${AGENTIC_DEV_KIT_GUARDRAILS_DEFAULT_PATH:-$plugin_root/scripts/guardrails.default.yaml}"
  repo_config="${AGENTIC_DEV_KIT_GUARDRAILS_REPO_PATH:-}"
  if [ -z "$repo_config" ]; then
    for candidate in \
      "$repo_root/.github/guardrails/guardrails.yaml" \
      "$repo_root/.github/guardrails/guardrails.yml" \
      "$repo_root/.github/guardrails/config.yaml" \
      "$repo_root/.github/guardrails/config.yml"; do
      if [ -f "$candidate" ]; then repo_config="$candidate"; break; fi
    done
  fi

  result="$(python3 - "$default_config" "$repo_config" "$cmd" <<'PY'
import os
import re
import subprocess
import sys
import tempfile

def parse(path):
    data = {"mode": "merge", "extends": None, "deny": [], "ask": []}
    if not path or not os.path.exists(path):
        return data
    current = None
    invalid = False
    for raw in open(path, encoding="utf-8"):
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or stripped in {"---", "..."}:
            continue
        if stripped.startswith("extends:"):
            spec = stripped.split(":", 1)[1].strip().strip("\"'")
            if not spec or "#" not in spec:
                invalid = True
            else:
                full_url, rest = spec.split("#", 1)
                if not full_url or ":" not in rest:
                    invalid = True
                else:
                    ref, file_path = rest.split(":", 1)
                    if not ref or not file_path:
                        invalid = True
                    else:
                        data["extends"] = spec
            continue
        if stripped.startswith("mode:"):
            mode = stripped.split(":", 1)[1].strip().strip("\"'")
            if mode in {"merge", "replace"}:
                data["mode"] = mode
            else:
                invalid = True
            continue
        if stripped in {"deny:", "ask:", "allow:"}:
            current = stripped[:-1]
            continue
        if stripped.startswith("- ") and current:
            item = stripped[2:].strip().strip("\"'")
            if item:
                data.setdefault(current, []).append(item)
            continue
        if stripped.startswith("-") and current:
            invalid = True
            continue
        if stripped and not stripped.startswith("#"):
            if current is None:
                invalid = True
    if invalid:
        return {"mode": "merge", "extends": None, "deny": [], "ask": []}
    return data


def fetch_shared(spec):
    if not spec or "#" not in spec:
        return None
    full_url, rest = spec.split("#", 1)
    if ":" not in rest:
        return None
    ref, path = rest.split(":", 1)
    if not full_url or not ref or not path:
        return None
    tmp = tempfile.mkdtemp(prefix="guardrails-")
    clone = subprocess.run(
        [
            "git",
            "clone",
            "--quiet",
            "--depth",
            "1",
            "--branch",
            ref,
            "--filter=blob:none",
            "--no-checkout",
            full_url,
            os.path.join(tmp, "src"),
        ],
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0", "GIT_SSH_COMMAND": os.environ.get("GIT_SSH_COMMAND", "ssh -o BatchMode=yes")},
        capture_output=True,
        text=True,
    )
    if clone.returncode != 0:
        return None
    candidate = os.path.join(tmp, "src", path)
    if not os.path.exists(candidate):
        return None
    return candidate


def merge(base, extra, mode):
    merged = {"deny": list(base.get("deny", [])), "ask": list(base.get("ask", []))}
    if mode == "replace":
        merged = {"deny": [], "ask": []}
    for key in ("deny", "ask"):
        for item in extra.get(key, []):
            if item not in merged[key]:
                merged[key].append(item)
    return merged


def effective_rules(default_path, repo_path, cmd):
    config = parse(default_path)
    if repo_path and os.path.exists(repo_path):
        repo_cfg = parse(repo_path)
        shared_path = fetch_shared(repo_cfg.get("extends"))
        if shared_path:
            shared_cfg = parse(shared_path)
            config = merge(config, shared_cfg, "merge")
        config = merge(config, repo_cfg, repo_cfg.get("mode", "merge"))
    for key in ("deny", "ask"):
        for rule in config.get(key, []):
            if re.search(rule, cmd, re.IGNORECASE):
                return f"{key}\t{rule}"
    return ""

print(effective_rules(sys.argv[1], sys.argv[2], sys.argv[3]))
PY
)"
  if [ -n "$result" ]; then
    decision="${result%%$'\t'*}"
    pattern="${result#*$'\t'}"
    case "$decision" in
      deny) decide deny "custom guardrail rule matched: $pattern" ;;
      ask) decide ask "custom guardrail rule matched: $pattern" ;;
    esac
  fi
}

config_decision

# Start of a command: line start or after a separator, so "legit push" never matches "git push".
B='(^|[;&|(`[:space:]])'

if printf '%s' "$tool" | grep -Eq '(repo_pull_request_write|repo_pull_request_thread_write|repo_create_branch|wit_work_item_write|wit_work_item_comment_write|wit_work_item_link_write|wit_work_item_attachment_upload|wit_work_item_attachment_link|pipelines_write|work_iteration_write|work_capacity_write|wiki_upsert_page|testplan_[a-z_]*_write)'; then
  if printf '%s' "$input" | grep -Eiq '"bypass[a-z]*"[[:space:]]*:[[:space:]]*true'; then
    decide deny "bypassing branch policies is blocked."
  fi
  decide ask "this writes to Azure DevOps."
fi

[ -n "$cmd" ] || exit 0

has "${B}git[[:space:]]+push[^;&|]*[[:space:]](--force|-f)([[:space:];&|]|$)" &&
  decide deny "force push is blocked; use --force-with-lease on your own feature branch."
has "${B}git[[:space:]]+push[^;&|]*[[:space:]]\+[^[:space:]]" &&
  decide deny "force push via +refspec is blocked."
has "${B}git[[:space:]]+push[^;&|]*[[:space:]:](main|master|develop|release/[^[:space:];&|]+)([[:space:];&|]|$)" &&
  decide deny "pushing directly to a protected branch is blocked; open a pull request."
has "${B}git[[:space:]]+reset[^;&|]*--hard" &&
  decide deny "git reset --hard discards work and is blocked."
has "${B}git[[:space:]]+clean[^;&|]*[[:space:]](-[a-zA-Z]*f|--force)" &&
  decide deny "git clean -f deletes untracked files and is blocked."
has "${B}git[[:space:]]+branch[^;&|]*[[:space:]]-[a-zA-Z]*D([[:space:];&|]|$)" &&
  decide deny "force-deleting a branch is blocked."
has "${B}git[[:space:]]+(checkout|restore)[^;&|]*[[:space:]]\.([[:space:];&|]|$)" &&
  decide deny "discarding all working-tree changes is blocked."
has "${B}git[[:space:]]+stash[[:space:]]+(drop|clear)" &&
  decide deny "dropping stashes is blocked."
has "${B}git[[:space:]][^;&|]*--no-verify" &&
  decide deny "skipping git hooks with --no-verify is blocked."
has "--bypass-policy" &&
  decide deny "bypassing branch policies is blocked."

if has "${B}rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive)"; then
  has '^rm[[:space:]]+-[a-zA-Z]+[[:space:]]+"?[^[:space:];&|]*\.git/agentic-dev-kit[^[:space:];&|]*"?[[:space:]]*$' && exit 0
  decide ask "recursive delete; confirm the target."
fi

has "${B}git[[:space:]]+push" &&
  decide ask "this pushes to a shared remote."
has "${B}gh[[:space:]]+pr[[:space:]]+(create|merge|review|comment|close|reopen|edit|ready)" &&
  decide ask "this writes to a GitHub pull request."
if has "${B}gh[[:space:]]+api"; then
  hasi "(-X|--method)[[:space:]=]*(POST|PATCH|PUT|DELETE)" && decide ask "this writes through the GitHub API."
  has "mutation" && decide ask "this runs a GitHub GraphQL mutation."
  has "graphql" || { has "[[:space:]](-f|-F|--field|--raw-field|--input)[[:space:]]" && decide ask "this writes through the GitHub API."; }
fi
has "${B}az[[:space:]]+repos[[:space:]]+policy[[:space:]]+[a-z-]+[[:space:]]+(create|update|delete)" &&
  decide ask "this changes branch policies."
has "${B}az[[:space:]]+repos[[:space:]]+pr[[:space:]]+(create|update|set-vote|reviewer[[:space:]]+(add|remove)|work-item[[:space:]]+(add|remove))" &&
  decide ask "this writes to an Azure Repos pull request."
has "${B}az[[:space:]]+boards[[:space:]]+work-item[[:space:]]+(create|update|delete|relation[[:space:]]+(add|remove))" &&
  decide ask "this writes to Azure Boards."
hasi "${B}az[[:space:]]+devops[[:space:]]+invoke[^;&|]*--http-method[[:space:]=]+(POST|PATCH|PUT|DELETE)" &&
  decide ask "this writes through the Azure DevOps REST API."

exit 0
