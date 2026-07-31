#!/usr/bin/env bash

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
    fi

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
