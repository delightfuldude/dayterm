#!/usr/bin/env bash

load_settings() {
    set_default_settings
    init_settings

    # shellcheck source=/dev/null
    source "$SETTINGS_FILE"
    normalize_settings
}

edit_settings() {
    local editor

    init_settings
    editor="${EDITOR:-nano}"

    dt_run_fullscreen "$editor" "$SETTINGS_FILE"
    load_settings
}
