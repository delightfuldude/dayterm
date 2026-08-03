import re
import sys
from pathlib import Path

from wcwidth import wcwidth, wcswidth

ANSI = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]")


def cell_positions(line):
    positions = []
    position = 0
    for character in ANSI.sub("", line):
        if character in "│┼":
            positions.append(position)
        position += max(0, wcwidth(character))
    return tuple(positions)


path, section, width_text, rows_text = sys.argv[1:5]
width, expected_rows = int(width_text), int(rows_text)
lines = Path(path).read_text().splitlines()
assert len(lines) == expected_rows, (len(lines), expected_rows)
for line in lines:
    plain = ANSI.sub("", line)
    if plain.startswith(("┌", "│", "└")):
        assert wcswidth(plain) == width, (wcswidth(plain), width, plain)

start = next(index for index, line in enumerate(lines) if ANSI.sub("", line).startswith(f"┌ {section} "))
end = next(index for index in range(start + 1, len(lines)) if ANSI.sub("", lines[index]).startswith("└"))
grid_rows = [cell_positions(line) for line in lines[start + 1 : end] if len(cell_positions(line)) >= 8]
assert grid_rows
expected = set(grid_rows[0])
assert all(expected.issubset(positions) for positions in map(set, grid_rows)), grid_rows
