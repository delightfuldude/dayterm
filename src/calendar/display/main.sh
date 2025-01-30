#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")")

# Source dependencies
source "$SCRIPT_DIR/calendar/core.sh"
source "$SCRIPT_DIR/calendar/display/formatting.sh"
source "$SCRIPT_DIR/calendar/display/events.sh"
source "$SCRIPT_DIR/calendar/display/details.sh"

# Function to initialize display module
init_display() {
    # Check if khal is available
    if ! test_khal; then
        echo -e "${RED}Error: khal is not available${NC}" >/dev/tty
        return 1
    fi
}

# Function to show events
show_events() {
    show_event_details
}

# Export functions
export -f show_events
export -f init_display