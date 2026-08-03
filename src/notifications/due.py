import hashlib
import json
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SRC))

from dayterm_dates import parse_datetime  # noqa: E402

SEP = "\x1f"


def digest(value):
    return hashlib.sha256(value.encode("utf-8", "replace")).hexdigest()[:24]


def clean(value):
    return str(value or "").replace(SEP, " ").replace("\n", " ").replace("\r", " ")


def seen_keys(path):
    result = set()
    try:
        for line in Path(path).read_text().splitlines():
            parts = line.split("\t", 1)
            if len(parts) == 2:
                result.add(parts[1])
    except OSError:
        pass
    return result


def event_body(prefix, event):
    body = prefix
    if event.get("location"):
        body += f" - {clean(event['location'])}"
    if event.get("calendar"):
        body += f" ({clean(event['calendar'])})"
    return body


def emit(key, base_key, title, body):
    print(SEP.join((key, base_key, clean(title), clean(body))))


def main():
    order, now_text, offsets_text = sys.argv[1:4]
    window, missed_enabled, max_missed_age, max_missed = map(int, sys.argv[4:8])
    seen = seen_keys(sys.argv[8])
    now = int(now_text)
    offsets = [int(value) for value in offsets_text.split() if value.isdigit()]
    try:
        events = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        events = []

    missed_count = 0
    for event in events:
        if str(event.get("all-day", "")).lower() == "true":
            continue
        start = parse_datetime(event.get("start"), order)
        if not start:
            continue
        start_epoch = int(start.timestamp())
        title = event.get("title") or "(no title)"
        identity = f"{event.get('uid') or title}|{event.get('start')}"
        base_key = digest(identity + "|event")
        scheduled = False

        for offset in offsets:
            target = start_epoch - offset * 60
            key = digest(identity + f"|{offset}")
            if target <= now < target + window and key not in seen:
                prefix = "Starts now" if offset == 0 else f"Starts in {offset} min"
                emit(key, base_key, title, event_body(prefix, event))
                seen.update((key, base_key))
                scheduled = True

        age_minutes = (now - start_epoch) // 60
        if (
            missed_enabled
            and not scheduled
            and base_key not in seen
            and 0 < age_minutes <= max_missed_age
            and missed_count < max_missed
        ):
            key = digest(identity + "|missed")
            emit(key, base_key, title, event_body(f"Started {age_minutes} min ago", event))
            seen.update((key, base_key))
            missed_count += 1


if __name__ == "__main__":
    main()
