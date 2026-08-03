#!/usr/bin/env bash

source_calendar_module() {
    local module="$1"
    local file="$DAYTERM_SRC/calendar/$module"

    if [[ ! -f "$file" ]]; then
        printf 'Error: missing calendar module %s\n' "$file" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$file"
}

source_calendar_module datetime.sh
source_calendar_module query.sh
source_calendar_module cache.sh
