#!/usr/bin/env bash

dayterm_check() {
    local rc=0

    printf 'DayTerm root: %s\n' "$DAYTERM_ROOT"

    if test_khal; then
        printf 'khal: OK (%s)\n' "$(khal --version 2>/dev/null)"
    else
        printf 'khal: missing or not configured\n'
        rc=1
    fi

    if test_jq; then
        printf 'jq: OK (%s)\n' "$(jq --version 2>/dev/null)"
    else
        printf 'jq: missing\n'
        rc=1
    fi

    if command -v python3 >/dev/null 2>&1; then
        printf 'python3: OK (%s)\n' "$(python3 --version 2>&1)"
    else
        printf 'python3: missing\n'
        rc=1
    fi

    if command -v vdirsyncer >/dev/null 2>&1; then
        printf 'vdirsyncer: OK (%s)\n' "$(vdirsyncer --version 2>/dev/null)"
    else
        printf 'vdirsyncer: optional, missing\n'
    fi

    if todo_command >/dev/null 2>&1; then
        printf 'todo: OK (%s)\n' "$(todo_command)"
    else
        printf 'todo: optional, missing\n'
    fi

    if command -v notify-send >/dev/null 2>&1; then
        printf 'notify-send: OK\n'
    else
        printf 'notify-send: optional, missing\n'
    fi

    if dt_has_wcwidth; then
        printf 'wcwidth: OK\n'
    else
        printf 'wcwidth: optional, using standard-library width fallback\n'
    fi

    printf 'settings: %s\n' "$SETTINGS_FILE"
    printf 'cache: %s\n' "$DAYTERM_CACHE_DIR"

    return "$rc"
}
