#!/usr/bin/env bash

##
# Two new environment variables:
#   KAFKA_CREATE_TOPICS
#   KAFKA_CREATE_TOPICS_SEPARATOR

if [[ -z "$KAFKA_CREATE_TOPICS" ]]; then
    exit 0
fi

# Expected format:
#   name:partitions:replicas:cleanup.policy
IFS="${KAFKA_CREATE_TOPICS_SEPARATOR-,}"; for topicToCreate in $KAFKA_CREATE_TOPICS; do
    echo "Creating topic: $topicToCreate"

    IFS=':' read -r -a topicConfig <<< "$topicToCreate"
    config=
    if [ -n "${topicConfig[3]}" ]; then
        config="--config=cleanup.policy=${topicConfig[3]}"
    fi

    COMMAND="/opt/landoop/kafka/bin/kafka-topics \\
        --create \\
        --zookeeper ${KAFKA_ZOOKEEPER_CONNECT} \\
        --topic ${topicConfig[0]} \\
        --partitions ${topicConfig[1]} \\
        --replication-factor ${topicConfig[2]} \\
        ${config}"
    eval "${COMMAND}"
done

wait
