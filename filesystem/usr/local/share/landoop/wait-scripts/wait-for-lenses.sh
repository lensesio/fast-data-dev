#!/usr/bin/env bash

# This wait script waits for Lenses to come up. It doesn't wait for Lenses to be
# configured via the API.

W_ITERATIONS=${W_ITERATIONS:-300}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_LENSES_ADDRESS=${W_LENSES_ADDRESS:-localhost}
W_LENSES_PORT=${W_LENSES_PORT:-$LENSES_PORT}

for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    curl -sS http://$W_LENSES_ADDRESS:$W_LENSES_PORT$LENSES_ROOT_PATH \
        | grep "Lenses" && exit 0
done

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
