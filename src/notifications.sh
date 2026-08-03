#!/usr/bin/env bash

DAYTERM_LAST_NOTIFICATION=''
declare -A DAYTERM_NOTIFICATION_KEYS=()

notification_state_file() {
    printf '%s/notifications.state\n' "$DAYTERM_CACHE_DIR"
}

notification_lock_file() {
    printf '%s/notifications.lock\n' "$DAYTERM_CACHE_DIR"
}

notifications_prune_state() {
    local file="$1" cutoff="$2" temp

    temp=$(mktemp "$DAYTERM_CACHE_DIR/.notifications.XXXXXX") || return 1
    if ! awk -F '\t' -v cutoff="$cutoff" '$1 ~ /^[0-9]+$/ && $1 >= cutoff' "$file" > "$temp"; then
        rm -f "$temp"
        return 1
    fi
    chmod 600 "$temp"
    mv -f "$temp" "$file"
}

notifications_init() {
    local file lock_file cutoff epoch key

    mkdir -p "$DAYTERM_CACHE_DIR"
    file=$(notification_state_file)
    lock_file=$(notification_lock_file)
    touch "$file"
    touch "$lock_file"
    chmod 600 "$file" "$lock_file"
    cutoff=$(($(date +%s) - NOTIFICATION_STATE_RETENTION_DAYS * 86400))
    if command -v flock >/dev/null 2>&1; then
        (flock -x 9 && notifications_prune_state "$file" "$cutoff") 9>> "$lock_file" || return 1
    else
        notifications_prune_state "$file" "$cutoff" || return 1
    fi

    DAYTERM_NOTIFICATION_KEYS=()
    while IFS=$'\t' read -r epoch key; do
        [[ -n "$key" ]] && DAYTERM_NOTIFICATION_KEYS["$key"]=1
    done < "$file"
}

notification_key_seen() {
    [[ -n "${DAYTERM_NOTIFICATION_KEYS[$1]+present}" ]]
}

notification_mark_seen() {
    notification_mark_delivery "$1" '' "${2:-$(date +%s)}"
}

notification_mark_delivery() {
    local key="$1" base_key="$2" epoch="${3:-$(date +%s)}" file lock_file payload='' line

    if ! notification_key_seen "$key"; then
        printf -v line '%s\t%s\n' "$epoch" "$key"
        payload+="$line"
    fi
    if [[ -n "$base_key" ]] && ! notification_key_seen "$base_key"; then
        printf -v line '%s\t%s\n' "$epoch" "$base_key"
        payload+="$line"
    fi
    [[ -n "$payload" ]] || return 0
    file=$(notification_state_file)
    lock_file=$(notification_lock_file)
    if command -v flock >/dev/null 2>&1; then
        (flock -x 9 && printf '%s' "$payload" >> "$file") 9>> "$lock_file" || return 1
    else
        printf '%s' "$payload" >> "$file" || return 1
    fi
    DAYTERM_NOTIFICATION_KEYS["$key"]=1
    [[ -n "$base_key" ]] && DAYTERM_NOTIFICATION_KEYS["$base_key"]=1
}

notifications_send() {
    local title="$1" body="$2" status=1

    if command -v notify-send >/dev/null 2>&1; then
        if command -v timeout >/dev/null 2>&1; then
            if timeout "${NOTIFICATION_SEND_TIMEOUT_SECONDS}s" \
                notify-send -a "DayTerm" -u "$NOTIFICATION_URGENCY" "$title" "$body" >/dev/null 2>&1; then
                status=0
            fi
        else
            if notify-send -a "DayTerm" -u "$NOTIFICATION_URGENCY" "$title" "$body" >/dev/null 2>&1; then
                status=0
            fi
        fi
        if (( status == 0 )); then
            DAYTERM_LAST_NOTIFICATION="$title"
            return 0
        fi
    fi

    if dt_has_tty; then
        printf '\a' > "$DAYTERM_TTY"
        DAYTERM_LAST_NOTIFICATION="$title (terminal bell)"
        return 0
    fi
    return 1
}

notifications_check_due() {
    local events_json="$1" now key base_key title body

    [[ "$NOTIFICATIONS_ENABLED" == "1" ]] || return 0
    command -v python3 >/dev/null 2>&1 || return 0
    calendar_detect_date_order
    now="${DAYTERM_NOW_EPOCH:-$(date +%s)}"

    while IFS=$'\037' read -r key base_key title body; do
        [[ -n "$key" ]] || continue
        notification_key_seen "$key" && continue
        if notifications_send "$title" "$body"; then
            notification_mark_delivery "$key" "$base_key" "$now"
        fi
    done < <(
        python3 "$DAYTERM_SRC/notifications/due.py" \
            "$DAYTERM_DATE_ORDER" "$now" "$NOTIFICATION_OFFSETS" \
            "$NOTIFICATION_WINDOW_SECONDS" "$MISSED_NOTIFICATIONS_ENABLED" \
            "$MAX_MISSED_NOTIFICATION_TIME" "$MAX_MISSED_NOTIFICATIONS" \
            "$(notification_state_file)" <<< "$events_json"
    )
}
