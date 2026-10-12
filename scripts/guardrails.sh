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

decide() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"agentic-dev-kit: %s"}}\n' "$1" "$2"
  exit 0
}
has() { printf '%s' "$cmd" | grep -Eq -- "$1"; }
hasi() { printf '%s' "$cmd" | grep -Eiq -- "$1"; }

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
has "${B}az[[:space:]]+repos[[:space:]]+pr[[:space:]]+(create|update|set-vote|reviewer[[:space:]]+(add|remove)|work-item[[:space:]]+(add|remove))" &&
  decide ask "this writes to an Azure Repos pull request."
has "${B}az[[:space:]]+boards[[:space:]]+work-item[[:space:]]+(create|update|delete|relation[[:space:]]+(add|remove))" &&
  decide ask "this writes to Azure Boards."
hasi "${B}az[[:space:]]+devops[[:space:]]+invoke[^;&|]*--http-method[[:space:]=]+(POST|PATCH|PUT|DELETE)" &&
  decide ask "this writes through the Azure DevOps REST API."

exit 0
