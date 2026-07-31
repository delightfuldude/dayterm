#!/usr/bin/env bash

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
