from datetime import datetime, timedelta

from dayterm_dates import event_span


def indexed_events(events, order):
    indexed = []
    for event in events:
        start, end, all_day = event_span(event, order)
        if not start:
            continue
        end = end or start
        indexed.append((event, start, end, all_day))
    return indexed


def events_for_day(indexed, day):
    day_start = datetime.combine(day, datetime.min.time())
    day_end = day_start + timedelta(days=1)
    return [item for item in indexed if item[1] < day_end and item[2] > day_start]
