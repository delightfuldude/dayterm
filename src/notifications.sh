#!/usr/bin/env bash

DAYTERM_LAST_NOTIFICATION=''

notifications_init() {
    mkdir -p "$DAYTERM_CACHE_DIR"
}

notification_state_file() {
    printf '%s/notified-%s.log\n' "$DAYTERM_CACHE_DIR" "$(date +%Y%m%d)"
}

notification_key_seen() {
    local key="$1"
    local file
    file=$(notification_state_file)

    [[ -f "$file" ]] && grep -qx -- "$key" "$file"
}

notification_mark_seen() {
    local key="$1"
    local file
    file=$(notification_state_file)

    printf '%s\n' "$key" >> "$file"
}

notification_hash() {
    cksum | awk '{print $1 "_" $2}'
}

notifications_send() {
    local title="$1"
    local body="$2"

    if command -v notify-send >/dev/null 2>&1; then
        if notify-send -a "DayTerm" -u "$NOTIFICATION_URGENCY" "$title" "$body" >/dev/null 2>&1; then
            DAYTERM_LAST_NOTIFICATION="$title"
            return 0
        fi
    fi

    if dt_has_tty; then
        printf '\a' >"$DAYTERM_TTY"
        DAYTERM_LAST_NOTIFICATION="$title (terminal bell)"
    fi
}

notifications_check_due() {
    local events_json="$1"
    local now offset window start_epoch target key raw_key title body
    local base_key base_raw diff_minutes missed_count
    local uid start all_day location calendar

    [[ "$NOTIFICATIONS_ENABLED" == "1" ]] || return 0
    test_jq || return 0

    now=$(date +%s)
    window="$NOTIFICATION_WINDOW_SECONDS"
    missed_count=0

    while IFS=$'\037' read -r uid start all_day title location calendar; do
        [[ "$all_day" == "True" ]] && continue
        [[ -n "$start" ]] || continue

        start_epoch=$(calendar_datetime_epoch "$start") || continue
        base_raw="${uid:-$title}|$start|event"
        base_key=$(printf '%s' "$base_raw" | notification_hash)

        for offset in $NOTIFICATION_OFFSETS; do
            [[ "$offset" =~ ^[0-9]+$ ]] || continue
            target=$((start_epoch - offset * 60))

            if (( now >= target && now < target + window )); then
                raw_key="${uid:-$title}|$start|$offset"
                key=$(printf '%s' "$raw_key" | notification_hash)

                if notification_key_seen "$key"; then
                    continue
                fi

                if (( offset == 0 )); then
                    body="Starts now"
                else
                    body="Starts in ${offset} min"
                fi

                [[ -n "$location" ]] && body="${body} - ${location}"
                [[ -n "$calendar" ]] && body="${body} (${calendar})"

                notifications_send "$title" "$body"
                notification_mark_seen "$key"
                notification_mark_seen "$base_key"
            fi
        done

        if [[ "$MISSED_NOTIFICATIONS_ENABLED" == "1" ]] &&
            (( missed_count < MAX_MISSED_NOTIFICATIONS )) &&
            ! notification_key_seen "$base_key"; then
            diff_minutes=$(((now - start_epoch) / 60))

            if (( diff_minutes > 0 && diff_minutes <= MAX_MISSED_NOTIFICATION_TIME )); then
                body="Started ${diff_minutes} min ago"
                [[ -n "$location" ]] && body="${body} - ${location}"
                [[ -n "$calendar" ]] && body="${body} (${calendar})"

                notifications_send "$title" "$body"
                notification_mark_seen "$base_key"
                missed_count=$((missed_count + 1))
            fi
        fi
    done < <(
        jq -r '.[] | [(.uid // ""), (.start // ""), (.["all-day"] // ""), (.title // "(no title)"), (.location // ""), (.calendar // "")] | join("\u001f")' <<< "$events_json" 2>/dev/null
    )
}
