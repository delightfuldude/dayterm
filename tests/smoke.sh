#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
status=0

while IFS= read -r file; do
    if ! bash -n "$file"; then
        status=1
    fi
done < <(find "$ROOT" -name '*.sh' -not -path '*/.git/*' | sort)

if "$ROOT/dayterm.sh" --check; then
    "$ROOT/dayterm.sh" --once >/tmp/dayterm-smoke.out || status=1
else
    status=1
fi

if python3 -c 'import wcwidth' >/dev/null 2>&1; then
    DAYTERM_FORCE_COLOR=1 COLUMNS=80 "$ROOT/dayterm.sh" --once >/tmp/dayterm-smoke-color.out || status=1
    python3 - /tmp/dayterm-smoke-color.out 80 <<'PY' || status=1
import re
import sys
from pathlib import Path
from wcwidth import wcswidth

path = Path(sys.argv[1])
width = int(sys.argv[2])
ansi = re.compile(r'\x1b\[[0-9;?]*[ -/]*[@-~]')

for line_number, line in enumerate(path.read_text().splitlines(), 1):
    plain = ansi.sub('', line)
    if plain.startswith(('┌', '│', '└')) and wcswidth(plain) != width:
        print(f'{path}:{line_number}: visible width {wcswidth(plain)} != {width}', file=sys.stderr)
        sys.exit(1)
PY
fi

exit "$status"
