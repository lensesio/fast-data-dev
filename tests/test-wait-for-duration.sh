#!/usr/bin/env bash

# Run with bash tests/test-wait-for-duration.sh; no services are needed.
set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAIT_SCRIPT="$REPO_ROOT/filesystem/usr/local/share/lensesio/wait-scripts/wait-for-duration.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
export SLEEP_CAPTURE="$TEST_DIR/sleep-args"

# Capture the actual sleep invocation so the default does not delay the test.
# shellcheck disable=SC2329 # Invoked by the child shell through export -f.
sleep() {
    printf '%s\n' "$#" "$@" > "$SLEEP_CAPTURE"
    return "${SLEEP_EXIT_CODE:-0}"
}
export -f sleep

check_duration() {
    local expected="$1"
    shift
    "$@" bash "$WAIT_SCRIPT"
    printf '%s\n' 1 "$expected" > "$TEST_DIR/expected"
    if ! cmp -s "$TEST_DIR/expected" "$SLEEP_CAPTURE"; then
        echo "Expected a single sleep argument: $expected" >&2
        cat "$SLEEP_CAPTURE" >&2
        exit 1
    fi
}

check_duration 120 env -u W_DURATION_SECS
check_duration 120 env W_DURATION_SECS=
check_duration 7 env W_DURATION_SECS=7
check_duration 0 env W_DURATION_SECS=0
check_duration 0.25 env W_DURATION_SECS=0.25

# A failed wait must still report failure to callers.
status=0
SLEEP_EXIT_CODE=7 W_DURATION_SECS=1 bash "$WAIT_SCRIPT" || status=$?
if [[ $status != 7 ]]; then
    echo "Expected sleep's exit status 7, got $status" >&2
    exit 1
fi

# Also exercise the real sleep command without adding a delay.
unset -f sleep
W_DURATION_SECS=0 bash "$WAIT_SCRIPT"

echo 'Duration wait regression tests passed.'
