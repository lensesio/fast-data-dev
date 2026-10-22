#!/usr/bin/env bash

# Run with bash tests/test-ssl-listeners.sh (requires GNU or BusyBox sed).
set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
export CONFIG="$TEST_DIR/server.properties"
export TRUE_REG='^([tT][rR][uU][eE]|[yY]|[yY][eE][sS]|1)$'
export ADV_HOST=broker.example
export TMP_ADV_LISTENERS_SET=true
export BROKER_SSL_PORT=19093

configure_ssl() {
    # Exercise the real broker configuration block without generating certificates
    # or writing to the container's /var/run directory.
    sed -n '/^    # Setup the broker with SSL$/,/^    # Log authorization requests$/p' \
        "$REPO_ROOT/setup-and-run.sh" \
        | sed "s|/var/run/broker/server.properties|$CONFIG|g" \
        | bash -euo pipefail
}

assert_line() {
    if ! grep -Fxq -- "$1" "$CONFIG"; then
        echo "Expected configuration line: $1" >&2
        cat "$CONFIG" >&2
        exit 1
    fi
}

# A fresh start and repeated starts must produce the same listener lists.
cat > "$CONFIG" <<'EOF'
listeners=PLAINTEXT://:9092,CONTROLLER://:16062
advertised.listeners=PLAINTEXT://broker.example:9092
EOF
for ((start=1; start<=3; start++)); do
    configure_ssl
    assert_line 'listeners=PLAINTEXT://:9092,CONTROLLER://:16062,SSL://:19093'
    assert_line 'advertised.listeners=PLAINTEXT://broker.example:9092,SSL://broker.example:19093'
done

# Preserve an explicitly configured SSL listener, including its host and port.
cat > "$CONFIG" <<'EOF'
listeners=SSL://custom.example:29093,PLAINTEXT://:9092,CONTROLLER://:16062
advertised.listeners=SSL://public.example:39093,PLAINTEXT://broker.example:9092
EOF
configure_ssl
configure_ssl
assert_line 'listeners=SSL://custom.example:29093,PLAINTEXT://:9092,CONTROLLER://:16062'
assert_line 'advertised.listeners=SSL://public.example:39093,PLAINTEXT://broker.example:9092'

# SASL_SSL is a separate listener name and must not prevent adding SSL.
cat > "$CONFIG" <<'EOF'
listeners=PLAINTEXT://:9092,SASL_SSL://:29093,CONTROLLER://:16062
advertised.listeners=PLAINTEXT://broker.example:9092,SASL_SSL://broker.example:29093
EOF
configure_ssl
configure_ssl
assert_line 'listeners=PLAINTEXT://:9092,SASL_SSL://:29093,CONTROLLER://:16062,SSL://:19093'
assert_line 'advertised.listeners=PLAINTEXT://broker.example:9092,SASL_SSL://broker.example:29093,SSL://broker.example:19093'

# User-supplied advertised listeners remain under the user's control.
export TMP_ADV_LISTENERS_SET=false
printf '%s\n' 'listeners=PLAINTEXT://:9092' \
    'advertised.listeners=PLAINTEXT://public.example:9092' > "$CONFIG"
configure_ssl
assert_line 'listeners=PLAINTEXT://:9092,SSL://:19093'
assert_line 'advertised.listeners=PLAINTEXT://public.example:9092'

# No ADV_HOST must not require TMP_ADV_LISTENERS_SET or create advertised listeners.
export ADV_HOST=
unset TMP_ADV_LISTENERS_SET
printf '%s\n' 'listeners=PLAINTEXT://:9092' > "$CONFIG"
configure_ssl
configure_ssl
assert_line 'listeners=PLAINTEXT://:9092,SSL://:19093'
if grep -q '^advertised\.listeners=' "$CONFIG"; then
    echo 'Unexpected advertised.listeners without ADV_HOST' >&2
    exit 1
fi

echo 'SSL listener regression tests passed.'
