#!/usr/bin/env bash

DAYTERM_TTY="${DAYTERM_TTY:-/dev/tty}"
DAYTERM_TTY_AVAILABLE=0
DAYTERM_WCWIDTH_AVAILABLE=0
DAYTERM_COLOR_ENABLED=0

BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

C_TITLE=''
C_BORDER=''
C_LABEL=''
C_VALUE=''
C_MUTED=''
C_TIME=''
C_EVENT=''
C_CALENDAR=''
C_TODO_ID=''
C_DUE_OVERDUE=''
C_DUE_TODAY=''
C_DUE_FUTURE=''
C_PRIORITY_HIGH=''
C_PRIORITY_MEDIUM=''
C_PRIORITY_LOW=''
C_OK=''
C_WARN=''
C_BAD=''
C_KEY=''

init_runtime() {
    detect_tty
    detect_wcwidth
    init_colors
}

init_colors() {
    local theme="${COLOR_THEME:-auto}"

    DAYTERM_COLOR_ENABLED=0

    if [[ "$theme" == "none" ]]; then
        clear_colors
        return
    fi

    if [[ -n "${NO_COLOR:-}" && "$theme" == "auto" && "${DAYTERM_FORCE_COLOR:-0}" != "1" ]]; then
        clear_colors
        return
    fi

    if ! dt_has_tty && [[ "${DAYTERM_FORCE_COLOR:-0}" != "1" ]]; then
        clear_colors
        return
    fi

    DAYTERM_COLOR_ENABLED=1
    apply_color_theme "$(resolved_color_theme)"
}

clear_colors() {
    local name

    for name in BLUE CYAN GREEN YELLOW RED MAGENTA BOLD DIM NC \
        C_TITLE C_BORDER C_LABEL C_VALUE C_MUTED C_TIME C_EVENT C_CALENDAR \
        C_TODO_ID C_DUE_OVERDUE C_DUE_TODAY C_DUE_FUTURE C_PRIORITY_HIGH \
        C_PRIORITY_MEDIUM C_PRIORITY_LOW C_OK C_WARN C_BAD C_KEY; do
        printf -v "$name" ''
    done
}

resolved_color_theme() {
    local theme="${COLOR_THEME:-auto}"
    local bg

    case "$theme" in
        dark|light)
            printf '%s' "$theme"
            return
            ;;
    esac

    # COLORFGBG usually ends with the background color index.
    if [[ "${COLORFGBG:-}" =~ \;([0-9]+)$ ]]; then
        bg="${BASH_REMATCH[1]}"
        if (( bg == 0 || bg == 1 || bg == 2 || bg == 3 || bg == 4 || bg == 5 || bg == 6 || bg == 8 )); then
            printf 'dark'
        else
            printf 'light'
        fi
    else
        printf 'dark'
    fi
}

