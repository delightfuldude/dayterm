import json
import sys
from datetime import date, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from ui.celltext import color, decode_ansi, fit, rpad, text_width  # noqa: E402


def box_chars(style):
    if style == "ascii":
        return "+", "+", "+", "+", "-", "|"
    return "┌", "┐", "└", "┘", "─", "│"


def read_json(path):
    try:
        return json.loads(Path(path).read_text())
    except Exception:
        return []


def build_box(title, lines, cols, style, palette):
    if cols < 24:
        return [title, *[fit(line, cols, palette["reset"]) for line in lines]]

    tl, tr, bl, br, h, v = box_chars(style)
    label = fit(f" {title} ", max(0, cols - 4), palette["reset"])
    top_fill = max(0, cols - 2 - text_width(label))
    inner = max(0, cols - 4)
    rendered = [
        f"{color(palette['border'], tl, palette['reset'])}"
        f"{color(palette['title'], label, palette['reset'])}"
        f"{color(palette['border'], h * top_fill + tr, palette['reset'])}"
    ]

    for line in lines or [""]:
        rendered.append(
            f"{color(palette['border'], v, palette['reset'])} "
            f"{rpad(line, inner, palette['reset'])} "
            f"{color(palette['border'], v, palette['reset'])}"
        )

    rendered.append(color(palette["border"], bl + (h * max(0, cols - 2)) + br, palette["reset"]))
    return rendered


def main():
    args = sys.argv[1:]
    cols = int(args[0])
    events_count, todos_count, updated = args[1:4]
    agenda_start, agenda_end = args[4:6]
    notifications_enabled, notification_offsets, notification_interval = args[6:9]
    last_notification, todo_limit, box_style = args[9], int(args[10]), args[11]
    events_error, todos_error, todos_enabled = args[12:15]

    color_names = (
        "border title label value muted time event calendar todo_id due_overdue "
        "due_today due_future priority_high priority_medium priority_low ok warn bad key reset"
    ).split()
    palette = {name: decode_ansi(value) for name, value in zip(color_names, args[15:35])}
    events_json = read_json(args[35])
    todos_json = read_json(args[36])

    def c(name, value):
        return color(palette[name], value, palette["reset"])

    def overview_lines():
        if notifications_enabled == "1":
            state = f"on, {notification_offsets} min before, check {notification_interval}s"
            state_color = "ok"
        else:
            state = "off"
            state_color = "warn"

        lines = [
            c("title", datetime.now().strftime("%A, %Y-%m-%d %H:%M")),
            f"{c('label', 'Range:')} {c('value', f'{agenda_start} {agenda_end}')} | "
            f"{c('label', 'Events:')} {c('value', events_count)} | "
            f"{c('label', 'Todos:')} {c('value', todos_count)} | "
            f"{c('label', 'Refreshed:')} {c('value', updated)}",
            f"{c('label', 'Notifications:')} {c(state_color, state)}",
        ]
        if last_notification:
            lines.append(f"{c('label', 'Last notification:')} {c('value', last_notification)}")
        return lines

    def event_lines():
        if events_error:
            return [f"{c('bad', 'Calendar error:')} {events_error}"]
        if not events_json:
            return [c("muted", "No events in range.")]

        lines = []
        for event in events_json:
            if event.get("all-day") == "True":
                time_text, time_color = "all day", "muted"
            else:
                start_time = event.get("start-time") or ""
                end_time = event.get("end-time") or ""
                time_text = start_time + (f"-{end_time}" if end_time else "")
                time_color = "time"

            line = f"{c(time_color, f'{time_text:<13}')} {c('event', event.get('title') or '(no title)')}"
            if event.get("location"):
                line += f" {c('muted', '@')} {c('value', event['location'])}"
            if event.get("calendar"):
                calendar = event["calendar"]
                line += f" {c('calendar', f'[{calendar}]')}"
            if event.get("status") == "CANCELLED":
                line = f"{c('bad', 'CANCELLED')} {line}"
            lines.append(line)
        return lines

    def todo_lines():
        if todos_enabled == "0":
            return [c("muted", "Disabled.")]
        if todos_error:
            return [f"{c('warn', 'Todo warning:')} {todos_error}"]
        if not todos_json:
            return [c("muted", "No open todos.")]

        today = date.today()
        todos = sorted(
            [todo for todo in todos_json if not todo.get("completed")],
            key=lambda todo: (todo.get("due") or 32503680000, -(todo.get("priority") or 0), todo.get("summary") or ""),
        )
        lines = []
        for todo in todos[:todo_limit]:
            due = todo.get("due")
            if isinstance(due, (int, float)):
                due_date = datetime.fromtimestamp(due).date()
                due_text = due_date.strftime("%Y-%m-%d")
                due_color = "due_overdue" if due_date < today else "due_today" if due_date == today else "due_future"
            else:
                due_text, due_color = "no due", "muted"

            priority = int(todo.get("priority") or 0)
            priority_color = "priority_high" if priority >= 5 else "priority_medium" if priority >= 3 else "priority_low"
            todo_id = todo.get("id", "")
            todo_list = todo.get("list") or ""
            lines.append(
                f"{c('todo_id', f'#{todo_id}')} "
                f"{c(due_color, f'{due_text:<10}')} "
                f"{c(priority_color, f'P{priority}')} "
                f"{c('value', todo.get('summary') or '(no title)')} "
                f"{c('calendar', f'[{todo_list}]')}"
            )
        return lines

    def key_lines():
        if cols < 64:
            return [
                f"{c('key', '[e]')} events  {c('key', '[t]')} todos  {c('key', '[n]')} new event",
                f"{c('key', '[a]')} add todo  {c('key', '[s]')} sync  {c('key', '[c]')} calendar",
                f"{c('key', '[i]')} settings  {c('key', '[h]')} help  {c('key', '[q]')} quit",
            ]
        return [
            f"{c('key', '[e]')} events  {c('key', '[t]')} todos  {c('key', '[n]')} new event  {c('key', '[a]')} add todo",
            f"{c('key', '[s]')} sync    {c('key', '[c]')} calendar  {c('key', '[i]')} settings  {c('key', '[h]')} help  {c('key', '[q]')} quit",
        ]

    screen = []
    screen.extend(build_box("DayTerm", overview_lines(), cols, box_style, palette))
    screen.extend(("", *build_box(f"Events ({events_count})", event_lines(), cols, box_style, palette)))
    screen.extend(("", *build_box(f"Todos ({todos_count})", todo_lines(), cols, box_style, palette)))
    screen.extend(("", *build_box("Keys", key_lines(), cols, box_style, palette)))
    print("\n".join(screen))


if __name__ == "__main__":
    main()
