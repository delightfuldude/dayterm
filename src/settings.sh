#!/usr/bin/env bash

source_settings_module() {
    local module="$1"
    local file="$DAYTERM_SRC/settings/$module"

    if [[ ! -f "$file" ]]; then
        printf 'Error: missing settings module %s\n' "$file" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$file"
}

source_settings_module defaults.sh
source_settings_module migration.sh
source_settings_module normalize.sh
source_settings_module editor.sh