apply_color_theme() {
    local theme="$1"

    NC='\033[0m'
    BOLD='\033[1m'
    DIM='\033[2m'

    if [[ "$theme" == "light" ]]; then
        BLUE='\033[38;5;25m'
        CYAN='\033[38;5;31m'
        GREEN='\033[38;5;28m'
        YELLOW='\033[38;5;130m'
        RED='\033[38;5;124m'
        MAGENTA='\033[38;5;89m'

        C_TITLE="${BOLD}${BLUE}"
        C_BORDER='\033[38;5;240m'
        C_LABEL="${BOLD}${CYAN}"
        C_VALUE='\033[38;5;236m'
        C_MUTED='\033[38;5;244m'
        C_TIME="${BOLD}${BLUE}"
        C_EVENT='\033[38;5;236m'
        C_CALENDAR='\033[38;5;60m'
        C_TODO_ID='\033[38;5;244m'
        C_DUE_OVERDUE="${BOLD}${RED}"
        C_DUE_TODAY="${BOLD}${YELLOW}"
        C_DUE_FUTURE="${GREEN}"
        C_PRIORITY_HIGH="${BOLD}${RED}"
        C_PRIORITY_MEDIUM="${YELLOW}"
        C_PRIORITY_LOW='\033[38;5;244m'
        C_OK="${GREEN}"
        C_WARN="${YELLOW}"
        C_BAD="${RED}"
        C_KEY="${BOLD}${CYAN}"
    else
        BLUE='\033[38;5;81m'
        CYAN='\033[38;5;87m'
        GREEN='\033[38;5;114m'
        YELLOW='\033[38;5;222m'
        RED='\033[38;5;203m'
        MAGENTA='\033[38;5;176m'

        C_TITLE="${BOLD}${CYAN}"
        C_BORDER='\033[38;5;245m'
        C_LABEL="${BOLD}${BLUE}"
        C_VALUE='\033[38;5;252m'
        C_MUTED='\033[38;5;244m'
        C_TIME="${BOLD}${BLUE}"
        C_EVENT='\033[38;5;255m'
        C_CALENDAR='\033[38;5;153m'
        C_TODO_ID='\033[38;5;244m'
        C_DUE_OVERDUE="${BOLD}${RED}"
        C_DUE_TODAY="${BOLD}${YELLOW}"
        C_DUE_FUTURE="${GREEN}"
        C_PRIORITY_HIGH="${BOLD}${RED}"
        C_PRIORITY_MEDIUM="${YELLOW}"
        C_PRIORITY_LOW='\033[38;5;244m'
        C_OK="${GREEN}"
        C_WARN="${YELLOW}"
        C_BAD="${RED}"
        C_KEY="${BOLD}${CYAN}"
    fi
}

color_text() {
    local color="$1"
    local text="$2"

    if [[ "$DAYTERM_COLOR_ENABLED" == "1" && -n "$color" ]]; then
        printf '%b%s%b' "$color" "$text" "$NC"
    else
        printf '%s' "$text"
    fi
}

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

detect_tty() {
    DAYTERM_TTY_AVAILABLE=0

    if [[ ( -t 0 || -t 1 || -t 2 ) && -r "$DAYTERM_TTY" && -w "$DAYTERM_TTY" ]] &&
        { : <"$DAYTERM_TTY"; } 2>/dev/null &&
        { : >"$DAYTERM_TTY"; } 2>/dev/null; then
        DAYTERM_TTY_AVAILABLE=1
    fi
}

dt_has_tty() {
    [[ "$DAYTERM_TTY_AVAILABLE" == "1" ]]
}

detect_wcwidth() {
    DAYTERM_WCWIDTH_AVAILABLE=0

    if command -v python3 >/dev/null 2>&1 &&
        python3 -c 'import wcwidth' >/dev/null 2>&1; then
        DAYTERM_WCWIDTH_AVAILABLE=1
    fi
}

dt_out() {
    if dt_has_tty; then
        printf '%b\n' "$*" >"$DAYTERM_TTY"
    else
        printf '%b\n' "$*"
    fi
}

dt_err() {
    if dt_has_tty; then
        printf '%b\n' "$*" >"$DAYTERM_TTY"
    else
        printf '%b\n' "$*" >&2
    fi
}

