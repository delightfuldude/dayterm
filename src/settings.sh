#!/usr/bin/env bash

SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dayterm"
SETTINGS_FILE="$SETTINGS_DIR/settings.conf"
DAYTERM_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dayterm"

set_default_settings() {
    UPDATE_INTERVAL=300
    TODO_UPDATE_INTERVAL=900
    IDLE_TICK_SECONDS=1

    AGENDA_START="today"
    AGENDA_END="eod"

    TODOS_ENABLED="auto"
    TODO_LIMIT=8

    NOTIFICATIONS_ENABLED=1
    NOTIFICATION_OFFSETS="15 5 0"
    NOTIFICATION_CHECK_INTERVAL=30
    NOTIFICATION_WINDOW_SECONDS=90
    NOTIFICATION_URGENCY="normal"
    MISSED_NOTIFICATIONS_ENABLED=1
    MAX_MISSED_NOTIFICATION_TIME=60
    MAX_MISSED_NOTIFICATIONS=5

    TUI_BOXES=1
    TUI_BOX_STYLE="unicode"
    COLOR_THEME="auto"
}

init_settings() {
    mkdir -p "$SETTINGS_DIR" "$DAYTERM_CACHE_DIR"

    if [[ ! -f "$SETTINGS_FILE" ]]; then
        cat > "$SETTINGS_FILE" <<'EOL'
# DayTerm settings

# Expensive calendar refresh interval in seconds.
UPDATE_INTERVAL=300

# Todo refresh interval in seconds. Todoman can be slower than khal.
TODO_UPDATE_INTERVAL=900

# Main loop sleep/read interval. Keep this at 1 for responsive keys.
IDLE_TICK_SECONDS=1

# khal date range arguments for the main agenda.
AGENDA_START="today"
AGENDA_END="eod"

# auto, 1, or 0. auto uses todo/todoman if available.
TODOS_ENABLED="auto"
TODO_LIMIT=8

# Desktop notifications. Offsets are minutes before the event start.
NOTIFICATIONS_ENABLED=1
NOTIFICATION_OFFSETS="15 5 0"
NOTIFICATION_CHECK_INTERVAL=30
NOTIFICATION_WINDOW_SECONDS=90
NOTIFICATION_URGENCY="normal"
MISSED_NOTIFICATIONS_ENABLED=1
MAX_MISSED_NOTIFICATION_TIME=60
MAX_MISSED_NOTIFICATIONS=5

# TUI layout. TUI_BOX_STYLE can be unicode or ascii.
TUI_BOXES=1
TUI_BOX_STYLE="unicode"
COLOR_THEME="auto"
EOL
    fi

    migrate_settings
}

setting_exists() {
    local key="$1"
    grep -Eq "^[[:space:]]*${key}=" "$SETTINGS_FILE"
}

legacy_notification_enabled() {
    if grep -Eiq '^[[:space:]]*NOTIFICATION_ENABLED=(false|0|no|off)' "$SETTINGS_FILE"; then
        printf '0'
    else
        printf '1'
    fi
}

legacy_missed_notifications_enabled() {
    if grep -Eiq '^[[:space:]]*NOTIFICATION_MISSED=(false|0|no|off)' "$SETTINGS_FILE"; then
        printf '0'
    else
        printf '1'
    fi
}

