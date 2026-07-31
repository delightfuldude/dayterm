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
    local cols events todos updated

    cols=$(dt_cols)
    events=$(calendar_event_count)
    todos=$(todo_count)
    updated=$(format_updated_at "$DAYTERM_EVENTS_UPDATED_AT")

    dt_clear

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
}

render_overview_lines() {
    local events="$1"
    local todos="$2"
    local updated="$3"
    local notification_state
    local notification_color

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

render_events() {
    local max_width="${1:-80}"
    local line

    render_events_lines | while IFS= read -r line; do
        dt_out "$(dt_fit "$line" "$max_width")"
    done
}

render_events_lines() {
    local time title calendar location status line time_color

    if [[ -n "$DAYTERM_EVENTS_ERROR" ]]; then
        printf '%s %s\n' "$(color_text "$C_BAD" "Calendar error:")" "$DAYTERM_EVENTS_ERROR"
        return
    fi

    if [[ "$(calendar_event_count)" == "0" ]]; then
        printf '%s\n' "$(color_text "$C_MUTED" "No events in range.")"
        return
    fi

    while IFS=$'\037' read -r time title calendar location status; do
        if [[ "$time" == "all day" ]]; then
            time_color="$C_MUTED"
        else
            time_color="$C_TIME"
        fi

        line="$(color_text "$time_color" "$(printf '%-13s' "$time")") $(color_text "$C_EVENT" "$title")"
        [[ -n "$location" ]] && line="${line} $(color_text "$C_MUTED" "@") $(color_text "$C_VALUE" "$location")"
        [[ -n "$calendar" ]] && line="${line} $(color_text "$C_CALENDAR" "[$calendar]")"
        [[ "$status" == "CANCELLED" ]] && line="$(color_text "$C_BAD" "CANCELLED") ${line}"
        printf '%s\n' "$line"
    done < <(
        jq -r '
            .[] |
            [
                (if .["all-day"] == "True"
                 then "all day"
                 else ((.["start-time"] // "") + (if (.["end-time"] // "") != "" then "-" + .["end-time"] else "" end))
                 end),
                (.title // "(no title)"),
                (.calendar // ""),
                (.location // ""),
                (.status // "")
            ] | join("\u001f")
        ' <<< "$DAYTERM_EVENTS_JSON" 2>/dev/null
    )
}

render_todos() {
    local limit="${1:-8}"
    local max_width="${2:-80}"
    local line

    render_todos_lines "$limit" | while IFS= read -r line; do
        dt_out "$(dt_fit "$line" "$max_width")"
    done
}

render_todos_lines() {
    local limit="${1:-8}"
    local id summary due priority list due_text line
    local due_color priority_color today_start tomorrow_start

    if [[ "$TODOS_ENABLED" == "0" ]]; then
        printf '%s\n' "$(color_text "$C_MUTED" "Disabled.")"
        return
    fi

    if [[ -n "$DAYTERM_TODOS_ERROR" ]]; then
        printf '%s %s\n' "$(color_text "$C_WARN" "Todo warning:")" "$DAYTERM_TODOS_ERROR"
        return
    fi

    if [[ "$(todo_count)" == "0" ]]; then
        printf '%s\n' "$(color_text "$C_MUTED" "No open todos.")"
        return
    fi

    today_start=$(date -d 'today 00:00' +%s)
    tomorrow_start=$(date -d 'tomorrow 00:00' +%s)

    while IFS=$'\037' read -r id summary due priority list; do
        if [[ "$due" =~ ^[0-9]+$ ]]; then
            due_text=$(date -d "@$due" '+%Y-%m-%d' 2>/dev/null || printf '?')
            if (( due < today_start )); then
                due_color="$C_DUE_OVERDUE"
            elif (( due < tomorrow_start )); then
                due_color="$C_DUE_TODAY"
            else
                due_color="$C_DUE_FUTURE"
            fi
        else
            due_text='no due'
            due_color="$C_MUTED"
        fi

        if (( priority >= 5 )); then
            priority_color="$C_PRIORITY_HIGH"
        elif (( priority >= 3 )); then
            priority_color="$C_PRIORITY_MEDIUM"
        else
            priority_color="$C_PRIORITY_LOW"
        fi

        line="$(color_text "$C_TODO_ID" "#$id") $(color_text "$due_color" "$(printf '%-10s' "$due_text")") $(color_text "$priority_color" "P$priority") $(color_text "$C_VALUE" "$summary") $(color_text "$C_CALENDAR" "[$list]")"
        printf '%s\n' "$line"
    done < <(
        jq -r --argjson limit "$limit" '
            sort_by((.due // 32503680000), -(.priority // 0), (.summary // "")) |
            .[:$limit][] |
            [((.id // "") | tostring), (.summary // "(no title)"), ((.due // "") | tostring), ((.priority // 0) | tostring), (.list // "")] | join("\u001f")
        ' <<< "$DAYTERM_TODOS_JSON" 2>/dev/null
    )
}

show_event_details() {
    local count selection index title calendar uid

    count=$(calendar_event_count)
    dt_clear
    dt_out "${BLUE}${BOLD}Event details${NC}"
    dt_out ""

    if [[ "$count" == "0" ]]; then
        dt_out "No events in range."
        dt_pause
        return 0
    fi

    jq -r '
        to_entries[] |
        "\(.key + 1). \(.value.start // "") - \(.value.end // "")\n   \(.value.title // "(no title)")\n   Calendar: \(.value.calendar // "")\n   Location: \(.value.location // "")\n   Organizer: \(.value.organizer // "")\n   UID: \(.value.uid // "")\n"
    ' <<< "$DAYTERM_EVENTS_JSON" >"$DAYTERM_TTY"

    dt_out ""
    printf 'Event number to edit, or Enter to return: ' >"$DAYTERM_TTY"
    read -r selection <"$DAYTERM_TTY"

    [[ "$selection" =~ ^[0-9]+$ ]] || return 0
    (( selection >= 1 && selection <= count )) || return 0

    index=$((selection - 1))
    title=$(jq -r --argjson i "$index" '.[$i].title // ""' <<< "$DAYTERM_EVENTS_JSON")
    calendar=$(jq -r --argjson i "$index" '.[$i].calendar // ""' <<< "$DAYTERM_EVENTS_JSON")
    uid=$(jq -r --argjson i "$index" '.[$i].uid // ""' <<< "$DAYTERM_EVENTS_JSON")

    if [[ -n "$calendar" && -n "$title" ]]; then
        dt_run_fullscreen khal edit --include-calendar "$calendar" "$title" --show-past
        refresh_calendar_data
    elif [[ -n "$uid" ]]; then
        dt_run_fullscreen khal edit "$uid" --show-past
        refresh_calendar_data
    fi
}

create_event() {
    if ! test_khal; then
        dt_clear
        dt_err "${RED}khal is not available.${NC}"
        dt_pause
        return 1
    fi

    dt_run_fullscreen khal new --interactive
}

sync_calendars() {
    local lock_file

    if ! command -v vdirsyncer >/dev/null 2>&1; then
        dt_clear
        dt_err "${YELLOW}vdirsyncer is not available.${NC}"
        dt_pause
        return 1
    fi

    lock_file="$DAYTERM_CACHE_DIR/sync.lock"
    dt_run_fullscreen flock -n "$lock_file" vdirsyncer sync
}

open_calendar() {
    if command -v ikhal >/dev/null 2>&1; then
        dt_run_fullscreen ikhal
    elif command -v khal >/dev/null 2>&1; then
        dt_run_fullscreen khal interactive
    else
        dt_clear
        dt_err "${RED}khal/ikhal is not available.${NC}"
        dt_pause
        return 1
    fi
}
