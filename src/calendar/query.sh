#!/usr/bin/env bash

calendar_query_events_json() {
    local start="${1:-$DAYTERM_QUERY_START}"
    local end="${2:-$DAYTERM_QUERY_END}"
    local raw_file err_file merged query_start query_end
    local range_args=()

    if ! test_khal; then
        printf 'khal is missing or not configured\n'
        return 1
    fi

    if ! test_jq; then
        printf 'jq is required for stable khal JSON parsing\n'
        return 1
    fi

    query_start=$(calendar_format_query_date "$start") || return 1
    query_end=$(calendar_format_query_date "$end") || return 1
    range_args=("$query_start")
    if [[ "$start" == "$end" ]]; then
        range_args+=("eod")
    else
        range_args+=("$query_end")
    fi

    raw_file=$(mktemp) || return 1
    err_file=$(mktemp) || {
        rm -f "$raw_file"
        return 1
    }

    if ! khal list \
        --json title --json start --json end \
        --json start-date --json start-time --json end-date --json end-time \
        --json all-day --json uid --json calendar --json location \
        --json description --json organizer --json status --json cancelled \
        --json repeat-symbol --json repeat-pattern --json url \
        "${range_args[@]}" >"$raw_file" 2>"$err_file"; then
        sed -n '1,3p' "$err_file"
        rm -f "$raw_file" "$err_file"
        return 1
    fi

    if ! merged=$(jq -c -s '
        (map(select(type == "array")) | add // []) |
        reduce .[] as $event (
            {seen: {}, events: []};
            ([$event.uid, $event.start, $event.end, $event.calendar, $event.title] | @json) as $key |
            if .seen[$key] then .
            else .seen[$key] = true | .events += [$event]
            end
        ) | .events
    ' "$raw_file" 2>"$err_file"); then
        sed -n '1,3p' "$err_file"
        rm -f "$raw_file" "$err_file"
        return 1
    fi

    rm -f "$raw_file" "$err_file"
    printf '%s\n' "$merged"
}
