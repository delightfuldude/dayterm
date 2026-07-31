#!/usr/bin/env bash

format_updated_at() {
    local epoch="$1"

    if [[ "$epoch" =~ ^[0-9]+$ && "$epoch" -gt 0 ]]; then
        date -d "@$epoch" '+%H:%M:%S'
    else
        printf 'never'
    fi
}

display_schedule() {
    local cols events todos updated screen

    cols=$(dt_cols)
    events=$(calendar_event_count)
    todos=$(todo_count)
    updated=$(format_updated_at "$DAYTERM_EVENTS_UPDATED_AT")

    if [[ "$TUI_BOXES" == "1" ]] && dt_has_wcwidth &&
        screen=$(render_screen_fast "$cols" "$events" "$todos" "$updated"); then
        dt_clear
        dt_begin_screen
        dt_out "$screen"
        dt_flush_screen
        return
    fi

    dt_begin_screen

    if [[ "$TUI_BOXES" == "1" ]]; then
        dt_box "DayTerm" "$cols" render_overview_lines "$events" "$todos" "$updated"
        dt_out ""
        dt_box "Events ($events)" "$cols" render_events_lines
        dt_out ""
        dt_box "Todos ($todos)" "$cols" render_todos_lines "$TODO_LIMIT"
    else
        dt_out "${BLUE}${BOLD}DayTerm${NC}  $(date '+%A, %Y-%m-%d %H:%M')"
        dt_out "$(dt_line '=')"
        render_overview_lines "$events" "$todos" "$updated" | while IFS= read -r line; do
            dt_out "$line"
        done
        dt_out ""
        dt_out "${GREEN}${BOLD}Events${NC}"
        render_events "$((cols - 1))"
        dt_out ""
        dt_out "${GREEN}${BOLD}Todos${NC}"
        render_todos "$TODO_LIMIT" "$((cols - 1))"
    fi

    dt_out ""
    render_command_bar "$cols"
    dt_clear
    dt_flush_screen
}

render_screen_fast() {
    local cols="$1" events="$2" todos="$3" updated="$4"
    local events_file todos_file status

    events_file=$(mktemp) || return 1
    todos_file=$(mktemp) || {
        rm -f "$events_file"
        return 1
    }

    printf '%s\n' "$DAYTERM_EVENTS_JSON" > "$events_file"
    printf '%s\n' "$DAYTERM_TODOS_JSON" > "$todos_file"

    python3 "$DAYTERM_SRC/display/render.py" \
        "$cols" "$events" "$todos" "$updated" \
        "$AGENDA_START" "$AGENDA_END" \
        "$NOTIFICATIONS_ENABLED" "$NOTIFICATION_OFFSETS" "$NOTIFICATION_CHECK_INTERVAL" \
        "$DAYTERM_LAST_NOTIFICATION" "$TODO_LIMIT" "$TUI_BOX_STYLE" \
        "$DAYTERM_EVENTS_ERROR" "$DAYTERM_TODOS_ERROR" "$TODOS_ENABLED" \
        "$C_BORDER" "$C_TITLE" "$C_LABEL" "$C_VALUE" "$C_MUTED" "$C_TIME" "$C_EVENT" "$C_CALENDAR" \
        "$C_TODO_ID" "$C_DUE_OVERDUE" "$C_DUE_TODAY" "$C_DUE_FUTURE" "$C_PRIORITY_HIGH" "$C_PRIORITY_MEDIUM" "$C_PRIORITY_LOW" \
        "$C_OK" "$C_WARN" "$C_BAD" "$C_KEY" "$NC" \
        "$events_file" "$todos_file"
    status=$?

    rm -f "$events_file" "$todos_file"
    return "$status"
}

render_overview_lines() {
    local events="$1" todos="$2" updated="$3"
    local notification_state notification_color

    if [[ "$NOTIFICATIONS_ENABLED" == "1" ]]; then
        notification_state="on, ${NOTIFICATION_OFFSETS} min before, check ${NOTIFICATION_CHECK_INTERVAL}s"
        notification_color="$C_OK"
    else
        notification_state="off"
        notification_color="$C_WARN"
    fi

    printf '%s\n' "$(color_text "$C_TITLE" "$(date '+%A, %Y-%m-%d %H:%M')")"
    printf '%s %s | %s %s | %s %s | %s %s\n' \
        "$(color_text "$C_LABEL" "Range:")" "$(color_text "$C_VALUE" "$AGENDA_START $AGENDA_END")" \
        "$(color_text "$C_LABEL" "Events:")" "$(color_text "$C_VALUE" "$events")" \
        "$(color_text "$C_LABEL" "Todos:")" "$(color_text "$C_VALUE" "$todos")" \
        "$(color_text "$C_LABEL" "Refreshed:")" "$(color_text "$C_VALUE" "$updated")"
    printf '%s %s\n' "$(color_text "$C_LABEL" "Notifications:")" "$(color_text "$notification_color" "$notification_state")"
    [[ -n "$DAYTERM_LAST_NOTIFICATION" ]] && printf '%s %s\n' "$(color_text "$C_LABEL" "Last notification:")" "$(color_text "$C_VALUE" "$DAYTERM_LAST_NOTIFICATION")"
}

render_command_bar() {
    local cols="${1:-80}"

    if [[ "$TUI_BOXES" == "1" ]]; then
        dt_box "Keys" "$cols" render_command_lines "$cols"
    else
        dt_out "$(dt_line '-')"
        render_command_lines "$cols" | while IFS= read -r line; do
            dt_out "$(dt_fit "$line" "$cols")"
        done
    fi
}

render_command_lines() {
    local cols="${1:-80}"

    if (( cols < 64 )); then
        printf '%s events  %s todos  %s new event\n' "$(color_text "$C_KEY" "[e]")" "$(color_text "$C_KEY" "[t]")" "$(color_text "$C_KEY" "[n]")"
        printf '%s add todo  %s sync  %s calendar\n' "$(color_text "$C_KEY" "[a]")" "$(color_text "$C_KEY" "[s]")" "$(color_text "$C_KEY" "[c]")"
        printf '%s settings  %s help  %s quit\n' "$(color_text "$C_KEY" "[i]")" "$(color_text "$C_KEY" "[h]")" "$(color_text "$C_KEY" "[q]")"
    else
        printf '%s events  %s todos  %s new event  %s add todo\n' "$(color_text "$C_KEY" "[e]")" "$(color_text "$C_KEY" "[t]")" "$(color_text "$C_KEY" "[n]")" "$(color_text "$C_KEY" "[a]")"
        printf '%s sync    %s calendar  %s settings  %s help  %s quit\n' "$(color_text "$C_KEY" "[s]")" "$(color_text "$C_KEY" "[c]")" "$(color_text "$C_KEY" "[i]")" "$(color_text "$C_KEY" "[h]")" "$(color_text "$C_KEY" "[q]")"
    fi
}
