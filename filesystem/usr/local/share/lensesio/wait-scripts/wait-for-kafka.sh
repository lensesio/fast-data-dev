#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-60}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_BROKERS_WANTED=${W_BROKERS_WANTED:-1}
W_CONTROLLER_HOST=${W_CONTROLLER_ADDRESS:-localhost}
W_CONTROLLER_PORT=${W_CONTROLLER_PORT:-16062}
W_ZK_ADDRESS=${W_ZK_ADDRESS:-127.0.0.1}
W_ZK_PORT=${W_ZK_PORT:-$ZK_PORT}
W_ZK_PORT=${W_ZK_PORT:-2181}
W_BROKER_CONFIG=${W_BROKER_CONFIG:-/var/run/broker/server.properties}

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

elif grep -sq "broker.id=" $W_BROKER_CONFIG; then
    echo "Broker setup with Zookeeper, using Zookeeper detection mode"

    for ((i=0;i<$W_ITERATIONS;i++)); do
        sleep $W_PERIOD_SECS
        _BROKER_NUM="$(echo dump | nc $W_ZK_ADDRESS $W_ZK_PORT | grep -c brokers/ids)"
        echo "Brokers detected/wanted: $_BROKER_NUM / $W_BROKERS_WANTED"
        if [[ ${_BROKER_NUM} -ge ${W_BROKERS_WANTED} ]]; then
            sleep 1
            exit 0
        fi
    done
else
    echo "Broker setup with unknown configuration, cannot detect whether Kafka is running"
fi

if [[ $W_ITERATIONS == 0 ]]; then
    exit 0
else
    exit 1
fi
