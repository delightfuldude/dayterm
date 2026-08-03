#!/usr/bin/env bash

# Compatibility wrapper for integrations that source calendar/core.sh directly.
if ! declare -F calendar_query_events_json >/dev/null 2>&1; then
    DAYTERM_SRC="${DAYTERM_SRC:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)}"
    # shellcheck source=../calendar.sh
    source "$DAYTERM_SRC/calendar.sh"
fi
