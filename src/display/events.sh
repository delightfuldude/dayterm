#!/usr/bin/env bash

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
    elif [[ -n "$uid" ]]; then
        dt_run_fullscreen khal edit "$uid" --show-past
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
    dt_run_fullscreen run_vdirsyncer_sync "$lock_file"
}

run_vdirsyncer_sync() {
    local lock_file="$1" status config="${VDIRSYNCER_CONFIG:-}"
    local command=(vdirsyncer -v INFO)

    if [[ -n "$config" ]]; then
        if [[ ! -f "$config" ]]; then
            printf 'Configured vdirsyncer file not found: %s\n' "$config" >&2
            return 2
        fi
        command+=(-c "$config")
    fi

    printf 'Synchronizing calendars and contacts...\n\n'
    flock -E 75 -n "$lock_file" "${command[@]}" sync
    status=$?
    if (( status == 75 )); then
        printf '\nAnother DayTerm sync is already running.\n' >&2
    elif (( status == 0 )); then
        printf '\nSynchronization completed.\n'
    fi
    return "$status"
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
