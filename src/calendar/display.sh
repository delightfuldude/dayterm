#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"

# Source the new display module
source "$SCRIPT_DIR/calendar/display/main.sh"

# Initialize display module
init_display

# Export the show_events function for external use
export -f show_events