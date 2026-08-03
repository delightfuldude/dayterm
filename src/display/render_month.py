import calendar
from datetime import date, timedelta

from display.render_agenda import event_lines
from display.render_common import grid_line
from display.render_data import events_for_day, indexed_events
from ui.celltext import fit


def month_lines(events, selected_text, order, cols, c, style):
    selected = date.fromisoformat(selected_text)
    indexed = indexed_events(events, order)
    weeks = calendar.Calendar(firstweekday=0).monthdayscalendar(selected.year, selected.month)
    inner = max(20, cols - 4)
    separator = "|" if style == "ascii" else "│"
    cell_width = max(2, (inner - 18) // 7)
    monday = date(2024, 1, 1)
    names = [(monday + timedelta(days=index)).strftime("%a") for index in range(7)]
    lines = [grid_line([c("label", fit(name, cell_width)) for name in names], cell_width, separator, c)]

    for week in weeks:
        day_cells, event_cells = [], []
        for day_number in week:
            if not day_number:
                day_cells.append("")
                event_cells.append("")
                continue
            current = date(selected.year, selected.month, day_number)
            day_events = events_for_day(indexed, current)
            label = str(day_number)
            if day_events:
                label += f" ·{len(day_events)}"
            color_name = "key" if current == selected else "due_today" if current == date.today() else "value"
            day_cells.append(c(color_name, fit(label, cell_width)))
            title = day_events[0][0].get("title") if day_events else ""
            event_cells.append(c("event", fit(title or "", cell_width)))
        lines.append(grid_line(day_cells, cell_width, separator, c))
        lines.append(grid_line(event_cells, cell_width, separator, c))

    selected_events = [item[0] for item in events_for_day(indexed, selected)]
    return lines, event_lines(selected_events, "", c)
