#!/usr/bin/env bash

# shellcheck source=variables.env
source variables.env

# Create Topics
# shellcheck disable=SC2043
for key in 6; do
    # Create topic with x partitions and a retention size of 50MB, log segment
    # size of 20MB and compression type y.
    kafka-topics \
        --zookeeper localhost:${ZK_PORT} \
        --topic "${TOPICS[key]}" \
        --partitions "${PARTITIONS[key]}" \
        --replication-factor "${REPLICATION[key]}" \
        --config retention.bytes=26214400 \
        --config compression.type="${COMPRESSION[key]}" \
        --config segment.bytes=8388608 \
        --create
done

LENSES_PORT=${LENSES_PORT:-9991}
USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}
# Wait for Lenses to get up if needed and see the topic
for ((i=0;i<30;i++)); do
    sleep 5
    lenses-cli --timeout 3s --user "$USER" --pass "$PASSWORD" --host http://127.0.0.1:$LENSES_PORT topics | grep -sq "${TOPICS[key]}" && { sleep 5; break; };
done
# Sleep for Lenses to read the topic
sleep 15
# Set Lenses to recognize topic as CSV
lenses-cli --timeout 3s --user "$USER" --pass "$PASSWORD" --host http://127.0.0.1:$LENSES_PORT \
           topics metadata set --name="financial_tweets" --key-type="BYTES" --value-type="CSV"

# Insert data with text key converted to json key
# shellcheck disable=SC2043
for key in 6; do
    /usr/local/bin/normcat -r "${RATES[key]}" -j "${JITTER[key]}" -p "${PERIOD[key]}" -c -v "${DATA[key]}" | \
        KAFKA_HEAP_OPTS="-Xmx50m" kafka-console-producer \
            --broker-list localhost:${BROKER_PORT} \
            --topic "${TOPICS[key]}"
done
