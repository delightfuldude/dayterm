#!/usr/bin/env bash

DAYTERM_TTY="${DAYTERM_TTY:-/dev/tty}"
DAYTERM_TTY_AVAILABLE=0
DAYTERM_WCWIDTH_AVAILABLE=0
DAYTERM_BUFFERING=0
DAYTERM_OUTPUT_BUFFER=''

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

dt_has_wcwidth() {
    [[ "$DAYTERM_WCWIDTH_AVAILABLE" == "1" ]]
}

dt_out() {
    local rendered

    if [[ "$DAYTERM_BUFFERING" == "1" ]]; then
        printf -v rendered '%b\n' "$*"
        DAYTERM_OUTPUT_BUFFER+="$rendered"
        return
    fi

    if dt_has_tty; then
        printf '%b\n' "$*" >"$DAYTERM_TTY"
    else
        printf '%b\n' "$*"
    fi
}

dt_begin_screen() {
    DAYTERM_BUFFERING=1
    DAYTERM_OUTPUT_BUFFER=''
}

dt_flush_screen() {
    local rendered="$DAYTERM_OUTPUT_BUFFER"

    DAYTERM_BUFFERING=0
    DAYTERM_OUTPUT_BUFFER=''

    if dt_has_tty; then
        printf '%b' "$rendered" >"$DAYTERM_TTY"
    else
        printf '%b' "$rendered"
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
