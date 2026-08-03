import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from dayterm_dates import event_span, parse_date, parse_datetime  # noqa: E402


assert parse_date("31/07/2026", "dmy") == date(2026, 7, 31)
assert parse_date("07/31/2026", "mdy") == date(2026, 7, 31)
assert parse_date("2026-07-31", "ymd") == date(2026, 7, 31)
assert parse_date("31/07/26", "dmy") == date(2026, 7, 31)
assert parse_datetime("31/07/2026 06:30", "dmy").hour == 6

start, end, all_day = event_span(
    {"start-date": "31/07/2026", "end-date": "01/08/2026", "all-day": "True"},
    "dmy",
)
assert all_day
assert start.date() == date(2026, 7, 31)
assert end.date() == date(2026, 8, 1)
