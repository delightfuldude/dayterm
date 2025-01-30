#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")")

# Source dependencies
source "$SCRIPT_DIR/calendar/core.sh"
source "$SCRIPT_DIR/calendar/display/formatting.sh"

# Function to get events from khal
get_events() {
    local temp_file=$(mktemp)
    
    # Check if khal is available
    if ! test_khal; then
        echo -e "${RED}Error: khal is not available${NC}" >/dev/tty
        rm -f "$temp_file"
        return 1
    fi
    
    # Try to get events
    if ! khal list --format "{start-date}|{start-time}-{end-time}|{title}|{calendar}|{location}|{description}|{status}|{repeat-pattern}|{alarm-symbol}|{categories}|{url}" --day-format "" today today > "$temp_file" 2>&1; then
        echo -e "${RED}Error: Failed to get events from khal${NC}" >/dev/tty
        cat "$temp_file" >/dev/tty  # Show error message from khal
        rm -f "$temp_file"
        return 1
    fi
    
    echo "$temp_file"
}

# Function to display event list
display_event_list() {
    local temp_file=$(get_events)
    local counter=1
    declare -A event_map
    local has_events=false
    local output=""
    
    # Process events from khal output
    while IFS='|' read -r date time title calendar location description status repeat alarm categories url || [ -n "$date" ]; do
        # Skip empty lines or non-event lines
        [[ -z "$date" ]] && continue
        [[ ! "$date" =~ ^[0-9]{2}/[0-9]{2}/[0-9]{4}$ ]] && continue
        [[ ! "$time" =~ ^[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}$ ]] && continue
        
        has_events=true
        
        # Build formatted output string with required fields
        output+="$(format_event_title "$title" "$counter")"$'\n'
        output+="$(format_event_field "Date" "$date")"$'\n'
        output+="$(format_event_time "$time")"$'\n'
        output+="$(format_event_field "Calendar" "$calendar")"$'\n'
        
        # Only add optional fields if they have content
        [[ -n "$location" ]] && output+="$(format_event_field "Location" "$location")"$'\n'
        [[ -n "$description" ]] && output+="$(format_event_field "Description" "$description")"$'\n'
        [[ -n "$status" ]] && output+="$(format_event_field "Status" "$status")"$'\n'
        [[ -n "$repeat" ]] && output+="$(format_event_field "Repeat" "$repeat")"$'\n'
        [[ -n "$alarm" ]] && output+="$(format_event_field "Alarm" "$alarm")"$'\n'
        [[ -n "$categories" ]] && output+="$(format_event_field "Category" "$categories")"$'\n'
        [[ -n "$url" ]] && output+="$(format_event_field "URL" "$url")"$'\n'
        
        # Add separator with one newline for spacing between events
        output+="$(draw_separator)"$'\n'
        
        # Store event information
        event_map[$counter]="$date|$time|$title|$calendar"
        ((counter++))
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    # If no events were found, add message to output
    if ! $has_events; then
        output+="${BLUE}No events found for today.${NC}"$'\n\n'
    fi
    
    # Display the formatted output
    echo -e "$output" >/dev/tty
    
    # Return event map
    for key in "${!event_map[@]}"; do
        echo "${key}|${event_map[$key]}"
    done
}