#!/usr/bin/env bash

is_positive_int() {
    [[ "$1" =~ ^[0-9]+$ && "$1" -gt 0 ]]
}

normalize_bool() {
    local name="$1"
    local default="$2"
    local value="${!name}"

    case "$value" in
        true|yes|on) printf -v "$name" '1' ;;
        false|no|off) printf -v "$name" '0' ;;
        0|1) ;;
        *) printf -v "$name" '%s' "$default" ;;
    esac
}

normalize_settings() {
    is_positive_int "$UPDATE_INTERVAL" || UPDATE_INTERVAL=300
    is_positive_int "$TODO_UPDATE_INTERVAL" || TODO_UPDATE_INTERVAL=900
    is_positive_int "$IDLE_TICK_SECONDS" || IDLE_TICK_SECONDS=1
    is_positive_int "$TODO_LIMIT" || TODO_LIMIT=8
    is_positive_int "$NOTIFICATION_CHECK_INTERVAL" || NOTIFICATION_CHECK_INTERVAL=30
    is_positive_int "$NOTIFICATION_DATA_REFRESH_INTERVAL" || NOTIFICATION_DATA_REFRESH_INTERVAL=300
    is_positive_int "$NOTIFICATION_SEND_TIMEOUT_SECONDS" || NOTIFICATION_SEND_TIMEOUT_SECONDS=5
    is_positive_int "$NOTIFICATION_WINDOW_SECONDS" || NOTIFICATION_WINDOW_SECONDS=90
    is_positive_int "$MAX_MISSED_NOTIFICATION_TIME" || MAX_MISSED_NOTIFICATION_TIME=60
    is_positive_int "$MAX_MISSED_NOTIFICATIONS" || MAX_MISSED_NOTIFICATIONS=5
    is_positive_int "$NOTIFICATION_STATE_RETENTION_DAYS" || NOTIFICATION_STATE_RETENTION_DAYS=30

    case "$DEFAULT_VIEW" in
        agenda|week|month|tasks) ;;
        *) DEFAULT_VIEW="agenda" ;;
    esac

    [[ "$WEEK_START_HOUR" =~ ^([0-9]|1[0-9]|2[0-3])$ ]] || WEEK_START_HOUR=7
    [[ "$WEEK_END_HOUR" =~ ^([1-9]|1[0-9]|2[0-4])$ ]] || WEEK_END_HOUR=20
    (( WEEK_END_HOUR > WEEK_START_HOUR )) || {
        WEEK_START_HOUR=7
        WEEK_END_HOUR=20
    }

    case "$TODOS_ENABLED" in
        auto|0|1) ;;
        *) TODOS_ENABLED="auto" ;;
    esac

    normalize_bool NOTIFICATIONS_ENABLED 1
    normalize_bool MISSED_NOTIFICATIONS_ENABLED 1
    normalize_bool TUI_BOXES 1

    case "$TUI_BOX_STYLE" in
        unicode|ascii) ;;
        *) TUI_BOX_STYLE="unicode" ;;
    esac

    case "$COLOR_THEME" in
        auto|dark|light|none) ;;
        *) COLOR_THEME="auto" ;;
    esac

    case "${NOTIFICATION_MISSED:-}" in
        false|no|off|0)
            if ! setting_exists MISSED_NOTIFICATIONS_ENABLED; then
                MISSED_NOTIFICATIONS_ENABLED=0
            fi
            ;;
    esac

    case "$NOTIFICATION_URGENCY" in
        low|normal|critical) ;;
        *) NOTIFICATION_URGENCY="normal" ;;
    esac
}
