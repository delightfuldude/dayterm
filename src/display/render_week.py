from datetime import date, datetime, timedelta

from display.render_common import column_widths, grid_line, grid_rule
from display.render_data import events_for_day, indexed_events
from ui.celltext import fit, rpad

GUTTER_WIDTH = 7


def week_lines(
    events, selected_text, order, cols, start_hour, end_hour,
    target_rows, cursor_minutes, cursor_step, c, style,
):
    selected = date.fromisoformat(selected_text)
    week_start = selected - timedelta(days=selected.weekday())
    days = [week_start + timedelta(days=offset) for offset in range(7)]
    indexed = indexed_events(events, order)
    if cols < 76:
        return compact_week(indexed, days, selected, target_rows, c)

    inner = max(20, cols - 4)
    separator = "|" if style == "ascii" else "│"
    widths = column_widths(inner - GUTTER_WIDTH - 3, 7)

    def row(gutter, cells):
        divider = f" {c('border', separator)} "
        return f"{rpad(gutter, GUTTER_WIDTH)}{divider}{grid_line(cells, widths, separator, c)}"

    headers = []
    for day, width in zip(days, widths):
        label = day.strftime("%a %d")
        color_name = "key" if day == selected else "due_today" if day == date.today() else "label"
        headers.append(c(color_name, fit(label, width)))

    rule = grid_rule([GUTTER_WIDTH, *widths], style, c)
    lines = [row("", headers), rule]
    all_day_cells = []
    for day, width in zip(days, widths):
        items = [item for item in events_for_day(indexed, day) if item[3]]
        label = items[0][0].get("title", "") if items else ""
        if len(items) > 1:
            label += f" +{len(items) - 1}"
        selected_cell = day == selected and cursor_minutes < 0
        all_day_cells.append(paint_cell(label, width, "calendar", selected_cell, c))
    lines.extend((row(c("muted", "all day"), all_day_cells), rule))

    timeline_rows = max(1, target_rows - 4)
    for start_minute, end_minute, gutter in timeline_slots(
        start_hour, end_hour, timeline_rows, cursor_minutes, cursor_step,
    ):
        cells = [
            timed_cell(
                indexed,
                day,
                start_minute,
                end_minute,
                width,
                day == selected and start_minute <= cursor_minutes < end_minute,
                c,
            )
            for day, width in zip(days, widths)
        ]
        lines.append(row(c("time", gutter), cells))
    return lines


def timeline_slots(start_hour, end_hour, row_count, cursor_minutes, cursor_step):
    hour_count = end_hour - start_hour
    if row_count < hour_count:
        range_start, range_end = start_hour * 60, end_hour * 60
        total_slots = (range_end - range_start + cursor_step - 1) // cursor_step
        cursor_index = max(0, (max(range_start, cursor_minutes) - range_start) // cursor_step)
        first_index = max(0, min(cursor_index - row_count // 2, total_slots - row_count))
        for index in range(row_count):
            start = range_start + (first_index + index) * cursor_step
            end = min(range_end, start + cursor_step)
            yield start, end, f"{start // 60:02d}:{start % 60:02d}"
        return

    rows_per_hour, extra_rows = divmod(row_count, hour_count)
    for hour_index, hour in enumerate(range(start_hour, end_hour)):
        hour_rows = rows_per_hour + (1 if hour_index < extra_rows else 0)
        for subrow in range(hour_rows):
            start = hour * 60 + subrow * 60 // hour_rows
            end = hour * 60 + (subrow + 1) * 60 // hour_rows
            yield start, end, f"{hour:02d}:00" if subrow == 0 else ""


def paint_cell(text, width, color_name, selected, c):
    if selected:
        text = f"▸{text}" if text else "▸"
    fitted = fit(text or "", width)
    if selected:
        return c("cursor", rpad(fitted, width))
    return c(color_name, fitted)


def timed_cell(indexed, day, start_minute, end_minute, width, selected, c):
    midnight = datetime.combine(day, datetime.min.time())
    slot_start = midnight + timedelta(minutes=start_minute)
    slot_end = midnight + timedelta(minutes=end_minute)
    items = [item for item in indexed if not item[3] and item[1] < slot_end and item[2] > slot_start]
    label = ""
    if items:
        event, start, _, _ = items[0]
        marker = "▌" if start >= slot_start else "│"
        label = f"{marker}{start:%H:%M} {event.get('title') or '(no title)'}"
        if len(items) > 1:
            label += f" +{len(items) - 1}"
    return paint_cell(label, width, "event", selected, c)


def compact_week(indexed, days, selected, target_rows, c):
    lines = []
    for day in days:
        items = events_for_day(indexed, day)
        color_name = "key" if day == selected else "due_today" if day == date.today() else "label"
        lines.append(c(color_name, day.strftime("%a %Y-%m-%d")))
        if not items:
            lines.append(f"  {c('muted', 'No events')}")
        for event, start, _, all_day in items:
            time_text = "all day" if all_day else start.strftime("%H:%M")
            lines.append(f"  {c('time', f'{time_text:<7}')} {c('event', event.get('title') or '(no title)')}")
    lines.extend([""] * max(0, target_rows - len(lines)))
    return lines
