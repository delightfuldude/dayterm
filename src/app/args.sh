#!/usr/bin/env bash

DAYTERM_ONCE=0
DAYTERM_CHECK=0
DAYTERM_NOTIFY_TEST=0
DAYTERM_REQUESTED_VIEW=''
DAYTERM_REQUESTED_DATE=''

dayterm_parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --once)
                DAYTERM_ONCE=1
                ;;
            --check)
                DAYTERM_CHECK=1
                ;;
            --notify-test)
                DAYTERM_NOTIFY_TEST=1
                ;;
            --view)
                shift
                [[ $# -gt 0 ]] || dayterm_argument_error '--view requires a value'
                DAYTERM_REQUESTED_VIEW="$1"
                view_valid_name "$DAYTERM_REQUESTED_VIEW" || \
                    dayterm_argument_error "Invalid view: $DAYTERM_REQUESTED_VIEW"
                ;;
            --date)
                shift
                [[ $# -gt 0 ]] || dayterm_argument_error '--date requires YYYY-MM-DD'
                DAYTERM_REQUESTED_DATE="$1"
                view_valid_date "$DAYTERM_REQUESTED_DATE" || \
                    dayterm_argument_error "Invalid date: $DAYTERM_REQUESTED_DATE"
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                dayterm_argument_error "Unknown option: $1"
                ;;
        esac
        shift
    done
}

dayterm_argument_error() {
    printf '%s\n' "$1" >&2
    print_usage >&2
    exit 2
}
