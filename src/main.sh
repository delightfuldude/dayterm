#!/bin/bash

# Source all required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to source a file with error checking
source_file() {
    local file="$1"
    local full_path="$SCRIPT_DIR/$file"
    if [ ! -f "$full_path" ]; then
        echo "Error: File not found - $full_path" >/dev/tty
        exit 1
    fi
    if ! source "$full_path"; then
        echo "Error: Failed to source $file (exit code $?)" >/dev/tty
        exit 1
    fi
}

# Source utils first as other modules depend on it
source_file "utils.sh"

# Source settings module
source_file "settings.sh"

# Source calendar modules in dependency order
source_file "calendar/core.sh"
source_file "calendar/display.sh"
source_file "calendar/template.sh"
source_file "calendar/create_event.sh"
source_file "calendar/edit_event.sh"

# Source remaining modules
source_file "todos.sh"
source_file "display.sh"

# Verify create_event is available
if ! declare -F create_event >/dev/null; then
    echo "Error: create_event function not found" >/dev/tty
    exit 1
fi

# Trap for clean exit with CTRL+C
trap 'echo -e "\nProgram is terminating..." >/dev/tty; exit' INT

# Load settings
load_settings

# Initial display right after start
display_schedule

# Store initial window size and start time
old_cols=$(tput cols)
old_lines=$(tput lines)
last_update=$(date +%s)

# Main loop with keyboard control
while true; do
    current_time=$(date +%s)
    current_cols=$(tput cols)
    current_lines=$(tput lines)
    
    # Check for updates
    if [ "$old_cols" -ne "$current_cols" ] || \
       [ "$old_lines" -ne "$current_lines" ] || \
       [ $((current_time - last_update)) -ge $UPDATE_INTERVAL ]; then
        display_schedule
        old_cols=$current_cols
        old_lines=$current_lines
        last_update=$current_time
    fi

    # Check for keyboard input (non-blocking)
    if read -t 1 -n 1 key </dev/tty; then
        case $key in
            e)
                show_event_details
                display_schedule
                ;;
            t)
                show_todo_details
                display_schedule
                ;;
            h)
                show_help
                ;;
            n)
                # Save current screen
                tput smcup >/dev/tty
                create_event
                # Restore screen and refresh display
                tput rmcup >/dev/tty
                display_schedule
                ;;
            a)
                edit_todo
                display_schedule
                ;;
            s)
                # Save current screen
                tput smcup >/dev/tty
                vdirsyncer sync >/dev/tty
                # Restore screen and refresh display
                tput rmcup >/dev/tty
                display_schedule
                ;;
            c)
                # Save current screen
                tput smcup >/dev/tty
                ikhal >/dev/tty
                # Restore screen and refresh display
                tput rmcup >/dev/tty
                display_schedule
                ;;
            i)
                edit_settings
                display_schedule
                ;;
            q)
                echo -e "\nProgram is terminating..." >/dev/tty
                exit 0
                ;;
        esac
    fi
done