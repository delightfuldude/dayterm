#!/usr/bin/env bash

source_app_module() {
    local module="$1"
    local file="$DAYTERM_SRC/app/$module"

    if [[ ! -f "$file" ]]; then
        printf 'Error: missing app module %s\n' "$file" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$file"
}

source_app_module args.sh
source_app_module keys.sh
source_app_module loop.sh
