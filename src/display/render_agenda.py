from datetime import date, datetime


def event_lines(events, error, c):
    if error:
        return [f"{c('bad', 'Calendar error:')} {error}"]
    if not events:
        return [c("muted", "No events in range.")]

    lines = []
    for event in events:
        if str(event.get("all-day", "")).lower() == "true":
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
            calendar_label = f"[{event['calendar']}]"
            line += f" {c('calendar', calendar_label)}"
        if event.get("status") == "CANCELLED":
            line = f"{c('bad', 'CANCELLED')} {line}"
        lines.append(line)
    return lines


def todo_lines(todos, enabled, error, limit, c):
    if enabled == "0":
        return [c("muted", "Disabled.")]
    if error:
        return [f"{c('warn', 'Todo warning:')} {error}"]
    if not todos:
        return [c("muted", "No open todos.")]

    today = date.today()
    pending = sorted(
        [todo for todo in todos if not todo.get("completed")],
        key=lambda item: (item.get("due") or 32503680000, -(item.get("priority") or 0), item.get("summary") or ""),
    )
    lines = []
    for todo in pending[:limit]:
        due = todo.get("due")
        if isinstance(due, (int, float)):
            due_date = datetime.fromtimestamp(due).date()
            due_text = due_date.strftime("%Y-%m-%d")
            due_color = "due_overdue" if due_date < today else "due_today" if due_date == today else "due_future"
        else:
            due_text, due_color = "no due", "muted"

        priority = int(todo.get("priority") or 0)
        priority_color = "priority_high" if priority >= 5 else "priority_medium" if priority >= 3 else "priority_low"
        todo_id = f"#{todo.get('id', '')}"
        priority_label = f"P{priority}"
        list_label = f"[{todo.get('list') or ''}]"
        lines.append(
            f"{c('todo_id', todo_id)} "
            f"{c(due_color, f'{due_text:<10}')} {c(priority_color, priority_label)} "
            f"{c('value', todo.get('summary') or '(no title)')} "
            f"{c('calendar', list_label)}"
        )
    return lines
