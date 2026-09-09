#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-60}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_CONTROLLER_HOST=${W_CONTROLLER_ADDRESS:-localhost}
W_CONTROLLER_PORT=${W_CONTROLLER_PORT:-16062}
W_BROKER_CONFIG=${W_BROKER_CONFIG:-/var/run/broker/server.properties}

# Kafka 4.0 is KRaft-only, so the broker always carries a node.id and we always
# probe the controller quorum. The ZooKeeper detection path was dropped with 4.0.
# Note we do not sleep between attempts on purpose: request.timeout.ms below makes
# each kafka-features call block for roughly W_PERIOD_SECS, which paces the loop.
if grep -sq "node.id=" $W_BROKER_CONFIG; then
    echo "Broker setup with KRaft, using KRaft detection mode"
    echo request.timeout.ms=${W_PERIOD_SECS}000 > /tmp/wait-for-kafka-config-$$.prop
    echo default.api.timeout.ms=${W_PERIOD_SECS}000 >> /tmp/wait-for-kafka-config-$$.prop

    for ((i=0;i<$W_ITERATIONS;i++)); do
        if kafka-features --command-config /tmp/wait-for-kafka-config-$$.prop --bootstrap-controller ${W_CONTROLLER_HOST}:${W_CONTROLLER_PORT} describe; then
           rm -f /tmp/wait-for-kafka-config-$$.prop
           exit 0
        fi
    done
    rm -f /tmp/wait-for-kafka-config-$$.prop
else
    echo "Broker config has no node.id, cannot detect whether Kafka is running"
fi

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
