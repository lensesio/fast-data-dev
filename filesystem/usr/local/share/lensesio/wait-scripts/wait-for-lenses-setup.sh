#!/usr/bin/env bash

# This wait script waits for Lenses to both come up and be configured via the
# API.

W_ITERATIONS=${W_ITERATIONS:-300}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_LENSES_ADDRESS=${W_LENSES_ADDRESS:-localhost}
W_LENSES_PORT=${W_LENSES_PORT:-$LENSES_PORT}

USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}

LENSES_URL="http://$W_LENSES_ADDRESS:$W_LENSES_PORT$LENSES_ROOT_PATH"

# Wait for Lenses to come up
for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    curl -sS "$LENSES_URL" \
        | grep "Lenses" && break
done

# Wait for Lenses to be configured
if [[ $W_ITERATIONS -gt 0 ]]; then
    TOKEN=$(curl -X POST -H "Content-Type:application/json" -d "{\"user\":\"$USER\",  \"password\":\"$PASSWORD\"}" "$LENSES_URL/api/login")
    if [[ ! $TOKEN =~ ^[0-9a-f-]{36,36}$ ]]; then # Naive way to check we indeed have a token
        echo "Token '$TOKEN' does not seem like a Lenses token. Something went wrong?"
        exit 1
    fi
    for ((i=0;i<$W_ITERATIONS;i++)); do
        sleep $W_PERIOD_SECS
        _IS_COMPLETED=$(curl -H "X-Kafka-Lenses-Token: $TOKEN" "$LENSES_URL/api/v1/setup" | jq .isCompleted)
        [[ $_IS_COMPLETED =~ [Tt][Rr][Uu][Ee] ]] && sleep 10 && exit 0
    done
fi

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
