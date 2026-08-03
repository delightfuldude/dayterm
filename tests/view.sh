#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
DEFAULT_VIEW=agenda
DAYTERM_REQUESTED_VIEW=week
DAYTERM_REQUESTED_DATE=2026-07-31

# shellcheck source=../src/view.sh
source "$ROOT/src/view.sh"

view_init
[[ "$DAYTERM_QUERY_START" == "2026-07-27" && "$DAYTERM_QUERY_END" == "2026-08-02" ]] || exit 1

view_move h
[[ "$DAYTERM_SELECTED_DATE" == "2026-07-30" ]] || exit 1
[[ "$DAYTERM_QUERY_START" == "2026-07-27" && "$DAYTERM_QUERY_END" == "2026-08-02" ]] || exit 1

view_move j
[[ "$DAYTERM_SELECTED_DATE" == "2026-08-06" ]] || exit 1
[[ "$DAYTERM_QUERY_START" == "2026-08-03" && "$DAYTERM_QUERY_END" == "2026-08-09" ]] || exit 1

view_set month
[[ "$DAYTERM_QUERY_START" == "2026-08-01" && "$DAYTERM_QUERY_END" == "2026-08-31" ]] || exit 1

view_set agenda
[[ "$DAYTERM_QUERY_START" == "$DAYTERM_SELECTED_DATE" && "$DAYTERM_QUERY_END" == "$DAYTERM_SELECTED_DATE" ]] || exit 1
