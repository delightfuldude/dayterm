#!/usr/bin/env bash

DAYTERM_EVENTS_JSON='[]'
DAYTERM_EVENTS_ERROR=''
DAYTERM_EVENTS_UPDATED_AT=0
DAYTERM_DATE_ORDER=''

calendar_cache_file() {
    printf '%s/events.json\n' "$DAYTERM_CACHE_DIR"
}

test_khal() {
    command -v khal >/dev/null 2>&1 && khal printcalendars >/dev/null 2>&1
}

test_jq() {
    command -v jq >/dev/null 2>&1
}

get_calendars() {
    khal printcalendars 2>/dev/null | sed '/^[[:space:]]*$/d;s/[[:space:]]*$//'
}

calendar_detect_date_order() {
    local sample
    local digits
    local a b c

    [[ -n "$DAYTERM_DATE_ORDER" ]] && return 0

    sample=$(khal printformats 2>/dev/null | awk -F': ' '/^dateformat:/ {print $2; exit}')
    digits=${sample//[!0-9]/ }
    read -r a b c <<< "$digits"

    if [[ "$a" == "2013" ]]; then
        DAYTERM_DATE_ORDER="ymd"
    elif [[ "$a" == "21" ]]; then
        DAYTERM_DATE_ORDER="dmy"
    elif [[ "$b" == "21" ]]; then
        DAYTERM_DATE_ORDER="mdy"
    else
        DAYTERM_DATE_ORDER="dmy"
    fi
}

calendar_datetime_epoch() {
    local value="$1"
    local date_part time_part
    local hour minute
    local digits a b c
    local year month day

    calendar_detect_date_order

    [[ "$value" == *" "* ]] || return 1
    date_part="${value%% *}"
    time_part="${value#* }"

    [[ "$time_part" =~ ^([0-9]{1,2}):([0-9]{2}) ]] || return 1
    hour="${BASH_REMATCH[1]}"
    minute="${BASH_REMATCH[2]}"

    digits=${date_part//[!0-9]/ }
    read -r a b c <<< "$digits"

    case "$DAYTERM_DATE_ORDER" in
        ymd)
            year="$a"; month="$b"; day="$c"
            ;;
        mdy)
            month="$a"; day="$b"; year="$c"
            ;;
        dmy|*)
            day="$a"; month="$b"; year="$c"
            ;;
    esac

    [[ -n "$year" && -n "$month" && -n "$day" ]] || return 1
    date -d "$(printf '%04d-%02d-%02d %02d:%02d' "$year" "$month" "$day" "$hour" "$minute")" +%s 2>/dev/null
}

calendar_query_events_json() {
    local raw_file err_file merged

    if ! test_khal; then
        printf 'khal is missing or not configured\n'
        return 1
    fi

    if ! test_jq; then
        printf 'jq is required for stable khal JSON parsing\n'
        return 1
    fi

    raw_file=$(mktemp)
    err_file=$(mktemp)

    if ! khal list \
        --json title \
        --json start \
        --json end \
        --json start-date \
        --json start-time \
        --json end-date \
        --json end-time \
        --json all-day \
        --json uid \
        --json calendar \
        --json location \
        --json description \
        --json organizer \
        --json status \
        --json cancelled \
        --json repeat-symbol \
        --json repeat-pattern \
        --json url \
        "$AGENDA_START" "$AGENDA_END" >"$raw_file" 2>"$err_file"; then
        printf '%s\n' "$(sed -n '1,3p' "$err_file")"
        rm -f "$raw_file" "$err_file"
        return 1
    fi

    if ! merged=$(jq -c -s 'map(select(type == "array")) | add // []' "$raw_file" 2>"$err_file"); then
        printf '%s\n' "$(sed -n '1,3p' "$err_file")"
        rm -f "$raw_file" "$err_file"
        return 1
    fi

    rm -f "$raw_file" "$err_file"
    printf '%s\n' "$merged"
}

refresh_calendar_data() {
    local result
    local cache_file

    if result=$(calendar_query_events_json); then
        DAYTERM_EVENTS_JSON="$result"
        DAYTERM_EVENTS_ERROR=''
        DAYTERM_EVENTS_UPDATED_AT=$(date +%s)
        cache_file=$(calendar_cache_file)
        printf '%s\n' "$DAYTERM_EVENTS_JSON" > "$cache_file"
    else
        DAYTERM_EVENTS_JSON='[]'
        DAYTERM_EVENTS_ERROR="$result"
        DAYTERM_EVENTS_UPDATED_AT=$(date +%s)
    fi
}

load_cached_calendar_data() {
    local cache_file

    cache_file=$(calendar_cache_file)
    [[ -s "$cache_file" ]] || return 1

    DAYTERM_EVENTS_JSON=$(cat "$cache_file")
    DAYTERM_EVENTS_ERROR=''
    DAYTERM_EVENTS_UPDATED_AT=$(stat -c %Y "$cache_file" 2>/dev/null || printf '0')
}

calendar_event_count() {
    jq -r 'length' <<< "$DAYTERM_EVENTS_JSON" 2>/dev/null || printf '0'
}
