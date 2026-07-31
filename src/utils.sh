#!/usr/bin/env bash

DAYTERM_SRC="${DAYTERM_SRC:-$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)}"

source_ui_module() {
    local module="$1"
    local file="$DAYTERM_SRC/ui/$module"

    if [[ ! -f "$file" ]]; then
        printf 'Error: missing UI module %s\n' "$file" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$file"
}

source_ui_module terminal.sh
source_ui_module colors.sh
source_ui_module text.sh
source_ui_module box.sh
source_ui_module help.sh

init_runtime() {
    detect_tty
    detect_wcwidth
    init_colors
}
