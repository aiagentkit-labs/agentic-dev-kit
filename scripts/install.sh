#!/usr/bin/env bash
# Install the tools agentic-dev-kit skills use (git, az + azure-devops, gh, node) on macOS or Linux.
# Usage: install.sh [--yes]
set -eu

yes=0
if [ "${1:-}" = "--yes" ]; then yes=1; fi
have() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  if [ "$yes" -eq 1 ]; then return 0; fi
  printf '%s [y/N] ' "$1"
  read -r answer
  [ "$answer" = y ] || [ "$answer" = Y ]
}

os="$(uname -s)"
missing=""
have git || missing="$missing git"
have az || missing="$missing az"
have gh || missing="$missing gh"
have node || missing="$missing node"

if [ -n "$missing" ]; then
  echo "Missing:$missing"
  case "$os" in
    Darwin)
      if ! have brew; then
        echo "Homebrew is required: https://brew.sh" >&2
        exit 1
      fi
      formulae=""
      for tool in $missing; do
        case "$tool" in
          az) formulae="$formulae azure-cli" ;;
          *) formulae="$formulae $tool" ;;
        esac
      done
      if confirm "Run: brew install$formulae ?"; then
        # shellcheck disable=SC2086
        brew install $formulae
      fi
      ;;
    Linux)
      for tool in $missing; do
        case "$tool" in
          git | node)
            if have apt-get; then
              pkg="$tool"
              if [ "$tool" = node ]; then pkg=nodejs; fi
              echo "Install $tool with: sudo apt-get install -y $pkg"
            else
              echo "Install $tool with your distribution's package manager."
            fi
            ;;
          az) echo "Install the Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli-linux" ;;
          gh) echo "Install the GitHub CLI: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
        esac
      done
      echo "These need admin rights, so run them yourself, then rerun this script."
      ;;
    *)
      echo "Unsupported OS: $os. On Windows, run install.ps1." >&2
      exit 1
      ;;
  esac
else
  echo "git, az, gh, and node are installed."
fi

if have az && ! az extension show --name azure-devops >/dev/null 2>&1; then
  if confirm "Run: az extension add --name azure-devops ?"; then
    az extension add --name azure-devops
  fi
fi

echo "Sign in yourself where needed: 'az login', 'gh auth login'."
