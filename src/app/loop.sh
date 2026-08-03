#!/usr/bin/env bash

DAYTERM_NEEDS_REDRAW=0

dayterm_cleanup() {
    dt_show_cursor
    dt_reset_screen
    dt_out ""
    dt_out "DayTerm stopped."
}

dayterm_prepare_data() {
    load_cached_calendar_data || true
    load_cached_notification_calendar_data || true
    load_cached_todo_data || true
}

dayterm_run() {
    local now next_calendar next_todo next_notification_data next_notification_check key

    dayterm_prepare_data
    now=$SECONDS
    next_calendar=$now
    next_todo=$now
    next_notification_data=$now
    next_notification_check=$now

    trap 'DAYTERM_NEEDS_REDRAW=1' WINCH
    trap 'dayterm_cleanup; exit 0' INT TERM

    dt_hide_cursor
    display_schedule

    while true; do
        now=$SECONDS

        if (( now >= next_calendar )); then
            [[ "$DAYTERM_VIEW" == "tasks" ]] || refresh_calendar_data
            next_calendar=$((now + UPDATE_INTERVAL))
            [[ "$DAYTERM_VIEW" == "tasks" ]] || DAYTERM_NEEDS_REDRAW=1
        fi

        if (( now >= next_todo )); then
            refresh_todo_data
            next_todo=$((now + TODO_UPDATE_INTERVAL))
            DAYTERM_NEEDS_REDRAW=1
        fi

        if (( now >= next_notification_data )); then
            [[ "$NOTIFICATIONS_ENABLED" == "1" ]] && refresh_notification_calendar_data
            next_notification_data=$((now + NOTIFICATION_DATA_REFRESH_INTERVAL))
        fi

        if (( now >= next_notification_check )); then
            notifications_check_due "$DAYTERM_NOTIFICATION_EVENTS_JSON"
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
