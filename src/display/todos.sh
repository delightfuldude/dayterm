#!/usr/bin/env bash

render_todos() {
    local limit="${1:-8}"
    local max_width="${2:-80}"
    local line

    render_todos_lines "$limit" | while IFS= read -r line; do
        dt_out "$(dt_fit "$line" "$max_width")"
    done
}

render_todos_lines() {
    local limit="${1:-8}"
    local id summary due_text priority list due_bucket line
    local due_color priority_color today_start tomorrow_start

    if [[ "$TODOS_ENABLED" == "0" ]]; then
        printf '%s\n' "$(color_text "$C_MUTED" "Disabled.")"
        return
    fi

    if [[ -n "$DAYTERM_TODOS_ERROR" ]]; then
        printf '%s %s\n' "$(color_text "$C_WARN" "Todo warning:")" "$DAYTERM_TODOS_ERROR"
        return
    fi

    if [[ "$(todo_count)" == "0" ]]; then
        printf '%s\n' "$(color_text "$C_MUTED" "No open todos.")"
        return
    fi

    today_start=$(date -d 'today 00:00' +%s)
    tomorrow_start=$((today_start + 86400))

    while IFS=$'\037' read -r id summary due_text priority list due_bucket; do
        case "$due_bucket" in
            overdue) due_color="$C_DUE_OVERDUE" ;;
            today) due_color="$C_DUE_TODAY" ;;
            future) due_color="$C_DUE_FUTURE" ;;
            *) due_color="$C_MUTED" ;;
        esac

        if (( priority >= 5 )); then
            priority_color="$C_PRIORITY_HIGH"
        elif (( priority >= 3 )); then
            priority_color="$C_PRIORITY_MEDIUM"
        else
            priority_color="$C_PRIORITY_LOW"
        fi

        line="$(color_text "$C_TODO_ID" "#$id") $(color_text "$due_color" "$(printf '%-10s' "$due_text")") $(color_text "$priority_color" "P$priority") $(color_text "$C_VALUE" "$summary") $(color_text "$C_CALENDAR" "[$list]")"
        printf '%s\n' "$line"
    done < <(
        jq -r --argjson limit "$limit" --argjson today "$today_start" --argjson tomorrow "$tomorrow_start" '
            sort_by((.due // 32503680000), -(.priority // 0), (.summary // "")) |
            .[:$limit][] |
            (.due // null) as $due |
            [
                ((.id // "") | tostring),
                (.summary // "(no title)"),
                (if ($due | type) == "number" then ($due | strflocaltime("%Y-%m-%d")) else "no due" end),
                ((.priority // 0) | tostring),
                (.list // ""),
                (if ($due | type) != "number" then "none"
                 elif $due < $today then "overdue"
                 elif $due < $tomorrow then "today"
                 else "future" end)
            ] | join("\u001f")
        ' <<< "$DAYTERM_TODOS_JSON" 2>/dev/null
    )
}
