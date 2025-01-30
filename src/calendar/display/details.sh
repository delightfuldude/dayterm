#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")")

# Source dependencies
source "$SCRIPT_DIR/calendar/core.sh"
source "$SCRIPT_DIR/calendar/display/formatting.sh"
source "$SCRIPT_DIR/calendar/display/events.sh"

# Function to handle event editing
handle_event_edit() {
    local selection="$1"
    local event_data="$2"
    
    if [[ -n $selection ]] && [[ $selection =~ ^[0-9]+$ ]]; then
        IFS='|' read -r date time title calendar <<< "$event_data"
        
        # Check if khal is available
        if ! test_khal; then
            echo -e "${RED}Cannot edit event - khal is not available${NC}" >/dev/tty
            read -n 1 </dev/tty
            return 1
        fi
        
        # Edit event in interactive mode using search string and calendar
        if khal edit --include-calendar "$calendar" "$title" --show-past </dev/tty >/dev/tty 2>/dev/tty; then
            echo -e "${GREEN}Event successfully edited.${NC}" >/dev/tty
        else
            echo -e "${RED}Error editing event.${NC}" >/dev/tty
        fi
        sleep 1
        
        echo >/dev/tty
        echo -e "${GREEN}Press any key to return...${NC}" >/dev/tty
        read -n 1 </dev/tty
    fi
}

# Function to show event details with window size tracking
show_event_details() {
    # Initialize window size tracking
    local old_cols=$(tput cols)
    local old_lines=$(tput lines)
    
    # Function to display content
    display_content() {
        clear >/dev/tty
        echo -e "${BLUE}=== Event Details ===${NC}" >/dev/tty
        echo >/dev/tty
        
        # Create temporary file for event map
        local temp_file=$(mktemp)
        
        # Display event list and get event map
        display_event_list > "$temp_file"
        
        echo >/dev/tty
        echo -e "${GREEN}[e] Edit event, [q] to return...${NC}" >/dev/tty
        
        # Return the temp file path
        echo "$temp_file"
    }

    # Initial display and get event map
    local temp_file=$(display_content)
    if [[ ! -f "$temp_file" ]]; then
        echo -e "${RED}Error: Failed to get event details${NC}" >/dev/tty
        read -n 1 </dev/tty
        return 1
    fi
    
    declare -A event_map
    
    # Read event map from temp file
    while IFS='|' read -r key value; do
        [[ -n "$key" ]] && event_map[$key]="$value"
    done < "$temp_file"
    rm -f "$temp_file"
    
    # Check if we got any events
    if [[ ${#event_map[@]} -eq 0 ]]; then
        echo -e "${BLUE}No events found for today.${NC}" >/dev/tty
        read -n 1 </dev/tty
        return 0
    fi

    # Input loop with window size checking
    while true; do
        local current_cols=$(tput cols)
        local current_lines=$(tput lines)
        
        # Redraw if window size changed
        if [ "$old_cols" -ne "$current_cols" ] || [ "$old_lines" -ne "$current_lines" ]; then
            temp_file=$(display_content)
            while IFS='|' read -r key value; do
                [[ -n "$key" ]] && event_map[$key]="$value"
            done < "$temp_file"
            rm -f "$temp_file"
            old_cols=$current_cols
            old_lines=$current_lines
        fi

        # Check for keyboard input (non-blocking)
        if read -t 1 -n 1 key; then
            case $key in
                e)
                    echo >/dev/tty
                    echo -e "${GREEN}Select an event (1-${#event_map[@]}) or press Enter to cancel:${NC}" >/dev/tty
                    read selection </dev/tty
                    handle_event_edit "$selection" "${event_map[$selection]}"
                    temp_file=$(display_content)
                    while IFS='|' read -r key value; do
                        [[ -n "$key" ]] && event_map[$key]="$value"
                    done < "$temp_file"
                    rm -f "$temp_file"
                    ;;
                q)
                    return
                    ;;
            esac
        fi
    done
}