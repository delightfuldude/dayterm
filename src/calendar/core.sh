#!/bin/bash

# Ensure required environment variables are set
: "${RED:='\033[0;31m'}"
: "${GREEN:='\033[0;32m'}"
: "${BLUE:='\033[0;34m'}"
: "${NC:='\033[0m'}"

# Test if khal is available and configured
test_khal() {
    if ! command -v khal >/dev/null 2>&1; then
        return 1
    fi
    
    # Try to list calendars to check if khal is properly configured
    if ! khal printcalendars >/dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Get available calendars
get_calendars() {
    # Get raw calendar list and clean it up
    khal printcalendars 2>/dev/null | grep -v '^$' | sed 's/[[:space:]]*$//' || echo "No calendars found"
}

# Get raw calendar name for khal command
get_calendar_name() {
    local display_name="$1"
    
    # Debug output
    if [ "${DEBUG:-}" = "true" ]; then
        echo "Looking up calendar: '$display_name'" >/dev/tty
        echo "Available calendars:" >/dev/tty
        khal printcalendars 2>/dev/null | sed 's/^/  /' >/dev/tty
    fi
    
    # Get exact calendar name
    local exact_name=$(khal printcalendars 2>/dev/null | grep "^${display_name}[[:space:]]*$" | sed 's/[[:space:]]*$//')
    
    # Debug output
    if [ "${DEBUG:-}" = "true" ]; then
        echo "Found calendar: '$exact_name'" >/dev/tty
    fi
    
    echo "$exact_name"
}

# Export functions so they're available after sourcing
export -f test_khal
export -f get_calendars
export -f get_calendar_name