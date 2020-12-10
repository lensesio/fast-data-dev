#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-150}
W_PERIOD_SECS=${W_PERIOD_SECS:-3}
W_LENSES_ADDRESS=${W_LENSES_ADDRESS:-localhost}
W_LENSES_PORT=${W_LENSES_PORT:-$LENSES_PORT}

for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    curl  http://$W_LENSES_ADDRESS:$W_LENSES_PORT | grep "Lenses" && sleep 10 && exit 0
done

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
