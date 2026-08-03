import calendar
from datetime import date, timedelta

from display.render_common import column_widths, grid_line, grid_rule
from display.render_data import events_for_day, indexed_events
from ui.celltext import fit, rpad


def month_lines(events, selected_text, order, cols, target_rows, c, style):
    selected = date.fromisoformat(selected_text)
    indexed = indexed_events(events, order)
    weeks = calendar.Calendar(firstweekday=0).monthdayscalendar(selected.year, selected.month)
    inner = max(20, cols - 4)
    separator = "|" if style == "ascii" else "│"
    widths = column_widths(inner, 7)
    monday = date(2024, 1, 1)
    names = [(monday + timedelta(days=index)).strftime("%a") for index in range(7)]
    headers = [c("label", fit(name, width)) for name, width in zip(names, widths)]
    rule = grid_rule(widths, style, c)
    lines = [grid_line(headers, widths, separator, c)]
    if target_rows >= len(weeks) + 2:
        lines.append(rule)

    separator_count = len(weeks) - 1
    use_week_rules = target_rows >= len(lines) + len(weeks) + separator_count
    if not use_week_rules:
        separator_count = 0
    body_rows = max(len(weeks), target_rows - len(lines) - separator_count)
    base_height, remainder = divmod(body_rows, len(weeks))
    for week_index, week in enumerate(weeks):
        height = base_height + (1 if week_index < remainder else 0)
        day_data = [day_details(indexed, selected, day_number) for day_number in week]
        for row_index in range(height):
            cells = [
                month_cell(details, row_index, height, width, c)
                for details, width in zip(day_data, widths)
            ]
            lines.append(grid_line(cells, widths, separator, c))
        if use_week_rules and week_index < len(weeks) - 1:
            lines.append(rule)
    return lines


def day_details(indexed, selected, day_number):
    if not day_number:
        return None
    current = selected.replace(day=day_number)
    return current, events_for_day(indexed, current), current == selected, current == date.today()


def month_cell(details, row_index, height, width, c):
    if not details:
        return ""
    current, items, selected, today = details
    if row_index == 0:
        marker = "▸" if selected else ""
        text = marker + str(current.day) + (f" ·{len(items)}" if items else "")
        color_name = "due_today" if today else "value"
    else:
        event_index = row_index - 1
        if event_index < len(items):
            event, start, _, all_day = items[event_index]
            prefix = "" if all_day else f"{start:%H:%M} "
            text = prefix + (event.get("title") or "(no title)")
            hidden = len(items) - event_index - 1
            if row_index == height - 1 and hidden:
                text += f" +{hidden}"
            color_name = "calendar" if all_day else "event"
        else:
            text, color_name = "", "event"
    fitted = fit(text, width)
    return c("cursor", rpad(fitted, width)) if selected else c(color_name, fitted)
