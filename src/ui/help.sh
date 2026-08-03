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
    dt_out "Week      h/l day, j/k time, J/K week"
    dt_out "Month     h/l day, j/k week"
    dt_out "Agenda    h/k back, j/l forward"
    dt_out "g        Return to today"
    dt_out "e/Enter  Edit selected event or create in empty slot"
    dt_out "n        New event at selected date and time"
    dt_out "N        New todo"
    dt_out "s        Sync calendars with vdirsyncer"
    dt_out "c        Open ikhal/khal interactive"
    dt_out "i        Edit DayTerm settings"
    dt_out "?        Help"
    dt_out "q        Quit"
    dt_pause
}
