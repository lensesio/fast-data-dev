#!/usr/bin/env bash

# shellcheck source=variables.env
source variables.env

# Create Topics
# shellcheck disable=SC2043
for key in 3 4; do
    # Create topic with x partitions and a retention size of 50MB, log segment
    # size of 20MB and compression type y.
    kafka-topics \
        --zookeeper "${GENERATOR_ZK_HOST}:${ZK_PORT}" \
        --topic "${TOPICS[key]}" \
        --partitions "${PARTITIONS[key]}" \
        --replication-factor "${REPLICATION[key]}" \
        --config retention.bytes=26214400 \
        --config compression.type="${COMPRESSION[key]}" \
        --config "cleanup.policy=${CLEANUP_POLICY[key]}" \
        --config segment.bytes=8388608 \
        --create
done

# Insert Grid Data
# shellcheck disable=SC2043
for key in 4; do
    unset SCHEMA_REGISTRY_OPTS
    unset SCHEMA_REGISTRY_JMX_OPTS
    unset SCHEMA_REGISTRY_LOG4J_OPTS
    /usr/local/bin/normcat -v "${DATA[key]}" | \
        SCHEMA_REGISTRY_HEAP_OPTS="-Xmx50m" kafka-avro-console-producer \
            --broker-list "${GENERATOR_BROKER}" \
            ${GENERATOR_PRODUCER_PROPERTIES} \
            --topic "${TOPICS[key]}" \
            --property parse.key=true \
            --property key.schema="$(cat "${KEYS[key]}")" \
            --property value.schema="$(cat "${VALUES[key]}")" \
            --property schema.registry.url="${GENERATOR_SCHEMA_REGISTRY_URL}"
done

# Insert data with key
# shellcheck disable=SC2043
for key in 3; do
    unset SCHEMA_REGISTRY_OPTS
    unset SCHEMA_REGISTRY_JMX_OPTS
    unset SCHEMA_REGISTRY_LOG4J_OPTS
    /usr/local/bin/normcat -r "${RATES[key]}" -j "${JITTER[key]}" -p "${PERIOD[key]}" -c -v "${DATA[key]}" | \
        SCHEMA_REGISTRY_HEAP_OPTS="-Xmx50m" kafka-avro-console-producer \
            --broker-list "${GENERATOR_BROKER}" \
            ${GENERATOR_PRODUCER_PROPERTIES} \
            --topic "${TOPICS[key]}" \
            --property parse.key=true \
            --property key.schema="$(cat "${KEYS[key]}")" \
            --property value.schema="$(cat "${VALUES[key]}")" \
            --property schema.registry.url="${GENERATOR_SCHEMA_REGISTRY_URL}"
done
