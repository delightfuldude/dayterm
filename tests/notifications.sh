#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

DAYTERM_SRC="$ROOT/src"
DAYTERM_CACHE_DIR="$TEST_DIR/cache"
NOTIFICATION_STATE_RETENTION_DAYS=30
NOTIFICATIONS_ENABLED=1
NOTIFICATION_OFFSETS="15 5 0"
NOTIFICATION_WINDOW_SECONDS=90
MISSED_NOTIFICATIONS_ENABLED=1
MAX_MISSED_NOTIFICATION_TIME=60
MAX_MISSED_NOTIFICATIONS=5
NOTIFICATION_URGENCY=normal
DAYTERM_NOW_EPOCH=$(date -d '2030-01-02 10:00:00' +%s)
SEND_COUNT=0

# shellcheck source=../src/calendar/datetime.sh
source "$DAYTERM_SRC/calendar/datetime.sh"
# shellcheck source=../src/notifications.sh
source "$DAYTERM_SRC/notifications.sh"

DAYTERM_DATE_ORDER="ymd"
DAYTERM_KHAL_DATE_FORMAT="%Y-%m-%d"

dt_has_tty() { return 1; }
notifications_send() {
    SEND_COUNT=$((SEND_COUNT + 1))
    return 0
}

EVENTS='[{"uid":"event-1","start":"2030-01-02 10:15","all-day":"False","title":"Test event","location":"Desk","calendar":"test"}]'

notifications_init
notifications_check_due "$EVENTS"
[[ "$SEND_COUNT" == "1" ]] || {
    printf 'expected one notification, got %s\n' "$SEND_COUNT" >&2
    exit 1
}

notifications_init
notifications_check_due "$EVENTS"
[[ "$SEND_COUNT" == "1" ]] || {
    printf 'duplicate notification was not suppressed\n' >&2
    exit 1
}

printf '1\told-key\n' >> "$(notification_state_file)"
notifications_init
notification_key_seen old-key && {
    printf 'expired notification state was not pruned\n' >&2
    exit 1
}

DAYTERM_NOW_EPOCH=$(date -d '2030-01-02 10:40:00' +%s)
MISSED='[{"uid":"event-3","start":"2030-01-02 10:20","all-day":"False","title":"Missed event"}]'
notifications_check_due "$MISSED"
[[ "$SEND_COUNT" == "2" ]] || {
    printf 'missed notification was not delivered\n' >&2
    exit 1
}

notifications_send() {
    SEND_COUNT=$((SEND_COUNT + 1))
    return 1
}
DAYTERM_NOW_EPOCH=$(date -d '2030-01-02 10:15:00' +%s)
FAILED='[{"uid":"event-2","start":"2030-01-02 10:30","all-day":"False","title":"Retry event"}]'
before=$(wc -l < "$(notification_state_file)")
notifications_check_due "$FAILED"
after=$(wc -l < "$(notification_state_file)")
[[ "$before" == "$after" ]] || {
    printf 'failed delivery was incorrectly marked as sent\n' >&2
    exit 1
}
