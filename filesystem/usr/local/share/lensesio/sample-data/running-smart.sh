#!/usr/bin/env bash

# shellcheck source=variables.env
source variables.env

# Create Topics
# shellcheck disable=SC2043
for key in 2; do
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

# Insert data with text key converted to json key
# shellcheck disable=SC2043
for key in 2; do
    unset KAFKA_OPTS
    unset KAFKA_JMX_OPTS
    /usr/local/bin/normcat -r "${RATES[key]}" -j "${JITTER[key]}" -p "${PERIOD[key]}" -c -v "${DATA[key]}" | \
        sed -r -e 's/([A-Z0-9-]*):/{"serial_number":"\1"}#/' | \
        KAFKA_HEAP_OPTS="-Xmx50m" kafka-console-producer \
            --broker-list "${GENERATOR_BROKER}" \
            ${GENERATOR_PRODUCER_PROPERTIES} \
            --topic "${TOPICS[key]}" \
            --property parse.key=true \
            --property "key.separator=#"
done
