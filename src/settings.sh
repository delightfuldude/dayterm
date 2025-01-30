#!/bin/bash

# Default settings
SETTINGS_DIR="$HOME/.config/dayterm"
SETTINGS_FILE="$SETTINGS_DIR/settings.conf"

# Initialize settings with defaults if not exists
init_settings() {
    if [ ! -d "$SETTINGS_DIR" ]; then
        mkdir -p "$SETTINGS_DIR"
    fi
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        cat > "$SETTINGS_FILE" << EOL
# DayTerm Settings
# Modify values as needed

# Auto-refresh interval in seconds (default: 300)
UPDATE_INTERVAL=300
EOL
    fi
}

# Load settings into environment
load_settings() {
    if [ -f "$SETTINGS_FILE" ]; then
        # Source the settings file
        source "$SETTINGS_FILE"
    else
        init_settings
        source "$SETTINGS_FILE"
    fi
}

# Open settings in editor
edit_settings() {
    # Ensure settings file exists
    init_settings
    
    # Determine editor (use EDITOR env var or fallback to nano)
    local editor=${EDITOR:-nano}
    
    # Save current screen
    tput smcup >/dev/tty
    
    # Open settings in editor
    $editor "$SETTINGS_FILE" </dev/tty >/dev/tty
    
    # Restore screen
    tput rmcup >/dev/tty
    
    # Reload settings
    load_settings
}