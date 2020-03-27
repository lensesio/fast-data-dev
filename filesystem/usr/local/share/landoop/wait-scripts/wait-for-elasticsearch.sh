#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-90}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_ELASTICSEARCH_PORT=${W_ELASTICSEARCH_PORT:-$ELASTICSEARCH_PORT}
W_ELASTICSEARCH_ADDRESS=${W_ELASTICSEARCH_ADDRESS:-http://localhost:$W_ELASTICSEARCH_PORT}

if [[ $W_ELASTICSEARCH_PORT == 0 ]]; then
    echo "Elasticsearch is disabled."
    exit 0
fi

for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    curl -sS "$W_ELASTICSEARCH_ADDRESS" \
        | grep "cluster_uuid" \
        && break
done

