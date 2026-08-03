#!/usr/bin/env bash

DAYTERM_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DAYTERM_ROOT="$(cd "$DAYTERM_SRC/.." >/dev/null 2>&1 && pwd)"

source_file() {
    local file="$1"
    local full_path="$DAYTERM_SRC/$file"

    if [[ ! -f "$full_path" ]]; then
        printf 'Error: missing module %s\n' "$full_path" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    if ! source "$full_path"; then
        printf 'Error: failed to source %s\n' "$file" >&2
        exit 1
    fi
}

source_file "utils.sh"
source_file "settings.sh"
source_file "calendar.sh"
source_file "todos.sh"
source_file "check.sh"
source_file "notifications.sh"
source_file "view.sh"
source_file "display.sh"
source_file "app.sh"

dayterm_parse_args "$@"
load_settings
init_runtime
view_init

if (( DAYTERM_CHECK )); then
    dayterm_check
    exit $?
fi

if (( DAYTERM_NOTIFY_TEST )); then
    notifications_send "DayTerm notification test" "Desktop notifications are reachable."
    exit $?
fi

if (( DAYTERM_ONCE )); then
    [[ "$DAYTERM_VIEW" == "tasks" ]] || refresh_calendar_data
    refresh_todo_data
    display_schedule
    exit 0
fi

if ! dt_has_tty; then
    printf 'DayTerm needs a TTY for interactive mode. Use --once for plain output.\n' >&2
    exit 1
fi

notifications_init
dayterm_run
