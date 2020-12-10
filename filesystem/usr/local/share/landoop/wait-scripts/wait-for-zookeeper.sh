#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-60}
W_PERIOD_SECS=${W_PERIOD_SECS:-1}
W_ZK_ADDRESS=${W_ZK_ADDRESS:-127.0.0.1}
W_ZK_PORT=${W_ZK_PORT:-$ZK_PORT}
W_ZK_PORT=${W_ZK_PORT:-2181}

for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    echo ruok | nc $W_ZK_ADDRESS $W_ZK_PORT | grep imok && exit 0
done

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
