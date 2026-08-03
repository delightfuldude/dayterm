import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from display.render_agenda import event_lines, todo_lines  # noqa: E402
from display.render_common import build_box, build_plain, make_colorizer, read_json  # noqa: E402
from display.render_month import month_lines  # noqa: E402
from display.render_week import week_lines  # noqa: E402
from ui.celltext import decode_ansi  # noqa: E402


def main():
    args = sys.argv[1:]
    cols = int(args[0])
    events_count, todos_count, updated = args[1:4]
    notifications_enabled, notification_offsets, notification_interval = args[4:7]
    last_notification, todo_limit, box_style = args[7], int(args[8]), args[9]
    events_error, todos_error, todos_enabled = args[10:13]
    color_names = (
        "border title label value muted time event calendar todo_id due_overdue "
        "due_today due_future priority_high priority_medium priority_low ok warn bad key reset"
    ).split()
    palette, c = make_colorizer(color_names, args[13:33])
    events, todos = read_json(args[33]), read_json(args[34])
    view, selected_date, date_order = args[35:38]
    week_start, week_end = int(args[38]), int(args[39])
    boxes_enabled = args[40] == "1"
    rows, cursor_minutes = int(args[41]), int(args[42])
    palette["cursor"] = decode_ansi(args[43])
    cursor_step = int(args[44])

    if notifications_enabled == "1":
        state = c("ok", f"on, {notification_offsets} min before, check {notification_interval}s")
    else:
        state = c("warn", "off")
    selected_label = selected_date
    if view == "week":
        selected_label += " / all day" if cursor_minutes < 0 else f" / {cursor_minutes // 60:02d}:{cursor_minutes % 60:02d}"
    overview = [
        c("title", datetime.now().strftime("%A, %Y-%m-%d %H:%M")),
        f"{c('label', 'View:')} {c('value', view.title())} | "
        f"{c('label', 'Selected:')} {c('value', selected_label)} | "
        f"{c('label', 'Events:')} {c('value', events_count)} | "
        f"{c('label', 'Todos:')} {c('value', todos_count)} | "
        f"{c('label', 'Refreshed:')} {c('value', updated)}",
        f"{c('label', 'Notifications:')} {state}",
    ]
    if last_notification:
        overview.append(f"{c('label', 'Last notification:')} {c('value', last_notification)}")

    keys = key_lines(cols, c, view)
    target_content_rows = max(1, rows - 1 - len(overview) - len(keys) - 8)
    sections = [("DayTerm", overview)]
    if view == "week":
        week = week_lines(
            events, selected_date, date_order, cols, week_start, week_end,
            target_content_rows, cursor_minutes, cursor_step, c, box_style,
        )
        sections.append(("Week", week))
    elif view == "month":
        sections.append(("Month", month_lines(events, selected_date, date_order, cols, target_content_rows, c, box_style)))
    elif view == "tasks":
        sections.append((f"Todos ({todos_count})", todo_lines(todos, todos_enabled, todos_error, 50, c)))
    else:
        sections.extend(
            (
                (f"Events ({events_count})", event_lines(events, events_error, c)),
                (f"Todos ({todos_count})", todo_lines(todos, todos_enabled, todos_error, todo_limit, c)),
            )
        )

    screen = []
    for title, lines in sections:
        if screen:
            screen.append("")
        renderer = build_box if boxes_enabled else build_plain
        screen.extend(renderer(title, lines, cols, box_style, palette))
    key_renderer = build_box if boxes_enabled else build_plain
    screen.extend(("", *key_renderer("Keys", keys, cols, box_style, palette)))
    print("\n".join(screen))


def key_lines(cols, c, view):
    if view == "week":
        movement = f"{c('key', '[h/l]')} day  {c('key', '[j/k]')} time  {c('key', '[J/K]')} week"
    elif view == "month":
        movement = f"{c('key', '[h/l]')} day  {c('key', '[j/k]')} week"
    else:
        movement = f"{c('key', '[h/j/k/l]')} move"
    movement += f"  {c('key', '[g]')} today"
    views = f"{c('key', '[a]')} agenda  {c('key', '[w]')} week  {c('key', '[m]')} month  {c('key', '[t]')} tasks"
    actions = f"{c('key', '[Enter]')} open  {c('key', '[n]')} event  {c('key', '[N]')} todo  {c('key', '[s]')} sync  {c('key', '[?]')} help  {c('key', '[q]')} quit"
    if cols < 104:
        create = f"{c('key', '[Enter]')} open  {c('key', '[n]')} event  {c('key', '[N]')} todo"
        utility = f"{c('key', '[s]')} sync  {c('key', '[?]')} help  {c('key', '[q]')} quit"
        return [views, movement, create, utility]
    return [f"{views}  {movement}", actions]


if __name__ == "__main__":
    main()
