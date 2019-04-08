#!/usr/bin/env bash

# shellcheck source=variables.env
source variables.env

GENERATOR_BROKER=${GENERATOR_BROKER:-localhost}

# Create Topics
for key in 0 1 2 3 4; do
    # Create topic with x partitions and a retention time of 10 years.
    kafka-topics \
        --zookeeper localhost:${ZK_PORT} \
        --topic "${TOPICS[key]}" \
        --partitions "${PARTITIONS[key]}" \
        --replication-factor "${REPLICATION[key]}" \
        --config retention.ms=315576000000 \
        --config "compression.type=${COMPRESSION[key]}" \
        --config "cleanup.policy=${CLEANUP_POLICY[key]}" \
        --create
done

# Insert data with keys
for key in 0 3 4; do
    unset SCHEMA_REGISTRY_OPTS
    unset SCHEMA_REGISTRY_JMX_OPTS
    unset SCHEMA_REGISTRY_LOG4J_OPTS
    /usr/local/bin/normcat -r 5000 "${DATA[key]}" | \
        kafka-avro-console-producer \
            --broker-list ${GENERATOR_BROKER}:${BROKER_PORT} \
            --topic "${TOPICS[key]}" \
            --property parse.key=true \
            --property key.schema="$(cat "${KEYS[key]}")" \
            --property value.schema="$(cat "${VALUES[key]}")" \
            --property schema.registry.url=http://localhost:${REGISTRY_PORT}
done

# Insert data without keys
# shellcheck disable=SC2043
for key in 1; do
    unset SCHEMA_REGISTRY_OPTS
    unset SCHEMA_REGISTRY_JMX_OPTS
    unset SCHEMA_REGISTRY_LOG4J_OPTS
    /usr/local/bin/normcat -r 5000 "${DATA[key]}" | \
        kafka-avro-console-producer \
            --broker-list ${GENERATOR_BROKER}:${BROKER_PORT} \
            --topic "${TOPICS[key]}" \
            --property value.schema="$(cat "${VALUES[key]}")" \
            --property schema.registry.url=http://localhost:${REGISTRY_PORT}
done

# Insert json data with text keys converted to json keys
# shellcheck disable=SC2043
for key in 2; do
    unset KAFKA_OPTS
    unset KAFKA_JMX_OPTS
    unset KAFKA_LOG4J_OPTS
    /usr/local/bin/normcat -r 5000 "${DATA[key]}" | \
        sed -r -e 's/([A-Z0-9-]*):/{"serial_number":"\1"}#/' | \
        kafka-console-producer \
            --broker-list ${GENERATOR_BROKER}:${BROKER_PORT} \
            --topic "${TOPICS[key]}" \
            --property parse.key=true \
            --property "key.separator=#"
done
