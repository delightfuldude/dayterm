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

    if [[ -f "$SETTINGS_FILE" ]]; then
        migrate_settings
        return
    fi

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
}
