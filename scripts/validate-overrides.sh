#!/usr/bin/env bash
# Validate an override file before it is applied to default controls.
# Usage: validate-overrides.sh <path-to-override.md>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "ERROR: usage: $0 <path-to-override.md>" >&2
  exit 2
fi

file="$1"
if [ ! -f "$file" ]; then
  echo "ERROR: file not found: $file" >&2
  exit 2
fi

python3 "$(dirname "$0")/policy_loader.py" --validate "$file" 2>&1 || exit 1
