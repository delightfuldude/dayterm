#!/bin/bash

# ANSI Colors
export BLUE='\033[0;34m'
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

# Test khal availability
test_khal() {
    if ! command -v khal &> /dev/null; then
        echo -e "${RED}khal is not installed!${NC}" >/dev/tty
        return 1
    fi
    
    # Test khal functionality
    if ! khal list today today &> /dev/null; then
        echo -e "${RED}khal appears to be not properly configured!${NC}" >/dev/tty
        return 1
    fi
    
    return 0
}

# Function for decorative line
line() {
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '*' >/dev/tty
}

# Function for help menu
show_help() {
    echo -e "${BLUE}Available Commands:${NC}" >/dev/tty
    echo "e - Show event details (e to edit)" >/dev/tty
    echo "t - Show todo details (e to edit)" >/dev/tty
    echo "n - New event" >/dev/tty
    echo "a - Add todo" >/dev/tty
    echo "s - Server sync" >/dev/tty
    echo "c - Calendar (ikhal)" >/dev/tty
    echo "i - Settings" >/dev/tty
    echo "h - Show this help" >/dev/tty
    echo "q - Quit" >/dev/tty
    echo >/dev/tty
    sleep 3
}