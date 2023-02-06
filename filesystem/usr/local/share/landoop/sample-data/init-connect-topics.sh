#!/usr/bin/env bash

# We need this because Lenses is faster than Connect, tries to access its topics
# before they are created and Kafka creates them with wrong settings. Connect
# 2.6+ will not start if the topics has bad settings. We could turn auto create
# topics off for our broker but since this is a dev box we don't want to.

kafka-topics \
    --bootstrap-server "${GENERATOR_BROKER}" \
    --topic "$CONNECT_CONFIG_STORAGE_TOPIC" \
    --partitions "$CONNECT_CONFIG_STORAGE_PARTITIONS" \
    --replication-factor "$CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR" \
    --config "cleanup.policy=compact" \
    --create

kafka-topics \
    --bootstrap-server "${GENERATOR_BROKER}" \
    --topic "$CONNECT_OFFSET_STORAGE_TOPIC" \
    --partitions "$CONNECT_OFFSET_STORAGE_PARTITIONS" \
    --replication-factor "$CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR" \
    --config "cleanup.policy=compact" \
    --create

kafka-topics \
    --bootstrap-server "${GENERATOR_BROKER}" \
    --topic "$CONNECT_STATUS_STORAGE_TOPIC" \
    --partitions "$CONNECT_STATUS_STORAGE_PARTITIONS" \
    --replication-factor "$CONNECT_STATUS_STORAGE_REPLICATION_FACTOR" \
    --config "cleanup.policy=compact" \
    --create
