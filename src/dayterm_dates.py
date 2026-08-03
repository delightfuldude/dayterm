import re
from datetime import datetime, timedelta


def parse_date(value, order="dmy"):
    numbers = [int(part) for part in re.findall(r"\d+", value or "")[:3]]
    if len(numbers) != 3:
        return None
    first, second, third = numbers
    if order == "ymd":
        year, month, day = first, second, third
    elif order == "mdy":
        month, day, year = first, second, third
    else:
        day, month, year = first, second, third
    if year < 100:
        year += 2000 if year <= 68 else 1900
    try:
        return datetime(year, month, day).date()
    except ValueError:
        return None


def parse_datetime(value, order="dmy"):
    if not value or " " not in value:
        return None
    date_text, time_text = value.split(" ", 1)
    parsed_date = parse_date(date_text, order)
    match = re.search(r"(\d{1,2}):(\d{2})", time_text)
    if not parsed_date or not match:
        return None
    try:
        return datetime.combine(
            parsed_date,
            datetime.min.time().replace(hour=int(match.group(1)), minute=int(match.group(2))),
        )
    except ValueError:
        return None


def event_span(event, order="dmy"):
    all_day = str(event.get("all-day", "")).lower() == "true"
    if all_day:
        start_date = parse_date(event.get("start-date") or event.get("start"), order)
        end_date = parse_date(event.get("end-date") or event.get("end"), order)
        if not start_date:
            return None, None, True
        end_date = end_date or start_date + timedelta(days=1)
        return datetime.combine(start_date, datetime.min.time()), datetime.combine(end_date, datetime.min.time()), True

    start = parse_datetime(event.get("start"), order)
    end = parse_datetime(event.get("end"), order) or start
    return start, end, False
