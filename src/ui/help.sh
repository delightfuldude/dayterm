#!/usr/bin/env bash

print_usage() {
    cat <<'USAGE'
Usage: dayterm.sh [--once] [--view VIEW] [--date YYYY-MM-DD]
                  [--check] [--notify-test]

  --once         Render one snapshot and exit.
  --view VIEW    agenda, week, month, or tasks.
  --date DATE    Select an ISO date for the rendered view.
  --check        Verify runtime dependencies and configuration.
  --notify-test  Send a desktop notification test.
USAGE
}

show_help() {
    dt_clear
    dt_out "${BLUE}${BOLD}DayTerm commands${NC}"
    dt_out ""
    dt_out "a/w/m/t  Agenda, week, month, or tasks view"
    dt_out "h/j/k/l  Move through days and weeks"
    dt_out "g        Return to today"
    dt_out "e/Enter  Event details and edit"
    dt_out "n        New event"
    dt_out "N        New todo"
    dt_out "s  Sync calendars with vdirsyncer"
    dt_out "c  Open ikhal/khal interactive"
    dt_out "i  Edit DayTerm settings"
    dt_out "?  Help"
    dt_out "q  Quit"
    dt_pause
}
