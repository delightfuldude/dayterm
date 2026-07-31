#!/usr/bin/env bash

strip_ansi() {
    sed -E $'s/\x1B\\[[0-9;?]*[ -/]*[@-~]//g'
}

visible_length() {
    local text="$1"

    if dt_has_wcwidth; then
        printf '%s' "$text" | dt_text_cells width 0
    else
        text=$(printf '%s' "$text" | strip_ansi)
        printf '%s' "${#text}"
    fi
}

dt_line() {
    local char="${1:--}"
    local cols
    cols=$(dt_cols)
    printf '%*s\n' "$cols" '' | tr ' ' "$char"
}

dt_repeat() {
    local char="$1"
    local count="$2"
    local out=''
    local i

    (( count > 0 )) || return 0

    for ((i = 0; i < count; i++)); do
        out+="$char"
    done

    printf '%s' "$out"
}

dt_text_cells() {
    local mode="$1"
    local width="$2"

    python3 "$DAYTERM_SRC/ui/text_cells.py" "$mode" "$width"
}

dt_fit() {
    local text="$1"
    local max="${2:-80}"
    local len

    if dt_has_wcwidth; then
        printf '%s' "$text" | dt_text_cells fit "$max"
        return
    fi

    if (( max <= 3 )); then
        printf '%.*s' "$max" "$text"
        return
    fi

    len=${#text}
    if (( len > max )); then
        printf '%s...' "${text:0:max - 3}"
    else
        printf '%s' "$text"
    fi
}

dt_rpad() {
    local text="$1"
    local width="$2"
    local len pad

    if dt_has_wcwidth; then
        printf '%s' "$text" | dt_text_cells rpad "$width"
        return
    fi

    text=$(dt_fit "$text" "$width")
    len=${#text}
    pad=$((width - len))

    if (( pad > 0 )); then
        printf '%s%s' "$text" "$(dt_repeat ' ' "$pad")"
    else
        printf '%s' "$text"
    fi
}
