#!/usr/bin/env bash

if [[ ! -f /data/kafka/logdir/meta.properties ]] && grep -sq "node.id=" /var/run/broker/server.properties; then
    echo "Fresh start and KRaft mode, formatting the data directory"
    _CLUSTER_ID=$(kafka-storage random-uuid)
    kafka-storage format -t $_CLUSTER_ID -c /var/run/broker/server.properties
else
    exit 0
fi
