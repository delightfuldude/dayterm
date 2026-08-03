#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
status=0
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

while IFS= read -r file; do
    if ! bash -n "$file"; then
        status=1
    fi
done < <(find "$ROOT" -name '*.sh' -not -path '*/.git/*' | sort)

if "$ROOT/dayterm.sh" --check; then
    "$ROOT/dayterm.sh" --once >"$TEST_DIR/agenda.out" || status=1
else
    status=1
fi

bash "$ROOT/tests/notifications.sh" || status=1
bash "$ROOT/tests/view.sh" || status=1
bash "$ROOT/tests/calendar_query.sh" || status=1
python3 "$ROOT/tests/dates.py" || status=1

if "$ROOT/dayterm.sh" --once --view invalid > /dev/null 2>&1; then
    printf 'invalid view was accepted\n' >&2
    status=1
fi

if "$ROOT/dayterm.sh" --once --date 2026-99-99 > /dev/null 2>&1; then
    printf 'invalid date was accepted\n' >&2
    status=1
fi

if python3 -c 'import wcwidth' >/dev/null 2>&1; then
    for view in agenda week month tasks; do
        output="$TEST_DIR/$view.out"
        DAYTERM_FORCE_COLOR=1 COLUMNS=80 "$ROOT/dayterm.sh" --once --view "$view" > "$output" || status=1
        python3 - "$output" 80 <<'PY' || status=1
import re
import sys
from pathlib import Path
from wcwidth import wcswidth

path = Path(sys.argv[1])
width = int(sys.argv[2])
ansi = re.compile(r'\x1b\[[0-9;?]*[ -/]*[@-~]')

for line_number, line in enumerate(path.read_text().splitlines(), 1):
    if r'\033' in line:
        print(f'{path}:{line_number}: literal ANSI escape found', file=sys.stderr)
        sys.exit(1)
    plain = ansi.sub('', line)
    if plain.startswith(('┌', '│', '└')) and wcswidth(plain) != width:
        print(f'{path}:{line_number}: visible width {wcswidth(plain)} != {width}', file=sys.stderr)
        sys.exit(1)
PY
    done
fi

exit "$status"