dt_clear() {
    if dt_has_tty && [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        tput clear >"$DAYTERM_TTY" 2>/dev/null || true
    fi
}

dt_reset_screen() {
    if dt_has_tty && [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        tput sgr0 >"$DAYTERM_TTY" 2>/dev/null || true
    fi
}

dt_hide_cursor() {
    if dt_has_tty && [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        tput civis >"$DAYTERM_TTY" 2>/dev/null || true
    fi
}

dt_show_cursor() {
    if dt_has_tty && [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        tput cnorm >"$DAYTERM_TTY" 2>/dev/null || true
    fi
}

dt_cols() {
    if dt_has_tty && [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        tput cols 2>/dev/null || printf '%s' "${COLUMNS:-80}"
    elif [[ "${COLUMNS:-}" =~ ^[0-9]+$ && "${COLUMNS:-0}" -gt 0 ]]; then
        printf '%s' "$COLUMNS"
    else
        printf '80'
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

dt_has_wcwidth() {
    [[ "$DAYTERM_WCWIDTH_AVAILABLE" == "1" ]]
}

dt_text_cells() {
    local mode="$1"
    local width="$2"

    python3 -c '
import sys
from wcwidth import wcwidth

mode = sys.argv[1]
width = int(sys.argv[2])
text = sys.stdin.read()

def iter_parts(value):
    i = 0
    while i < len(value):
        if value[i] == "\x1b" and i + 1 < len(value) and value[i + 1] == "[":
            j = i + 2
            while j < len(value) and not ("@" <= value[j] <= "~"):
                j += 1
            if j < len(value):
                yield ("ansi", value[i:j + 1])
                i = j + 1
                continue
        yield ("char", value[i])
        i += 1

def text_width(value):
    total = 0
    for part_type, part in iter_parts(value):
        if part_type == "ansi":
            continue
        cell_width = wcwidth(part)
        if cell_width > 0:
            total += cell_width
    return total

def fit(value, max_width):
    if max_width <= 0:
        return ""
    if text_width(value) <= max_width:
        return value
    if max_width <= 3:
        suffix = ""
        content_width = max_width
    else:
        suffix = "..."
        content_width = max_width - text_width(suffix)

    out = []
    used = 0
    saw_ansi = False
    truncated = False
    for part_type, part in iter_parts(value):
        if part_type == "ansi":
            saw_ansi = True
            out.append(part)
            continue
        cell_width = wcwidth(part)
        if cell_width < 0:
            cell_width = 0
        if used + cell_width > content_width:
            truncated = True
            break
        out.append(part)
        used += cell_width
    result = "".join(out) + suffix
    if truncated and saw_ansi:
        result += "\x1b[0m"
    return result

if mode == "width":
    sys.stdout.write(str(text_width(text)))
    raise SystemExit

fitted = fit(text, width)
if mode == "rpad":
    sys.stdout.write(fitted + (" " * max(0, width - text_width(fitted))))
else:
    sys.stdout.write(fitted)
' "$mode" "$width"
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
    label=" ${title} "
    label=$(dt_fit "$label" "$max_label")
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
    local inner_width
    local line
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

dt_pause() {
    dt_out ""
    dt_out "${GREEN}Press any key to return...${NC}"
    if dt_has_tty; then
        read -rsn 1 <"$DAYTERM_TTY"
    fi
}

dt_run_fullscreen() {
    local status

    if dt_has_tty && [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        tput smcup >"$DAYTERM_TTY" 2>/dev/null || true
    fi

    "$@" <"$DAYTERM_TTY" >"$DAYTERM_TTY" 2>&1
    status=$?

    dt_out ""
    dt_out "${GREEN}Command finished. Press any key to return...${NC}"
    if dt_has_tty; then
        read -rsn 1 <"$DAYTERM_TTY"
    fi

    if dt_has_tty && [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        tput rmcup >"$DAYTERM_TTY" 2>/dev/null || true
    fi

    return "$status"
}

print_usage() {
    cat <<'USAGE'
Usage: dayterm.sh [--once] [--check] [--notify-test]

  --once         Render one agenda snapshot and exit.
  --check        Verify runtime dependencies and configuration.
  --notify-test  Send a desktop notification test.
USAGE
}

show_help() {
    dt_clear
    dt_out "${BLUE}${BOLD}DayTerm commands${NC}"
    dt_out ""
    dt_out "e  Event details and edit"
    dt_out "t  Todo details and edit"
    dt_out "n  New event"
    dt_out "a  Add todo"
    dt_out "s  Sync calendars with vdirsyncer"
    dt_out "c  Open ikhal/khal interactive"
    dt_out "i  Edit DayTerm settings"
    dt_out "h  Help"
    dt_out "q  Quit"
    dt_pause
}
