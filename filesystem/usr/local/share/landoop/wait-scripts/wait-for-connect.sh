#!/usr/bin/env bash

W_ITERATIONS=${W_ITERATIONS:-90}
W_PERIOD_SECS=${W_PERIOD_SECS:-2}
W_CONNECT_PORT=${CONNECT_PORT:-8083}
W_CONNECT_ADDRESS=${W_CONNECT_ADDRESS:-http://localhost:$W_CONNECT_PORT}

for ((i=0;i<$W_ITERATIONS;i++)); do
    sleep $W_PERIOD_SECS
    # Because when we create a connector, connect rebalances which takes some
    # time, we don't want all checks to to trigger together, so we add some
    # random wait. It isn't a great solution, but it may help.
    curl -sS "${W_CONNECT_ADDRESS}/connector-plugins/" \
        | grep "org.apache.kafka.connect.file.FileStreamSourceConnector" \
        && { sleep $(( RANDOM%(5*W_PERIOD_SECS) )); break; }
done

