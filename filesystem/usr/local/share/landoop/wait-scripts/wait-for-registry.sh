#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-90}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_SR_ADDRESS=${W_SR_ADDRESS:-http://127.0.0.1:$REGISTRY_PORT}

for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    curl -sS "$W_SR_ADDRESS" | grep "{}" && exit 0
done

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
