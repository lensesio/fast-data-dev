#!/usr/bin/env bash

# shellcheck source=variables.env
source variables.env

# Create Topics
# shellcheck disable=SC2043
for key in 5; do
    # Create topic with x partitions and a retention size of 50MB, log segment
    # size of 20MB and compression type y.
    kafka-topics \
        --bootstrap-server "${GENERATOR_BROKER}" \
        --topic "${TOPICS[key]}" \
        --partitions "${PARTITIONS[key]}" \
        --replication-factor "${REPLICATION[key]}" \
        --config retention.bytes=${RETENTION_BYTES} \
        --config compression.type="${COMPRESSION[key]}" \
        --config segment.bytes=${SEGMENT_BYTES} \
        --create
done

LENSES_PORT=${LENSES_PORT:-9991}
USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}
# Wait for Lenses to get up if needed and see the topic
for ((i=0;i<30;i++)); do
    sleep 5
    lenses-cli --timeout 3s --user "$USER" --pass "$PASSWORD" --host http://"${GENERATOR_LENSES}" topics | grep -sq "${TOPICS[key]}" && { sleep 5; break; };
done
# Set Lenses to recognize topic as CSV
lenses-cli --timeout 3s --user "$USER" --pass "$PASSWORD" --host http://"${GENERATOR_LENSES}" \
           topics metadata set --name="financial_tweets" --key-type="BYTES" --value-type="CSV"

# Insert data with text key converted to json key
# shellcheck disable=SC2043
for key in 5; do
    /usr/local/bin/normcat -r "${RATES[key]}" -j "${JITTER[key]}" -p "${PERIOD[key]}" -c -v "${DATA[key]}" | \
        KAFKA_HEAP_OPTS="-Xmx50m" kafka-console-producer \
            --broker-list "${GENERATOR_BROKER}" \
            ${GENERATOR_PRODUCER_PROPERTIES} \
            --topic "${TOPICS[key]}" \
            --property client.id="tweets-scraper"
done