migrate_settings() {
    local wrote_header=0
    local notification_enabled
    local missed_enabled

    notification_enabled=$(legacy_notification_enabled)
    missed_enabled=$(legacy_missed_notifications_enabled)

    append_setting() {
        local line="$1"

        if (( ! wrote_header )); then
            printf '\n# Added by DayTerm settings migration\n' >> "$SETTINGS_FILE"
            wrote_header=1
        fi

        printf '%s\n' "$line" >> "$SETTINGS_FILE"
    }

    setting_exists TODO_UPDATE_INTERVAL || append_setting 'TODO_UPDATE_INTERVAL=900'
    setting_exists IDLE_TICK_SECONDS || append_setting 'IDLE_TICK_SECONDS=1'
    setting_exists AGENDA_START || append_setting 'AGENDA_START="today"'
    setting_exists AGENDA_END || append_setting 'AGENDA_END="eod"'
    setting_exists TODOS_ENABLED || append_setting 'TODOS_ENABLED="auto"'
    setting_exists TODO_LIMIT || append_setting 'TODO_LIMIT=8'
    setting_exists NOTIFICATIONS_ENABLED || append_setting "NOTIFICATIONS_ENABLED=${notification_enabled}"
    setting_exists NOTIFICATION_OFFSETS || append_setting 'NOTIFICATION_OFFSETS="15 5 0"'
    setting_exists NOTIFICATION_CHECK_INTERVAL || append_setting 'NOTIFICATION_CHECK_INTERVAL=30'
    setting_exists NOTIFICATION_WINDOW_SECONDS || append_setting 'NOTIFICATION_WINDOW_SECONDS=90'
    setting_exists NOTIFICATION_URGENCY || append_setting 'NOTIFICATION_URGENCY="normal"'
    setting_exists MISSED_NOTIFICATIONS_ENABLED || append_setting "MISSED_NOTIFICATIONS_ENABLED=${missed_enabled}"
    setting_exists MAX_MISSED_NOTIFICATION_TIME || append_setting 'MAX_MISSED_NOTIFICATION_TIME=60'
    setting_exists MAX_MISSED_NOTIFICATIONS || append_setting 'MAX_MISSED_NOTIFICATIONS=5'
    setting_exists TUI_BOXES || append_setting 'TUI_BOXES=1'
    setting_exists TUI_BOX_STYLE || append_setting 'TUI_BOX_STYLE="unicode"'
    setting_exists COLOR_THEME || append_setting 'COLOR_THEME="auto"'
}

is_positive_int() {
    [[ "$1" =~ ^[0-9]+$ && "$1" -gt 0 ]]
}

normalize_settings() {
    is_positive_int "$UPDATE_INTERVAL" || UPDATE_INTERVAL=300
    is_positive_int "$TODO_UPDATE_INTERVAL" || TODO_UPDATE_INTERVAL=900
    is_positive_int "$IDLE_TICK_SECONDS" || IDLE_TICK_SECONDS=1
    is_positive_int "$TODO_LIMIT" || TODO_LIMIT=8
    is_positive_int "$NOTIFICATION_CHECK_INTERVAL" || NOTIFICATION_CHECK_INTERVAL=30
    is_positive_int "$NOTIFICATION_WINDOW_SECONDS" || NOTIFICATION_WINDOW_SECONDS=90
    is_positive_int "$MAX_MISSED_NOTIFICATION_TIME" || MAX_MISSED_NOTIFICATION_TIME=60
    is_positive_int "$MAX_MISSED_NOTIFICATIONS" || MAX_MISSED_NOTIFICATIONS=5

    [[ -n "$AGENDA_START" ]] || AGENDA_START="today"
    [[ -n "$AGENDA_END" ]] || AGENDA_END="eod"

    case "$TODOS_ENABLED" in
        auto|0|1) ;;
        *) TODOS_ENABLED="auto" ;;
    esac

    case "$NOTIFICATIONS_ENABLED" in
        true|yes|on) NOTIFICATIONS_ENABLED=1 ;;
        false|no|off) NOTIFICATIONS_ENABLED=0 ;;
        0|1) ;;
        *) NOTIFICATIONS_ENABLED=1 ;;
    esac

    case "$MISSED_NOTIFICATIONS_ENABLED" in
        true|yes|on) MISSED_NOTIFICATIONS_ENABLED=1 ;;
        false|no|off) MISSED_NOTIFICATIONS_ENABLED=0 ;;
        0|1) ;;
        *) MISSED_NOTIFICATIONS_ENABLED=1 ;;
    esac

    case "$TUI_BOXES" in
        true|yes|on) TUI_BOXES=1 ;;
        false|no|off) TUI_BOXES=0 ;;
        0|1) ;;
        *) TUI_BOXES=1 ;;
    esac

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

load_settings() {
    set_default_settings
    init_settings

    # shellcheck source=/dev/null
    source "$SETTINGS_FILE"
    normalize_settings
}

edit_settings() {
    local editor

    init_settings
    editor="${EDITOR:-nano}"

    dt_run_fullscreen "$editor" "$SETTINGS_FILE"
    load_settings
}
