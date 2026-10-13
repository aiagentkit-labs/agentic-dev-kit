#!/usr/bin/env bash
# Print the layers of one topic's controls: the plugin default, the file the repo override extends, and the repo override.
# Usage: controls.sh <security|privacy|testing|practices|lint> [--ref <base-ref>]   (run from the user's repo root)
set -u

usage="usage: controls.sh <security|privacy|testing|practices|lint> [--ref <base-ref>]"
case "${1:-}" in
  security | privacy) rel="review-controls/$1.md" ;;
  testing) rel="testing-controls/testing.md" ;;
  practices) rel="practice-controls/practices.md" ;;
  lint) rel="lint-controls/lint.md" ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
ref=""
case "${2:-}" in
  "") ;;
  --ref) ref="${3:-}" ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
if [ -z "$ref" ]; then
  ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -z "$ref" ]; then echo "no origin/HEAD; pass --ref origin/<base>" >&2; exit 2; fi
fi

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
repo_path=".github/$rel"

# frontmatter <text> <key>: the value of <key> in the text's leading --- block.
frontmatter() {
  printf '%s\n' "$1" | awk -v key="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    /^---[[:space:]]*$/ { exit }
    $0 ~ "^" key ":" { sub("^" key ":[[:space:]]*", ""); sub(/[[:space:]]+$/, ""); print; exit }'
}

echo "=== layer 1: plugin default ($rel) ==="
cat "$plugin_root/$rel"

repo="$(git show "$ref:$repo_path" 2>/dev/null || true)"
extends=""
if [ -n "$repo" ]; then extends="$(frontmatter "$repo" extends)"; fi

echo
echo "=== layer 2: extends ${extends:-none} ==="
if [ -n "$extends" ]; then
  url="${extends%%#*}"
  rest="${extends#*#}"
  xref="${rest%%:*}"
  xpath="${rest#*:}"
  if [ "$url" = "$extends" ] || [ "$xref" = "$rest" ] || [ -z "$xref" ] || [ -z "$xpath" ]; then
    echo "(not fetched: write extends as <git URL>#<ref>:<path>)"
  else
    case "$url" in
      https://* | ssh://* | git@*)
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        # Fail instead of prompting: the agent's terminal can't answer a credential prompt.
        if GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes}" \
          git clone --quiet --depth 1 --branch "$xref" --filter=blob:none --no-checkout -- "$url" "$tmp/src" 2>"$tmp/err"; then
          if shared="$(git -C "$tmp/src" show "HEAD:$xpath" 2>"$tmp/err")"; then
            printf '%s\n' "$shared"
            if [ -n "$(frontmatter "$shared" extends)" ]; then echo "(its own extends is ignored: one level only)"; fi
          else
            echo "(fetch failed: $xpath not found at $xref)"
          fi
        else
          echo "(fetch failed: $(head -1 "$tmp/err"))"
        fi
        ;;
      *) echo "(not fetched: only https and ssh URLs are allowed)" ;;
    esac
  fi
fi

echo
echo "=== layer 3: repo override ($repo_path at $ref) ==="
if [ -n "$repo" ]; then printf '%s\n' "$repo"; else echo "none"; fi
