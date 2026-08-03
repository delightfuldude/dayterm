#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
DAYTERM_SRC="$ROOT/src"

khal() {
    case "$1" in
        printcalendars)
            printf 'test\n'
            ;;
        list)
            printf '%s\n' "$*" > "$TEST_DIR/args"
            printf '%s\n' '[{"uid":"z","start":"28/07/2026 10:00","end":"28/07/2026 11:00","title":"First"},{"uid":"z","start":"28/07/2026 10:00","end":"28/07/2026 11:00","title":"First"},{"uid":"a","start":"28/07/2026 12:00","end":"28/07/2026 13:00","title":"Second"}]'
            ;;
        *)
            return 0
            ;;
    esac
}

# shellcheck source=../src/calendar/datetime.sh
source "$DAYTERM_SRC/calendar/datetime.sh"
# shellcheck source=../src/calendar/query.sh
source "$DAYTERM_SRC/calendar/query.sh"
# shellcheck source=../src/calendar/cache.sh
source "$DAYTERM_SRC/calendar/cache.sh"
DAYTERM_DATE_ORDER=dmy
DAYTERM_KHAL_DATE_FORMAT='%d/%m/%Y'

result=$(calendar_query_events_json 2026-07-28 2026-07-28) || exit 1
args=$(<"$TEST_DIR/args")
[[ "$args" == *"28/07/2026 eod" ]] || {
    printf 'single-day query does not end at eod: %s\n' "$args" >&2
    exit 1
}
[[ "$(jq -r 'length' <<< "$result")" == "2" ]] || exit 1
[[ "$(jq -r 'map(.title) | join(",")' <<< "$result")" == "First,Second" ]] || {
    printf 'deduplication changed event order\n' >&2
    exit 1
}

calendar_query_events_json 2026-07-28 2026-07-31 > /dev/null || exit 1
args=$(<"$TEST_DIR/args")
[[ "$args" == *"28/07/2026 31/07/2026" ]] || {
    printf 'multi-day query range is incorrect: %s\n' "$args" >&2
    exit 1
}

DAYTERM_CACHE_DIR="$TEST_DIR/cache"
mkdir -p "$DAYTERM_CACHE_DIR"
cache_file="$DAYTERM_CACHE_DIR/events.json"
calendar_store_cache "$cache_file" 2026-07-28 2026-07-31 "$result" || exit 1
cached=$(calendar_load_cache "$cache_file" 2026-07-28 2026-07-31) || exit 1
[[ "$cached" == "$result" ]] || exit 1
if calendar_load_cache "$cache_file" 2026-08-01 2026-08-31 > /dev/null 2>&1; then
    printf 'cache accepted the wrong date range\n' >&2
    exit 1
fi
