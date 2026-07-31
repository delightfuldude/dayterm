#!/usr/bin/env bash

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
