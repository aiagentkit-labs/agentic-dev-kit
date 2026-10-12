#!/usr/bin/env bash
# Table tests for guardrails.sh: each case is "<expected> <tool> <command>"; expected is deny, ask, or none.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
pass=0
fail=0

run() {
  expected="$1" tool="$2" cmd="$3"
  case "$tool" in
    mcp_*) payload="$(printf '{"tool_name":"%s","tool_input":%s}' "$tool" "$cmd")" ;;
    *) payload="$(printf '{"tool_name":"%s","tool_input":{"command":"%s"}}' "$tool" "$(printf '%s' "$cmd" | sed 's/\\/\\\\/g; s/"/\\"/g')")" ;;
  esac
  out="$(printf '%s' "$payload" | PATH="$GUARD_PATH" bash "$here/guardrails.sh")"
  got="$(printf '%s' "$out" | sed -nE 's/.*"permissionDecision":"([a-z]+)".*/\1/p')"
  [ -n "$got" ] || got=none
  if [ "$got" = "$expected" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL want=$expected got=$got :: $tool :: $cmd"; fi
}

cases() {
  run deny  run_in_terminal 'git push --force origin feat/1-x'
  run deny  run_in_terminal 'git push -f'
  run deny  run_in_terminal 'git push origin +feat/1-x'
  run deny  run_in_terminal 'git push -u origin main'
  run deny  run_in_terminal 'git push origin HEAD:release/2.1'
  run deny  run_in_terminal 'git fetch && git reset --hard origin/main'
  run deny  run_in_terminal 'git clean -fd'
  run deny  run_in_terminal 'git branch -D feat/1-x'
  run deny  run_in_terminal 'git checkout .'
  run deny  run_in_terminal 'git restore .'
  run deny  run_in_terminal 'git stash drop'
  run deny  run_in_terminal 'git commit -m "x" --no-verify'
  run deny  run_in_terminal 'az repos pr update --id 4 --bypass-policy true'
  run deny  mcp_ado_repo_pull_request_write '{"bypassPolicy": true}'
  run ask   run_in_terminal 'git push -u origin feat/1234-login'
  run ask   run_in_terminal 'git push --force-with-lease origin feat/1234-login'
  run ask   run_in_terminal 'gh pr create --base main --title x --body-file .git/agentic-dev-kit/tmp/pr-body.md'
  run ask   run_in_terminal 'gh api repos/o/r/pulls/3/reviews --method POST --input .git/agentic-dev-kit/tmp/review.json'
  run ask   run_in_terminal 'gh api repos/o/r/pulls/3/comments/9/replies -f body=done'
  run ask   run_in_terminal "gh api graphql -f query='mutation { resolveReviewThread(input:{threadId:\"x\"}) { thread { id } } }'"
  run ask   run_in_terminal 'az repos pr create --source-branch feat/1 --target-branch main'
  run ask   run_in_terminal 'az repos pr set-vote --id 4 --vote approve'
  run ask   run_in_terminal 'az devops invoke --area git --resource pullRequestThreads --http-method POST --in-file t.json'
  run ask   run_in_terminal 'rm -rf node_modules'
  run ask   mcp_ado_wit_work_item_write '{}'
  run ask   mcp_ado_repo_pull_request_thread_write '{}'
  run none  run_in_terminal 'rm -rf .git/agentic-dev-kit/tmp'
  run none  run_in_terminal 'git status && git diff origin/main...HEAD'
  run none  run_in_terminal 'git switch -c feat/1-x origin/main'
  run none  run_in_terminal 'git fetch origin main'
  run none  run_in_terminal 'git commit -m "push to main later"'
  run none  run_in_terminal 'echo legit push'
  run none  run_in_terminal 'git branch -d feat/merged'
  run none  run_in_terminal 'git checkout ./src/app.ts'
  run none  run_in_terminal 'gh pr view 3 --json comments,reviews'
  run none  run_in_terminal "gh api graphql -F n=3 -f query='query { viewer { login } }'"
  run none  run_in_terminal 'gh api repos/o/r/pulls/3'
  run none  run_in_terminal 'az repos pr list --reviewer me --status active'
  run none  run_in_terminal 'az devops invoke --area git --resource pullRequestThreads --http-method GET'
  run none  mcp_ado_wit_work_item '{}'
  run none  mcp_ado_repo_pull_request '{}'
  run none  read_file ''
}

GUARD_PATH="$PATH"
cases

# Again without jq: shadow it with a jq that always fails.
no_jq="$(mktemp -d)"
printf '#!/bin/sh\nexit 127\n' >"$no_jq/jq"
chmod +x "$no_jq/jq"
GUARD_PATH="$no_jq:$PATH"
cases
rm -r "$no_jq"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
