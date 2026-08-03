import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from display.render_agenda import event_lines, todo_lines  # noqa: E402
from display.render_common import build_box, build_plain, make_colorizer, read_json  # noqa: E402
from display.render_month import month_lines  # noqa: E402
from display.render_week import week_lines  # noqa: E402


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

    if notifications_enabled == "1":
        state = c("ok", f"on, {notification_offsets} min before, check {notification_interval}s")
    else:
        state = c("warn", "off")
    overview = [
        c("title", datetime.now().strftime("%A, %Y-%m-%d %H:%M")),
        f"{c('label', 'View:')} {c('value', view.title())} | "
        f"{c('label', 'Selected:')} {c('value', selected_date)} | "
        f"{c('label', 'Events:')} {c('value', events_count)} | "
        f"{c('label', 'Todos:')} {c('value', todos_count)} | "
        f"{c('label', 'Refreshed:')} {c('value', updated)}",
        f"{c('label', 'Notifications:')} {state}",
    ]
    if last_notification:
        overview.append(f"{c('label', 'Last notification:')} {c('value', last_notification)}")

    sections = [("DayTerm", overview)]
    if view == "week":
        sections.append(("Week", week_lines(events, selected_date, date_order, cols, week_start, week_end, c, box_style)))
    elif view == "month":
        grid, selected = month_lines(events, selected_date, date_order, cols, c, box_style)
        sections.extend((("Month", grid), (f"Events on {selected_date}", selected)))
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
    screen.extend(("", *key_renderer("Keys", key_lines(cols, c), cols, box_style, palette)))
    print("\n".join(screen))


def key_lines(cols, c):
    movement = f"{c('key', '[h/j/k/l]')} move  {c('key', '[g]')} today"
    views = f"{c('key', '[a]')} agenda  {c('key', '[w]')} week  {c('key', '[m]')} month  {c('key', '[t]')} tasks"
    actions = f"{c('key', '[n]')} event  {c('key', '[N]')} todo  {c('key', '[s]')} sync  {c('key', '[?]')} help  {c('key', '[q]')} quit"
    return [views, movement, actions] if cols < 104 else [f"{views}  {movement}", actions]


if __name__ == "__main__":
    main()
