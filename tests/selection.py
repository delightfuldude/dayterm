import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from event_selection import matching_events  # noqa: E402

EVENTS = [
    {
        "uid": "all-day",
        "start-date": "03/08/2026",
        "end-date": "04/08/2026",
        "all-day": "True",
        "title": "Holiday",
    },
    {
        "uid": "timed",
        "start": "03/08/2026 10:00",
        "end": "03/08/2026 11:00",
        "all-day": "False",
        "title": "Meeting",
    },
    {
        "uid": "offset",
        "start": "03/08/2026 11:15",
        "end": "03/08/2026 11:45",
        "all-day": "False",
        "title": "Offset meeting",
    },
]

assert [event["uid"] for event in matching_events(EVENTS, "2026-08-03", -2, 1, "dmy")] == [
    "all-day", "timed", "offset",
]
assert [event["uid"] for event in matching_events(EVENTS, "2026-08-03", -1, 1, "dmy")] == ["all-day"]
assert [event["uid"] for event in matching_events(EVENTS, "2026-08-03", 630, 30, "dmy")] == ["timed"]
assert [event["uid"] for event in matching_events(EVENTS, "2026-08-03", 660, 30, "dmy")] == ["offset"]
assert matching_events(EVENTS, "2026-08-03", 705, 30, "dmy") == []
