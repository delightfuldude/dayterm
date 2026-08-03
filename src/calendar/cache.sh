#!/usr/bin/env bash

DAYTERM_EVENTS_JSON='[]'
DAYTERM_EVENTS_ERROR=''
DAYTERM_EVENTS_UPDATED_AT=0
DAYTERM_NOTIFICATION_EVENTS_JSON='[]'

calendar_cache_path() { printf '%s/%s\n' "$DAYTERM_CACHE_DIR" "$1"; }

calendar_store_cache() {
    local data_file="$1" start="$2" end="$3" data="$4" data_tmp

    data_tmp=$(mktemp "$DAYTERM_CACHE_DIR/.events.XXXXXX") || return 1
    printf '{"start":"%s","end":"%s","events":%s}\n' "$start" "$end" "$data" > "$data_tmp"
    chmod 600 "$data_tmp"
    mv -f "$data_tmp" "$data_file"
}

calendar_load_cache() {
    local data_file="$1" start="$2" end="$3"

    [[ -s "$data_file" ]] || return 1
    jq -ce --arg start "$start" --arg end "$end" \
        'select(.start == $start and .end == $end and (.events | type) == "array") | .events' \
        "$data_file" 2>/dev/null
}

refresh_calendar_data() {
    local result data_file

    DAYTERM_EVENTS_UPDATED_AT=$(date +%s)
    if result=$(calendar_query_events_json "$DAYTERM_QUERY_START" "$DAYTERM_QUERY_END"); then
        DAYTERM_EVENTS_JSON="$result"
        DAYTERM_EVENTS_ERROR=''
        data_file=$(calendar_cache_path events.json)
        calendar_store_cache "$data_file" "$DAYTERM_QUERY_START" "$DAYTERM_QUERY_END" "$result"
    else
        DAYTERM_EVENTS_JSON='[]'
        DAYTERM_EVENTS_ERROR="$result"
    fi
}

load_cached_calendar_data() {
    local data_file result

    data_file=$(calendar_cache_path events.json)
    result=$(calendar_load_cache "$data_file" "$DAYTERM_QUERY_START" "$DAYTERM_QUERY_END") || return 1
    DAYTERM_EVENTS_JSON="$result"
    DAYTERM_EVENTS_ERROR=''
    DAYTERM_EVENTS_UPDATED_AT=$(stat -c %Y "$data_file" 2>/dev/null || printf '0')
}

calendar_notification_range() {
    local max_offset=0 offset lookback lookahead start end
    for offset in $NOTIFICATION_OFFSETS; do
        [[ "$offset" =~ ^[0-9]+$ ]] && (( offset > max_offset )) && max_offset=$offset
    done
    lookback=$(((MAX_MISSED_NOTIFICATION_TIME + 1439) / 1440))
    lookahead=$(((max_offset + 1439) / 1440))
    start=$(date -d "today -$lookback days" +%F)
    end=$(date -d "today +$lookahead days" +%F)
    printf '%s\t%s\n' "$start" "$end"
}

refresh_notification_calendar_data() {
    local start end result data_file
    IFS=$'\t' read -r start end < <(calendar_notification_range)
    if result=$(calendar_query_events_json "$start" "$end"); then
        DAYTERM_NOTIFICATION_EVENTS_JSON="$result"
        data_file=$(calendar_cache_path notification-events.json)
        calendar_store_cache "$data_file" "$start" "$end" "$result"
    fi
}

load_cached_notification_calendar_data() {
    local start end data_file result
    IFS=$'\t' read -r start end < <(calendar_notification_range)
    data_file=$(calendar_cache_path notification-events.json)
    result=$(calendar_load_cache "$data_file" "$start" "$end") || return 1
    DAYTERM_NOTIFICATION_EVENTS_JSON="$result"
}

calendar_event_count() {
    jq -r 'length' <<< "$DAYTERM_EVENTS_JSON" 2>/dev/null || printf '0'
}
