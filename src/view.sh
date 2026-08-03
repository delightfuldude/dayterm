#!/usr/bin/env bash

DAYTERM_VIEW='agenda'
DAYTERM_SELECTED_DATE=''
DAYTERM_QUERY_START=''
DAYTERM_QUERY_END=''
DAYTERM_CURSOR_MINUTES=0
WEEK_START_HOUR="${WEEK_START_HOUR:-7}"
WEEK_END_HOUR="${WEEK_END_HOUR:-20}"
WEEK_CURSOR_STEP_MINUTES="${WEEK_CURSOR_STEP_MINUTES:-30}"

view_init() {
    DAYTERM_VIEW="${DAYTERM_REQUESTED_VIEW:-$DEFAULT_VIEW}"
    DAYTERM_SELECTED_DATE="${DAYTERM_REQUESTED_DATE:-$(date +%F)}"

    view_valid_name "$DAYTERM_VIEW" || DAYTERM_VIEW='agenda'
    view_valid_date "$DAYTERM_SELECTED_DATE" || DAYTERM_SELECTED_DATE=$(date +%F)
    view_reset_cursor
    view_apply_query_range
}

view_valid_name() {
    case "$1" in
        agenda|week|month|tasks) return 0 ;;
        *) return 1 ;;
    esac
}

view_valid_date() {
    [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] &&
        [[ "$(date -d "$1" +%F 2>/dev/null)" == "$1" ]]
}

view_name_for_key() {
    case "$1" in
        a) printf 'agenda' ;;
        w) printf 'week' ;;
        m) printf 'month' ;;
        t) printf 'tasks' ;;
    esac
}

view_set() {
    local view="$1"

    view_valid_name "$view" || return 1
    [[ "$DAYTERM_VIEW" == "$view" ]] && return 1
    DAYTERM_VIEW="$view"
    [[ "$view" == "week" ]] && view_reset_cursor
    view_apply_query_range
}

view_move() {
    local key="$1" amount

    case "$DAYTERM_VIEW:$key" in
        tasks:*) return 1 ;;
        week:j) view_move_cursor "$WEEK_CURSOR_STEP_MINUTES"; return ;;
        week:k) view_move_cursor "-$WEEK_CURSOR_STEP_MINUTES"; return ;;
        week:J) amount=7 ;;
        week:K) amount=-7 ;;
        *:h) amount=-1 ;;
        *:l) amount=1 ;;
        agenda:k) amount=-1 ;;
        agenda:j) amount=1 ;;
        *:k) amount=-7 ;;
        *:j) amount=7 ;;
        *) return 1 ;;
    esac

    DAYTERM_SELECTED_DATE=$(date -d "$DAYTERM_SELECTED_DATE $amount days" +%F) || return 1
    view_apply_query_range
}

view_go_today() {
    local today changed=0

    today=$(date +%F)
    if [[ "$DAYTERM_SELECTED_DATE" != "$today" ]]; then
        DAYTERM_SELECTED_DATE="$today"
        changed=1
    fi
    if [[ "$DAYTERM_VIEW" == "week" ]]; then
        view_reset_cursor
        changed=1
    fi
    (( changed )) || return 1
    view_apply_query_range
}

view_reset_cursor() {
    local now_minutes start_minutes end_minutes

    start_minutes=$((WEEK_START_HOUR * 60))
    end_minutes=$((WEEK_END_HOUR * 60))
    now_minutes=$((10#$(date +%H) * 60 + 10#$(date +%M)))
    if [[ "$DAYTERM_SELECTED_DATE" == "$(date +%F)" ]] &&
        (( now_minutes >= start_minutes && now_minutes < end_minutes )); then
        DAYTERM_CURSOR_MINUTES=$((start_minutes + (now_minutes - start_minutes) / WEEK_CURSOR_STEP_MINUTES * WEEK_CURSOR_STEP_MINUTES))
    else
        DAYTERM_CURSOR_MINUTES=$start_minutes
    fi
}

view_move_cursor() {
    local amount="$1" start_minutes end_minutes next

    start_minutes=$((WEEK_START_HOUR * 60))
    end_minutes=$((WEEK_END_HOUR * 60))
    if (( DAYTERM_CURSOR_MINUTES < 0 )); then
        (( amount > 0 )) || return 1
        DAYTERM_CURSOR_MINUTES=$start_minutes
        return 0
    fi
    next=$((DAYTERM_CURSOR_MINUTES + amount))
    if (( next < start_minutes )); then
        DAYTERM_CURSOR_MINUTES=-1
    elif (( next >= end_minutes )); then
        return 1
    else
        DAYTERM_CURSOR_MINUTES=$next
    fi
}

view_apply_query_range() {
    local weekday month_start

    case "$DAYTERM_VIEW" in
        week)
            weekday=$(date -d "$DAYTERM_SELECTED_DATE" +%u)
            DAYTERM_QUERY_START=$(date -d "$DAYTERM_SELECTED_DATE -$((weekday - 1)) days" +%F)
            DAYTERM_QUERY_END=$(date -d "$DAYTERM_QUERY_START +6 days" +%F)
            ;;
        month)
            month_start=$(date -d "$DAYTERM_SELECTED_DATE" +%Y-%m-01)
            DAYTERM_QUERY_START="$month_start"
            DAYTERM_QUERY_END=$(date -d "$month_start +1 month -1 day" +%F)
            ;;
        agenda|tasks)
            DAYTERM_QUERY_START="$DAYTERM_SELECTED_DATE"
            DAYTERM_QUERY_END="$DAYTERM_SELECTED_DATE"
            ;;
    esac
}
