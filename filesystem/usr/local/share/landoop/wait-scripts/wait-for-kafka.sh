#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-60}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_BROKERS_WANTED=${W_BROKERS_WANTED:-1}
W_ZK_ADDRESS=${W_ZK_ADDRESS:-127.0.0.1}
W_ZK_PORT=${W_ZK_PORT:-$ZK_PORT}
W_ZK_PORT=${W_ZK_PORT:-2181}

for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    _BROKER_NUM="$(echo dump | nc $W_ZK_ADDRESS $W_ZK_PORT | grep -c brokers/ids)"
    echo "Brokers detected/wanted: $_BROKER_NUM / $W_BROKERS_WANTED"
    if [[ ${_BROKER_NUM} -ge ${W_BROKERS_WANTED} ]]; then
        sleep 1
        exit 0
    fi
done

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
