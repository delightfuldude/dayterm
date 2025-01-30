#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Source the main script
source "$SCRIPT_DIR/src/main.sh" || {
    echo "Error: Failed to source main.sh"
    exit 1
}

# Start the main loop
while true; do
    # The main loop is now in main.sh
    sleep infinity
done