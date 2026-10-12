#!/usr/bin/env bash
# Preflight and postflight checks for agentic-dev-kit skills; run from the user's repo root.
# Usage: check.sh pre|post <ado-implement|pr-review|branch-policies> [--skip git,az,gh,node]
set -u

phase="${1:-}"
skill="${2:-}"
usage="usage: check.sh pre|post <ado-implement|pr-review|branch-policies> [--skip git,az,gh,node]"
case "$phase" in pre|post) ;; *) echo "$usage" >&2; exit 2 ;; esac
case "$skill" in ado-implement|pr-review|branch-policies) ;; *) echo "unknown skill: $skill" >&2; exit 2 ;; esac
skip=""
case "${3:-}" in
  "") ;;
  --skip) skip="$(printf '%s' "${4:-}" | tr -d ' ')" ;;
  *) echo "$usage" >&2; exit 2 ;;
esac

fails=0
report() {
  printf '%-5s %-28s %s\n' "$1" "$2" "${3:-}"
  if [ "$1" = FAIL ]; then fails=$((fails + 1)); fi
}
have() { command -v "$1" >/dev/null 2>&1; }
# skipped <id> <label>: report SKIP and succeed when the user chose to skip check <id>.
skipped() {
  case ",$skip," in
    *",$1,"*) report SKIP "$2" "skipped by the user"; return 0 ;;
  esac
  return 1
}

if ! have git; then report FAIL "git" "not installed; run install.sh"; exit 1; fi
if ! git rev-parse --git-dir >/dev/null 2>&1; then report FAIL "git repository" "run from inside a git work tree"; exit 1; fi

state_dir="$(git rev-parse --absolute-git-dir)/agentic-dev-kit"
remote_url="$(git remote get-url origin 2>/dev/null || true)"
case "$remote_url" in
  *github.com*) host=github ;;
  *dev.azure.com* | *visualstudio.com*) host=azure-repos ;;
  *) host=unknown ;;
esac

pre() {
  ver="$(git --version | awk '{print $3}')"
  major="${ver%%.*}"
  rest="${ver#*.}"
  minor="${rest%%.*}"
  if skipped git "git $ver"; then :
  elif [ "$major" -gt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -ge 23 ]; }; then
    report PASS "git $ver"
  else
    report FAIL "git $ver" "need 2.23+ for 'git switch'; run install.sh"
  fi

  if [ "$host" = unknown ]; then
    report WARN "origin remote" "not Azure Repos or GitHub; PR steps will need manual help"
  else
    report PASS "origin: $host"
  fi

  if skipped az "az CLI"; then :
  elif have az; then
    if az extension show --name azure-devops >/dev/null 2>&1; then
      report PASS "az + azure-devops"
    else
      report WARN "azure-devops extension" "az extension add --name azure-devops"
    fi
    if az account show >/dev/null 2>&1; then
      report PASS "az login"
    else
      report WARN "az login" "run 'az login' in your own terminal (CLI fallback only)"
    fi
  else
    report WARN "az CLI" "needed only when the ADO MCP server can't sign in; run install.sh"
  fi

  if [ "$host" = github ] && ! skipped gh "gh CLI"; then
    gh_path="$(command -v gh 2>/dev/null || true)"
    if [ -z "$gh_path" ]; then
      report FAIL "gh CLI" "needed for GitHub PRs; run install.sh"
    elif ! gh --version >/dev/null 2>&1; then
      hint="$gh_path won't run in this session"
      if [ "$(uname)" = Darwin ] && ! file -bL "$gh_path" | grep -q "$(uname -m)"; then
        hint="$hint: it's built for another CPU than $(uname -m)"
      fi
      report FAIL "gh CLI" "$hint. If gh works in your terminal, restart VS Code so it reloads PATH; otherwise reinstall gh"
    elif ! gh auth status >/dev/null 2>&1; then
      report FAIL "gh auth" "run 'gh auth login' in your own terminal"
    else
      report PASS "gh + auth"
    fi
  fi

  if [ "$skill" = ado-implement ] && [ -f package.json ] && ! skipped node "node / npx"; then
    if have node && have npx; then
      report PASS "node $(node --version)"
    else
      report WARN "node / npx" "needed for Playwright and axe tests; run install.sh"
    fi
  fi

  if [ -n "$(git status --porcelain)" ]; then
    report WARN "working tree dirty" "the skill will ask to stash, commit, or stop"
  else
    report PASS "working tree clean"
  fi

  mkdir -p "$state_dir/tmp"
  {
    echo "skill=$skill"
    echo "start_branch=$(git symbolic-ref --quiet --short HEAD || git rev-parse HEAD)"
    echo "stash_count=$(git stash list | wc -l | tr -d ' ')"
    echo "skipped=$skip"
  } >"$state_dir/state"
  report PASS "state recorded" "$state_dir"
}

post() {
  state="$state_dir/state"
  if [ ! -f "$state" ]; then
    report FAIL "preflight state" "run 'check.sh pre $skill' first"
    return
  fi
  start_branch="$(sed -n 's/^start_branch=//p' "$state")"
  stash_count="$(sed -n 's/^stash_count=//p' "$state")"
  branch="$(git symbolic-ref --quiet --short HEAD || echo DETACHED)"

  if [ -z "$(git status --porcelain)" ]; then
    report PASS "working tree clean"
  else
    report WARN "working tree dirty" "$(git status --porcelain | wc -l | tr -d ' ') path(s) uncommitted"
  fi

  now_stash="$(git stash list | wc -l | tr -d ' ')"
  if [ "$now_stash" -gt "$stash_count" ]; then
    report FAIL "stash" "$((now_stash - stash_count)) stash(es) left behind; restore with 'git stash pop'"
  else
    report PASS "stash restored"
  fi

  case "$skill" in
    pr-review | branch-policies)
      if [ "$branch" = "$start_branch" ]; then
        report PASS "back on $start_branch"
      else
        report FAIL "branch" "on $branch; the user started on $start_branch"
      fi
      ;;
    ado-implement)
      if [ "$branch" = DETACHED ]; then
        report FAIL "branch" "detached HEAD"
      elif ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
        report WARN "upstream" "$branch is not pushed"
      else
        ahead="$(git rev-list --count '@{u}..HEAD')"
        if [ "$ahead" -eq 0 ]; then
          report PASS "$branch pushed"
        else
          report WARN "upstream" "$ahead commit(s) not pushed"
        fi
      fi
      ;;
  esac

  # Keep state on failure so the check can be rerun after fixing.
  if [ "$fails" -eq 0 ]; then
    rm -rf "$state_dir"
    report PASS "temp files removed"
  fi
}

"$phase"
[ "$fails" -eq 0 ]
