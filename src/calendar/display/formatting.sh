#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")")

# Source core functions
source "$SCRIPT_DIR/calendar/core.sh"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to draw separator line
draw_separator() {
    printf -- "---"
}

# Function to format event time
format_event_time() {
    local time="$1"
    printf "%sTime:%s   %s" "$BLUE" "$NC" "$time"
}

# Function to format event title
format_event_title() {
    local title="$1"
    local counter="$2"
    printf "%s[%s]%s %sEvent:%s %s" "$GREEN" "$counter" "$NC" "$BLUE" "$NC" "$title"
}

# Function to format event details
format_event_field() {
    local label="$1"
    local value="$2"
    if [[ -n "$value" ]]; then
        printf "%s%s:%s %s" "$BLUE" "$label" "$NC" "$value"
    fi
}