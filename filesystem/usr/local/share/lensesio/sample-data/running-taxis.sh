#!/usr/bin/env bash

# shellcheck source=variables.env
source variables.env

# Create Topics
# shellcheck disable=SC2043
for key in 1; do
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

# Insert data without key
# shellcheck disable=SC2043
for key in 1; do
    unset SCHEMA_REGISTRY_OPTS
    unset SCHEMA_REGISTRY_JMX_OPTS
    unset SCHEMA_REGISTRY_LOG4J_OPTS
    /usr/local/bin/normcat -r "${RATES[key]}" -j "${JITTER[key]}" -p "${PERIOD[key]}" -c -v "${DATA[key]}" | \
        SCHEMA_REGISTRY_HEAP_OPTS="-Xmx50m" kafka-avro-console-producer \
            --broker-list "${GENERATOR_BROKER}" \
            ${GENERATOR_PRODUCER_PROPERTIES} \
            --topic "${TOPICS[key]}" \
            --property value.schema="$(cat "${VALUES[key]}")" \
            --property schema.registry.url="${GENERATOR_SCHEMA_REGISTRY_URL}" \
            --property client.id="trips-feed"
done
