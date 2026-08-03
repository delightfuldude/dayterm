import json
import sys
from datetime import date, datetime, timedelta

from dayterm_dates import event_span


def matching_events(events, selected_text, cursor_minutes, cursor_step, order):
    selected = date.fromisoformat(selected_text)
    day_start = datetime.combine(selected, datetime.min.time())
    day_end = day_start + timedelta(days=1)
    slot_start = day_start + timedelta(minutes=max(0, cursor_minutes))
    slot_end = slot_start + timedelta(minutes=max(1, cursor_step))
    matches = []
    for event in events:
        start, end, all_day = event_span(event, order)
        if not start or start >= day_end or end <= day_start:
            continue
        if cursor_minutes == -2:
            matches.append(event)
        elif cursor_minutes < 0 and all_day:
            matches.append(event)
        elif cursor_minutes >= 0 and not all_day and start < slot_end and end > slot_start:
            matches.append(event)
    return matches


def main():
    order, selected_text, cursor_text, step_text = sys.argv[1:5]
    try:
        events = json.load(sys.stdin)
    except (OSError, json.JSONDecodeError):
        events = []
    json.dump(matching_events(events, selected_text, int(cursor_text), int(step_text), order), sys.stdout)


if __name__ == "__main__":
    main()
