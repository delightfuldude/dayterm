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
source_file "calendar/core.sh"
source_file "todos.sh"
source_file "check.sh"
source_file "notifications.sh"
source_file "display.sh"

DAYTERM_ONCE=0
DAYTERM_CHECK=0
DAYTERM_NOTIFY_TEST=0

for arg in "$@"; do
    case "$arg" in
        --once)
            DAYTERM_ONCE=1
            ;;
        --check)
            DAYTERM_CHECK=1
            ;;
        --notify-test)
            DAYTERM_NOTIFY_TEST=1
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$arg" >&2
            print_usage >&2
            exit 2
            ;;
    esac
done

load_settings
init_runtime
notifications_init

if (( DAYTERM_CHECK )); then
    dayterm_check
    exit $?
fi

if (( DAYTERM_NOTIFY_TEST )); then
    notifications_send "DayTerm notification test" "Desktop notifications are reachable."
    exit $?
fi

if (( DAYTERM_ONCE )); then
    refresh_calendar_data
    refresh_todo_data
    display_schedule
    exit 0
fi

if ! dt_has_tty; then
    printf 'DayTerm needs a TTY for interactive mode. Use --once for plain output.\n' >&2
    exit 1
fi

load_cached_calendar_data || true
load_cached_todo_data || true
DAYTERM_DEFER_INITIAL_REFRESH=1
DAYTERM_NEEDS_REDRAW=0

cleanup() {
    dt_show_cursor
    dt_reset_screen
    dt_out ""
    dt_out "DayTerm stopped."
}

trap 'DAYTERM_NEEDS_REDRAW=1' WINCH
trap 'cleanup; exit 0' INT TERM

handle_key() {
    local key="$1"

    case "$key" in
        e)
            show_event_details
            DAYTERM_NEEDS_REDRAW=1
            ;;
        t)
            show_todo_details
            DAYTERM_NEEDS_REDRAW=1
            ;;
        h)
            show_help
            DAYTERM_NEEDS_REDRAW=1
            ;;
        n)
            create_event
            refresh_calendar_data
            DAYTERM_NEEDS_REDRAW=1
            ;;
        a)
            edit_todo
            refresh_todo_data
            DAYTERM_NEEDS_REDRAW=1
            ;;
        s)
            sync_calendars
            refresh_calendar_data
            refresh_todo_data
            DAYTERM_NEEDS_REDRAW=1
            ;;
        c)
            open_calendar
            refresh_calendar_data
            DAYTERM_NEEDS_REDRAW=1
            ;;
        i)
            edit_settings
            notifications_init
            DAYTERM_NEEDS_REDRAW=1
            ;;
        q)
            cleanup
            exit 0
            ;;
    esac
}

main_loop() {
    local now
    local next_calendar_refresh
    local next_todo_refresh
    local next_notification_check
    local key

    now=$SECONDS
    if [[ "${DAYTERM_DEFER_INITIAL_REFRESH:-0}" == "1" ]]; then
        next_calendar_refresh=$now
        next_todo_refresh=$now
    else
        next_calendar_refresh=$((now + UPDATE_INTERVAL))
        next_todo_refresh=$((now + TODO_UPDATE_INTERVAL))
    fi
    next_notification_check=$now

    dt_hide_cursor
    display_schedule

    while true; do
        now=$SECONDS

        if (( now >= next_calendar_refresh )); then
            refresh_calendar_data
            next_calendar_refresh=$((now + UPDATE_INTERVAL))
            DAYTERM_NEEDS_REDRAW=1
        fi

        if (( now >= next_todo_refresh )); then
            refresh_todo_data
            next_todo_refresh=$((now + TODO_UPDATE_INTERVAL))
            DAYTERM_NEEDS_REDRAW=1
        fi

        if (( now >= next_notification_check )); then
            notifications_check_due "$DAYTERM_EVENTS_JSON"
            next_notification_check=$((now + NOTIFICATION_CHECK_INTERVAL))
        fi

        if (( DAYTERM_NEEDS_REDRAW )); then
            display_schedule
            DAYTERM_NEEDS_REDRAW=0
        fi

        if read -rsn 1 -t "$IDLE_TICK_SECONDS" key <"$DAYTERM_TTY"; then
            handle_key "$key"
        fi
    done
}

main_loop
