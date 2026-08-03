import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from display.render_week import timeline_slots  # noqa: E402


def starts(cursor):
    return [slot[0] for slot in timeline_slots(7, 20, 4, cursor, 30)]


assert starts(420) == [420, 450, 480, 510]
assert starts(480) == [420, 450, 480, 510]
assert starts(570) == [510, 540, 570, 600]
assert starts(1170) == [1080, 1110, 1140, 1170]
