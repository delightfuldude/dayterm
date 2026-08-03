from datetime import date, datetime, timedelta

from display.render_common import grid_line
from display.render_data import events_for_day, indexed_events
from ui.celltext import fit


def week_lines(events, selected_text, order, cols, start_hour, end_hour, c, style):
    selected = date.fromisoformat(selected_text)
    week_start = selected - timedelta(days=selected.weekday())
    days = [week_start + timedelta(days=offset) for offset in range(7)]
    indexed = indexed_events(events, order)
    if cols < 76:
        return compact_week(indexed, days, selected, c)

    inner = max(20, cols - 4)
    separator = "|" if style == "ascii" else "│"
    cell_width = max(4, (inner - 26) // 7)
    headers = []
    for day in days:
        label = day.strftime("%a %d")
        color_name = "key" if day == selected else "due_today" if day == date.today() else "label"
        headers.append(c(color_name, fit(label, cell_width)))
    lines = [f"{'':7}{grid_line(headers, cell_width, separator, c)}"]

    all_day_cells = []
    for day in days:
        items = [item for item in events_for_day(indexed, day) if item[3]]
        label = items[0][0].get("title", "") if items else ""
        if len(items) > 1:
            label += f" +{len(items) - 1}"
        all_day_cells.append(c("calendar", fit(label, cell_width)))
    all_day_label = c("muted", "all day".ljust(7))
    lines.append(f"{all_day_label} {grid_line(all_day_cells, cell_width, separator, c)}")

    for hour in range(start_hour, end_hour):
        cells = [timed_cell(indexed, day, hour, cell_width, c) for day in days]
        lines.append(f"{c('time', f'{hour:02d}:00')}  {grid_line(cells, cell_width, separator, c)}")
    return lines


def timed_cell(indexed, day, hour, width, c):
    slot_start = datetime.combine(day, datetime.min.time()).replace(hour=hour)
    slot_end = slot_start + timedelta(hours=1)
    items = [item for item in indexed if not item[3] and item[1] < slot_end and item[2] > slot_start]
    if not items:
        return ""
    event, start, _, _ = items[0]
    marker = "▌" if start >= slot_start else "│"
    label = f"{marker}{start:%H:%M} {event.get('title') or '(no title)'}"
    if len(items) > 1:
        label += f" +{len(items) - 1}"
    return c("event", fit(label, width))


def compact_week(indexed, days, selected, c):
    lines = []
    for day in days:
        items = events_for_day(indexed, day)
        color_name = "key" if day == selected else "due_today" if day == date.today() else "label"
        lines.append(c(color_name, day.strftime("%a %Y-%m-%d")))
        if not items:
            lines.append(f"  {c('muted', 'No events')}")
            continue
        for event, start, _, all_day in items:
            time_text = "all day" if all_day else start.strftime("%H:%M")
            lines.append(f"  {c('time', f'{time_text:<7}')} {c('event', event.get('title') or '(no title)')}")
    return lines
