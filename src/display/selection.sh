#!/usr/bin/env bash

calendar_cursor_candidates() {
    local cursor="$1" step=1

    (( cursor >= 0 )) && step="$WEEK_CURSOR_STEP_MINUTES"

    python3 "$DAYTERM_SRC/event_selection.py" \
        "$DAYTERM_DATE_ORDER" "$DAYTERM_SELECTED_DATE" "$cursor" "$step" <<< "$DAYTERM_EVENTS_JSON"
}

activate_calendar_cursor() {
    local cursor candidates count

    case "$DAYTERM_VIEW" in
        week) cursor="$DAYTERM_CURSOR_MINUTES" ;;
        month) cursor=-2 ;;
        *) return 1 ;;
    esac

    candidates=$(calendar_cursor_candidates "$cursor") || return 1
    count=$(jq -r 'length' <<< "$candidates")
    if (( count > 0 )); then
        edit_event_candidates "$candidates"
    else
        create_event_at_selection "$cursor"
    fi
}

edit_event_candidates() {
    local candidates="$1" count selection=1 index title calendar uid

    count=$(jq -r 'length' <<< "$candidates")
    if (( count > 1 )); then
        dt_clear
        dt_show_cursor
        dt_out "${BLUE}${BOLD}Events on $DAYTERM_SELECTED_DATE${NC}"
        jq -r 'to_entries[] | "\(.key + 1). \(.value["start-time"] // "all day")  \(.value.title // "(no title)")  [\(.value.calendar // "")]"' \
            <<< "$candidates" > "$DAYTERM_TTY"
        dt_out ""
        printf 'Event number, or Enter to cancel: ' > "$DAYTERM_TTY"
        read -r selection < "$DAYTERM_TTY"
        dt_hide_cursor
        [[ "$selection" =~ ^[0-9]+$ ]] || return 0
        (( selection >= 1 && selection <= count )) || return 0
    fi

    index=$((selection - 1))
    title=$(jq -r --argjson index "$index" '.[$index].title // ""' <<< "$candidates")
    calendar=$(jq -r --argjson index "$index" '.[$index].calendar // ""' <<< "$candidates")
    uid=$(jq -r --argjson index "$index" '.[$index].uid // ""' <<< "$candidates")
    if [[ -n "$calendar" && -n "$title" ]]; then
        dt_run_fullscreen khal edit --include-calendar "$calendar" --show-past -- "$title"
    elif [[ -n "$uid" ]]; then
        dt_run_fullscreen khal edit --show-past -- "$uid"
    fi
}

create_event_for_context() {
    case "$DAYTERM_VIEW" in
        week) create_event_at_selection "$DAYTERM_CURSOR_MINUTES" ;;
        agenda|month) create_event_at_selection -2 ;;
        *) create_event ;;
    esac
}

create_event_at_selection() {
    local cursor="$1" start

    test_khal || return 1
    start=$(calendar_format_query_date "$DAYTERM_SELECTED_DATE") || return 1
    if (( cursor >= 0 )); then
        start+=" $(printf '%02d:%02d' "$((cursor / 60))" "$((cursor % 60))")"
    fi
    dt_run_fullscreen khal new --interactive "$start"
}
