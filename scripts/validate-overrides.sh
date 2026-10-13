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

python3 - "$file" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

if not text.strip():
    raise SystemExit("ERROR: override file is empty")

body = text
frontmatter = {}
if text.startswith('---\n'):
    match = re.match(r'^---\n(.*?)\n---\n', text, re.S)
    if not match:
        raise SystemExit("ERROR: invalid frontmatter delimiter")
    fm_text = match.group(1)
    body = text[match.end():]
    for line in fm_text.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if ':' not in line:
            raise SystemExit(f"ERROR: invalid frontmatter line: {line!r}")
        key, value = [part.strip() for part in line.split(':', 1)]
        if key not in {'extends', 'mode'}:
            raise SystemExit(f"ERROR: unsupported frontmatter key: {key!r}")
        frontmatter[key] = value
else:
    body = text

mode = frontmatter.get('mode', 'merge')
if mode not in {'merge', 'replace'}:
    raise SystemExit(f"ERROR: unsupported mode {mode!r}; use 'merge' or 'replace'")

if 'extends' in frontmatter:
    extends = frontmatter['extends']
    if not re.match(r'^(https://|ssh://|git@)[^\s]+#[^\s:]+:[^\s]+$', extends):
        raise SystemExit(
            "ERROR: invalid extends format; use <git URL>#<ref>:<path> with https, ssh, or git@ URLs"
        )

controls_match = re.search(r'(?ms)^##\s+Controls\s*\n(.*?)(?=\n##\s+|\Z)', body)
if not controls_match:
    raise SystemExit("ERROR: missing ## Controls section")

controls_block = controls_match.group(1)
rows = []
for line in controls_block.splitlines():
    line = line.strip()
    if not line or line.startswith('| ---') or line.startswith('| ID |') or 'Control' in line and 'Severity' in line:
        continue
    if not line.startswith('|'):
        continue
    cells = [c.strip() for c in line.strip().strip('|').split('|')]
    if len(cells) < 3:
        raise SystemExit(f"ERROR: malformed controls row: {line!r}")
    row_id, control, severity = cells[:3]
    rows.append((row_id, control, severity))

if not rows:
    raise SystemExit("ERROR: no control rows found in ## Controls")

valid_severities = {'blocker', 'should-fix', 'nit', 'escalate', 'setup', 'off'}
for row_id, control, severity in rows:
    if not re.fullmatch(r'[A-Z0-9-]+', row_id):
        raise SystemExit(f"ERROR: invalid control ID {row_id!r}")
    if severity not in valid_severities:
        raise SystemExit(f"ERROR: invalid severity {severity!r} for {row_id!r}")
    if severity == 'off' and not control.lower().startswith('off:'):
        raise SystemExit(
            f"ERROR: control {row_id!r} is marked 'off' but the description is missing the required 'off:' reason"
        )

print(f"OK: valid override file: {path}")
PY
