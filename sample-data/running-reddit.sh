#!/usr/bin/env bash

pushd /usr/share/landoop/sample-data

# shellcheck source=variables.env
source variables.env

# Create Topics
# shellcheck disable=SC2043
for key in 1; do
    # Create topic with x partitions and a retention size of 50MB, log segment
    # size of 20MB and compression type y.
    kafka-topics \
        --zookeeper localhost:2181 \
        --topic "${TOPICS[key]}" \
        --partitions "${PARTITIONS[key]}" \
        --replication-factor "${REPLICATION[key]}" \
        --config retention.bytes=26214400 \
        --config compression.type="${COMPRESSION[key]}" \
        --config segment.bytes=8388608 \
        --create
done

# Insert data with key
# shellcheck disable=SC2043
for key in 1; do
    /usr/local/bin/normcat -r "${RATES[key]}" -j "${JITTER[key]}" -p "${PERIOD[key]}" -c -v "${DATA[key]}" | \
        kafka-avro-console-producer \
            --broker-list localhost:9092 \
            --topic "${TOPICS[key]}" \
            --property parse.key=true \
            --property key.schema="$(cat "${KEYS[key]}")" \
            --property value.schema="$(cat "${VALUES[key]}")" \
            --property schema.registry.url=http://localhost:8081
done

popd
