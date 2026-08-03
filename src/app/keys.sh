#!/usr/bin/env bash

handle_key() {
    local key="$1"

    case "$key" in
        a|w|m|t)
            dayterm_apply_view_change view_set "$(view_name_for_key "$key")"
            ;;
        h|j|k|l|J|K)
            dayterm_apply_view_change view_move "$key"
            ;;
        g)
            dayterm_apply_view_change view_go_today
            ;;
        e)
            if [[ "$DAYTERM_VIEW" == "week" || "$DAYTERM_VIEW" == "month" ]]; then
                activate_calendar_cursor
            else
                show_event_details
            fi
            refresh_calendar_data
            refresh_notification_calendar_data
            ;;
        '')
            if [[ "$DAYTERM_VIEW" == "tasks" ]]; then
                show_todo_details
            elif [[ "$DAYTERM_VIEW" == "week" || "$DAYTERM_VIEW" == "month" ]]; then
                activate_calendar_cursor
                refresh_calendar_data
                refresh_notification_calendar_data
            else
                show_event_details
                refresh_calendar_data
                refresh_notification_calendar_data
            fi
            ;;
        n)
            create_event_for_context && refresh_calendar_data
            refresh_notification_calendar_data
            ;;
        N)
            edit_todo
            refresh_todo_data
            ;;
        s)
            sync_calendars
            refresh_calendar_data
            refresh_notification_calendar_data
            refresh_todo_data
            ;;
        c)
            open_calendar
            refresh_calendar_data
            refresh_notification_calendar_data
            ;;
        i)
            edit_settings
            view_apply_query_range
            notifications_init
            ;;
        \?)
            show_help
            ;;
        q)
            dayterm_cleanup
            exit 0
            ;;
        *)
            return 0
            ;;
    esac

    DAYTERM_NEEDS_REDRAW=1
}

dayterm_apply_view_change() {
    local previous_start="$DAYTERM_QUERY_START"
    local previous_end="$DAYTERM_QUERY_END"
    local previous_view="$DAYTERM_VIEW"

    "$@" || return 0
    if [[ "$DAYTERM_VIEW" != "tasks" ]] &&
        [[ "$previous_view" != "$DAYTERM_VIEW" || "$previous_start" != "$DAYTERM_QUERY_START" || "$previous_end" != "$DAYTERM_QUERY_END" ]]; then
        refresh_calendar_data
    fi
}
