#!/usr/bin/env bash

dt_box_chars() {
    case "${TUI_BOX_STYLE:-unicode}" in
        unicode)
            DT_BOX_TL='┌'
            DT_BOX_TR='┐'
            DT_BOX_BL='└'
            DT_BOX_BR='┘'
            DT_BOX_H='─'
            DT_BOX_V='│'
            ;;
        ascii|*)
            DT_BOX_TL='+'
            DT_BOX_TR='+'
            DT_BOX_BL='+'
            DT_BOX_BR='+'
            DT_BOX_H='-'
            DT_BOX_V='|'
            ;;
    esac
}

dt_box_top() {
    local title="$1"
    local width="$2"
    local fill label max_label

    dt_box_chars
    max_label=$((width - 4))
    label=$(dt_fit " ${title} " "$max_label")
    fill=$((width - 2 - $(visible_length "$label")))

    printf '%b%s%b%b%s%b%b%s%b' \
        "$C_BORDER" "$DT_BOX_TL" "$NC" \
        "$C_TITLE" "$label" "$NC" \
        "$C_BORDER" "$(dt_repeat "$DT_BOX_H" "$fill")$DT_BOX_TR" "$NC"
}

dt_box_bottom() {
    local width="$1"

    dt_box_chars
    printf '%b%s%s%s%b' "$C_BORDER" "$DT_BOX_BL" "$(dt_repeat "$DT_BOX_H" "$((width - 2))")" "$DT_BOX_BR" "$NC"
}

dt_box_line() {
    local text="$1"
    local inner_width="$2"

    dt_box_chars
    printf '%b%s%b %s %b%s%b' "$C_BORDER" "$DT_BOX_V" "$NC" "$(dt_rpad "$text" "$inner_width")" "$C_BORDER" "$DT_BOX_V" "$NC"
}

dt_box() {
    local title="$1"
    local width="$2"
    local inner_width line
    local lines=()

    shift 2

    if (( width < 24 )); then
        dt_out "$title"
        "$@" | while IFS= read -r line; do
            dt_out "$(dt_fit "$line" "$width")"
        done
        return
    fi

    inner_width=$((width - 4))
    mapfile -t lines < <("$@")

    if dt_has_wcwidth; then
        dt_out "$(dt_box_render_wcwidth "$title" "$width" "${lines[@]}")"
        return
    fi

    dt_out "$(dt_box_top "$title" "$width")"

    if (( ${#lines[@]} == 0 )); then
        dt_out "$(dt_box_line "" "$inner_width")"
    else
        for line in "${lines[@]}"; do
            dt_out "$(dt_box_line "$line" "$inner_width")"
        done
    fi

    dt_out "$(dt_box_bottom "$width")"
}

dt_box_render_wcwidth() {
    local title="$1"
    local width="$2"
    local style="${TUI_BOX_STYLE:-unicode}"
    local border_color="$C_BORDER"
    local title_color="$C_TITLE"
    local reset="$NC"

    shift 2
    python3 "$DAYTERM_SRC/ui/box.py" "$title" "$width" "$style" "$border_color" "$title_color" "$reset" "$@"
}
