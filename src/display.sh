#!/usr/bin/env bash

source_display_module() {
    local module="$1"
    local file="$DAYTERM_SRC/display/$module"

    if [[ ! -f "$file" ]]; then
        printf 'Error: missing display module %s\n' "$file" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$file"
}

source_display_module events.sh
source_display_module todos.sh
source_display_module layout.sh
