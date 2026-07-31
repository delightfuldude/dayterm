#!/usr/bin/env bash

DAYTERM_TODOS_JSON='[]'
DAYTERM_TODOS_ERROR=''
DAYTERM_TODOS_UPDATED_AT=0

todo_cache_file() {
    printf '%s/todos.json\n' "$DAYTERM_CACHE_DIR"
}

todo_command() {
    if command -v todo >/dev/null 2>&1; then
        command -v todo
    elif command -v todoman >/dev/null 2>&1; then
        command -v todoman
    else
        return 1
    fi
}

todos_should_run() {
    case "$TODOS_ENABLED" in
        1) todo_command >/dev/null 2>&1 ;;
        0) return 1 ;;
        auto) todo_command >/dev/null 2>&1 ;;
    esac
}

refresh_todo_data() {
    local cmd raw_file json_file err_file parsed
    local cache_file

    DAYTERM_TODOS_UPDATED_AT=$(date +%s)

    if ! todos_should_run; then
        DAYTERM_TODOS_JSON='[]'
        DAYTERM_TODOS_ERROR=''
        return 0
    fi

    if ! test_jq; then
        DAYTERM_TODOS_JSON='[]'
        DAYTERM_TODOS_ERROR='jq is required for todo JSON parsing'
        return 1
    fi

    cmd=$(todo_command) || {
        DAYTERM_TODOS_JSON='[]'
        DAYTERM_TODOS_ERROR='todo/todoman not found'
        return 1
    }

    raw_file=$(mktemp)
    json_file=$(mktemp)
    err_file=$(mktemp)

    if ! "$cmd" --porcelain list >"$raw_file" 2>"$err_file"; then
        DAYTERM_TODOS_JSON='[]'
        DAYTERM_TODOS_ERROR="$(sed -n '1p' "$err_file")"
        rm -f "$raw_file" "$json_file" "$err_file"
        return 1
    fi

    awk 'seen || /^\[/ { seen = 1; print }' "$raw_file" > "$json_file"

    if ! parsed=$(jq -c '[.[] | select(.completed == false)]' "$json_file" 2>"$err_file"); then
        DAYTERM_TODOS_JSON='[]'
        DAYTERM_TODOS_ERROR="$(sed -n '1p' "$err_file")"
        rm -f "$raw_file" "$json_file" "$err_file"
        return 1
    fi

    DAYTERM_TODOS_JSON="$parsed"
    DAYTERM_TODOS_ERROR=''
    cache_file=$(todo_cache_file)
    printf '%s\n' "$DAYTERM_TODOS_JSON" > "$cache_file"
    rm -f "$raw_file" "$json_file" "$err_file"
}

load_cached_todo_data() {
    local cache_file

    cache_file=$(todo_cache_file)
    [[ -s "$cache_file" ]] || return 1

    DAYTERM_TODOS_JSON=$(cat "$cache_file")
    DAYTERM_TODOS_ERROR=''
    DAYTERM_TODOS_UPDATED_AT=$(stat -c %Y "$cache_file" 2>/dev/null || printf '0')
}

todo_count() {
    jq -r 'length' <<< "$DAYTERM_TODOS_JSON" 2>/dev/null || printf '0'
}

edit_todo() {
    local cmd summary

    cmd=$(todo_command) || {
        dt_clear
        dt_err "${YELLOW}todo/todoman is not available.${NC}"
        dt_pause
        return 1
    }

    dt_clear
    dt_out "${BLUE}${BOLD}New todo${NC}"
    dt_out ""
    printf 'Summary: ' >"$DAYTERM_TTY"
    read -r summary <"$DAYTERM_TTY"

    [[ -n "$summary" ]] || return 0
    dt_run_fullscreen "$cmd" new "$summary"
}

show_todo_details() {
    local cmd id

    cmd=$(todo_command) || {
        dt_clear
        dt_err "${YELLOW}todo/todoman is not available.${NC}"
        dt_pause
        return 1
    }

    dt_clear
    dt_out "${BLUE}${BOLD}Todos${NC}"
    dt_out ""
    render_todos 50
    dt_out ""
    printf 'Todo id to edit, or Enter to return: ' >"$DAYTERM_TTY"
    read -r id <"$DAYTERM_TTY"

    [[ "$id" =~ ^[0-9]+$ ]] || return 0
    dt_run_fullscreen "$cmd" edit "$id"
    refresh_todo_data
}
