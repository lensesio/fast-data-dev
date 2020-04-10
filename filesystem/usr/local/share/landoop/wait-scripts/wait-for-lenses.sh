#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-90}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_LENSES_ADDRESS=${W_LENSES_ADDRESS:-localhost}
W_LENSES_PORT=${W_LENSES_PORT:-$ZK_PORT}


for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    curl  http://$W_LENSES_ADDRESS:$W_LENSES_PORT | grep "Lenses" && sleep 10 && break
done
