#!/usr/bin/env bash
set -u

if [[ "${DAYTERM_FAKE_SYNC:-0}" == "1" ]]; then
    printf '%s\n' "$*" > "${DAYTERM_FAKE_ARGS:?}"
    exit "${DAYTERM_FAKE_STATUS:-0}"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin"
cp "$0" "$TEST_DIR/bin/vdirsyncer"
chmod +x "$TEST_DIR/bin/vdirsyncer"
touch "$TEST_DIR/vdirsyncer.conf"

PATH="$TEST_DIR/bin:$PATH"
export PATH DAYTERM_FAKE_SYNC=1 DAYTERM_FAKE_ARGS="$TEST_DIR/args"
VDIRSYNCER_CONFIG="$TEST_DIR/vdirsyncer.conf"

# shellcheck source=../src/display/events.sh
source "$ROOT/src/display/events.sh"

run_vdirsyncer_sync "$TEST_DIR/sync.lock" > /dev/null || exit 1
args=$(<"$TEST_DIR/args")
[[ "$args" == "-v INFO -c $VDIRSYNCER_CONFIG sync" ]] || exit 1

exec 9> "$TEST_DIR/sync.lock"
flock -n 9 || exit 1
run_vdirsyncer_sync "$TEST_DIR/sync.lock" > /dev/null 2>&1
[[ "$?" == "75" ]] || exit 1
flock -u 9
